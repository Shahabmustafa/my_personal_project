// ZKTeco ADMS / PUSH ("iclock") server — attendance machine yahan punches
// bhejti hai. Machine ka "Cloud Server" web app ka domain hai; Vercel
// /iclock/* ko is function par bhejta hai (vercel.json).
//
//   GET  /iclock/cdata?SN=..            → machine ko settings
//   POST /iclock/cdata?SN=..&table=ATTLOG → punches (tab-separated lines)
//   POST /iclock/cdata?SN=..&table=OPERLOG → users/fingerprints — sirf OK
//   GET  /iclock/getrequest?SN=..       → koi command nahi → OK
//   POST /iclock/devicecmd?SN=..        → OK
//
// Har machine pehli baar aate hi "Attendance Machines" screen mein pending
// dikhti hai; superadmin branch de kar approve kare tabhi punches attendance
// banate hain (database functions — attendance_machine_migration.sql).
import { createClient } from "jsr:@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const text = (body: string) =>
  new Response(body, { headers: { "Content-Type": "text/plain" } });

Deno.serve(async (req) => {
  const url = new URL(req.url);
  const path = url.pathname.toLowerCase();
  const sn = (url.searchParams.get("SN") ?? url.searchParams.get("sn") ?? "")
    .trim();
  if (!sn) return text("OK");

  const ip = req.headers.get("x-forwarded-for")?.split(",")[0].trim() ?? "";
  const { error: seenErr } = await supabase.rpc("attendance_device_seen", {
    p_sn: sn,
    p_ip: ip,
  });
  if (seenErr) console.error("device_seen", sn, seenErr.message);

  if (path.endsWith("/cdata")) {
    if (req.method === "GET") {
      // Stamp=None → machine apne saare purane punches bhi bhej de (dobara
      // aaye to database duplicate ignore karta hai).
      return text(
        [
          `GET OPTION FROM: ${sn}`,
          "ATTLOGStamp=None",
          "OPERLOGStamp=9999",
          "ATTPHOTOStamp=None",
          "ErrorDelay=30",
          "Delay=10",
          "TransTimes=00:00;14:05",
          "TransInterval=1",
          "TransFlag=TransData AttLog\tOpLog",
          "TimeZone=5",
          "Realtime=1",
          "Encrypt=None",
        ].join("\n"),
      );
    }

    const table = (url.searchParams.get("table") ?? "").toUpperCase();
    const body = await req.text();
    if (table !== "ATTLOG") {
      const lines = body.split("\n").filter((l) => l.trim()).length;
      return text(`OK: ${lines}`);
    }

    // PIN \t YYYY-MM-DD HH:MM:SS \t status \t verify \t workcode ...
    const rows = body
      .split("\n")
      .map((l) => l.replace("\r", "").split("\t"))
      .filter((c) => c.length >= 2 && c[0].trim() && c[1].trim())
      .map((c) => ({
        pin: c[0].trim(),
        time: c[1].trim(),
        status: (c[2] ?? "").trim(),
        verify: (c[3] ?? "").trim(),
      }));
    if (rows.length === 0) return text("OK: 0");

    const { data, error } = await supabase.rpc("attendance_ingest_punches", {
      p_sn: sn,
      p_rows: rows,
    });
    if (error) {
      // OK na bhejne par machine baad mein dobara bhejegi — data nahi khota.
      console.error("ingest", sn, error.message);
      return new Response("ERROR", { status: 500 });
    }
    return text(`OK: ${data ?? rows.length}`);
  }

  // getrequest, devicecmd, ping, registry, ... — hamare paas koi command nahi.
  if (req.method === "POST") await req.text();
  return text("OK");
});
