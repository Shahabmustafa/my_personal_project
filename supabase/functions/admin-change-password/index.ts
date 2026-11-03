// Head office (superadmin) kisi bhi user ka password change kar sakta hai.
// service_role key sirf is function ke andar rehti hai, app mein nahi.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const url = Deno.env.get("SUPABASE_URL")!;
    const authHeader = req.headers.get("Authorization") ?? "";

    // Caller kaun hai?
    const caller = createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user } } = await caller.auth.getUser();
    if (!user) return json({ error: "Not authenticated" }, 401);

    // Server-side role check — caller ke apne token se (jo app ke users read
    // ke liye already chalta hai). service_role ko users table grant nahi hai.
    const { data: me, error: meErr } = await caller
      .from("users").select("role, is_active").eq("id", user.id).maybeSingle();
    if (!me || me.role !== "superadmin" || me.is_active === false) {
      return json({
        error: `Only head office can change passwords (found=${me ? me.role : "no users row"}${meErr ? ", db=" + meErr.message : ""})`,
      }, 403);
    }

    // service_role sirf Auth admin API ke liye (users table nahi chhoota)
    const admin = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

    const { user_id, new_password } = await req.json();
    if (!user_id || typeof new_password !== "string" || new_password.length < 6) {
      return json({ error: "Password must be at least 6 characters" }, 400);
    }

    const { error } = await admin.auth.admin.updateUserById(user_id, {
      password: new_password,
    });
    if (error) return json({ error: error.message }, 400);

    return json({ ok: true });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
