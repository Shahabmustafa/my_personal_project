-- ─────────────────────────────────────────────────────────────────────────────
-- ATTENDANCE MACHINE (ZKTeco ADMS / PUSH)
-- Machine har punch `iclock` edge function ko bhejti hai (Vercel par
-- /iclock/* → supabase functions/v1/iclock/*). Function service role se
-- neeche wale functions call karta hai:
--   attendance_device_seen      — machine ne rabta kiya (naya ho to "pending")
--   attendance_ingest_punches   — punches save + attendance mein lagao
-- Punch tab hi attendance banta hai jab machine superadmin ne approve ki ho
-- (branch + is_active) aur machine ka PIN kisi user ke machine_user_id se
-- mile. Baad mein approve / Machine ID set ho to
-- attendance_reapply_pending() purane punches bhi laga deta hai.
-- Din ka pehla punch = check in, aakhri punch = check out (2 minute ke
-- andar dobara thumb ignore).
-- STATUS (2026-10-08): applied to LIVE database.
-- ─────────────────────────────────────────────────────────────────────────────

-- Machine mein jo User ID (PIN) diya, wahi yahan — poore system mein unique.
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS machine_user_id TEXT;
CREATE UNIQUE INDEX IF NOT EXISTS users_machine_user_id_key
    ON public.users (machine_user_id) WHERE machine_user_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS public.attendance_devices (
    serial_number  TEXT         PRIMARY KEY,
    name           TEXT,
    branch_id      UUID         REFERENCES public.branches(id) ON DELETE SET NULL,
    is_active      BOOLEAN      NOT NULL DEFAULT false,
    last_seen_at   TIMESTAMPTZ,
    last_ip        TEXT,
    created_at     TIMESTAMPTZ  DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.attendance_punches (
    id          BIGSERIAL    PRIMARY KEY,
    device_sn   TEXT         NOT NULL REFERENCES public.attendance_devices(serial_number) ON DELETE CASCADE,
    pin         TEXT         NOT NULL,
    punch_at    TIMESTAMPTZ  NOT NULL,
    status      INT,
    verify      INT,
    applied     BOOLEAN      NOT NULL DEFAULT false,
    created_at  TIMESTAMPTZ  DEFAULT now(),
    UNIQUE (device_sn, pin, punch_at)
);
CREATE INDEX IF NOT EXISTS idx_attendance_punches_pending
    ON public.attendance_punches (device_sn) WHERE NOT applied;

ALTER TABLE public.attendance_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_punches ENABLE ROW LEVEL SECURITY;
CREATE POLICY authenticated_full_access ON public.attendance_devices
    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY authenticated_full_access ON public.attendance_punches
    FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, UPDATE, DELETE ON public.attendance_devices TO authenticated;
GRANT SELECT ON public.attendance_punches TO authenticated;

-- Ek punch ko us din ki attendance mein lagao.
CREATE OR REPLACE FUNCTION public.attendance_apply_punch(
    p_user UUID, p_branch UUID, p_ts TIMESTAMPTZ)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_date DATE := (p_ts AT TIME ZONE 'Asia/Karachi')::date;
    v_row  public.branch_attendance;
    v_in   TIMESTAMPTZ;
    v_max  TIMESTAMPTZ;
    v_out  TIMESTAMPTZ;
BEGIN
    SELECT * INTO v_row FROM public.branch_attendance
    WHERE user_id = p_user AND attendance_date = v_date
    FOR UPDATE;

    IF NOT FOUND THEN
        INSERT INTO public.branch_attendance
            (user_id, branch_id, attendance_date, check_in_at)
        VALUES (p_user, p_branch, v_date, p_ts)
        ON CONFLICT (user_id, attendance_date) DO NOTHING;
        IF FOUND THEN RETURN; END IF;
        -- Saath saath doosra punch aa gaya — dobara padh kar merge.
        SELECT * INTO v_row FROM public.branch_attendance
        WHERE user_id = p_user AND attendance_date = v_date
        FOR UPDATE;
    END IF;

    v_in  := LEAST(v_row.check_in_at, p_ts);
    v_max := GREATEST(v_row.check_in_at,
                      COALESCE(v_row.check_out_at, v_row.check_in_at), p_ts);
    v_out := CASE WHEN v_max > v_in + INTERVAL '2 minutes'
                  THEN v_max ELSE v_row.check_out_at END;

    UPDATE public.branch_attendance
    SET check_in_at = v_in, check_out_at = v_out
    WHERE id = v_row.id;
END;
$$;

-- Machine ne rabta kiya — record/update; approved hai ya nahi wapas.
CREATE OR REPLACE FUNCTION public.attendance_device_seen(p_sn TEXT, p_ip TEXT)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
    INSERT INTO public.attendance_devices (serial_number, last_seen_at, last_ip)
    VALUES (p_sn, now(), p_ip)
    ON CONFLICT (serial_number) DO UPDATE
        SET last_seen_at = now(), last_ip = EXCLUDED.last_ip
    RETURNING is_active;
$$;

-- Machine ke ATTLOG punches. p_rows: [{pin, time: 'YYYY-MM-DD HH:MM:SS'
-- (machine ka Pakistan time), status, verify}]. Kitne row parhe wapas.
CREATE OR REPLACE FUNCTION public.attendance_ingest_punches(p_sn TEXT, p_rows JSONB)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    d     public.attendance_devices;
    r     JSONB;
    v_ts  TIMESTAMPTZ;
    v_uid UUID;
    v_id  BIGINT;
    n     INT := 0;
BEGIN
    SELECT * INTO d FROM public.attendance_devices WHERE serial_number = p_sn;
    IF NOT FOUND THEN RETURN 0; END IF;

    FOR r IN SELECT * FROM jsonb_array_elements(p_rows) LOOP
        BEGIN
            v_ts := (r->>'time')::timestamp AT TIME ZONE 'Asia/Karachi';
        EXCEPTION WHEN others THEN
            CONTINUE;  -- kharab line chhor do
        END;

        INSERT INTO public.attendance_punches (device_sn, pin, punch_at, status, verify)
        VALUES (p_sn, r->>'pin', v_ts,
                NULLIF(r->>'status', '')::int, NULLIF(r->>'verify', '')::int)
        ON CONFLICT (device_sn, pin, punch_at) DO NOTHING
        RETURNING id INTO v_id;
        n := n + 1;

        IF v_id IS NOT NULL AND d.is_active AND d.branch_id IS NOT NULL THEN
            SELECT id INTO v_uid FROM public.users WHERE machine_user_id = r->>'pin';
            IF v_uid IS NOT NULL THEN
                PERFORM public.attendance_apply_punch(v_uid, d.branch_id, v_ts);
                UPDATE public.attendance_punches SET applied = true WHERE id = v_id;
            END IF;
        END IF;
        v_id := NULL;
        v_uid := NULL;
    END LOOP;
    RETURN n;
END;
$$;

-- Machine approve / Machine ID set hone ke baad pehle ke ruke hue punches.
CREATE OR REPLACE FUNCTION public.attendance_reapply_pending()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    p RECORD;
    n INT := 0;
BEGIN
    FOR p IN
        SELECT ap.id, ap.punch_at, u.id AS user_id, d.branch_id
        FROM public.attendance_punches ap
        JOIN public.attendance_devices d ON d.serial_number = ap.device_sn
        JOIN public.users u ON u.machine_user_id = ap.pin
        WHERE NOT ap.applied AND d.is_active AND d.branch_id IS NOT NULL
        ORDER BY ap.punch_at
    LOOP
        PERFORM public.attendance_apply_punch(p.user_id, p.branch_id, p.punch_at);
        UPDATE public.attendance_punches SET applied = true WHERE id = p.id;
        n := n + 1;
    END LOOP;
    RETURN n;
END;
$$;

-- Machine wale functions sirf server (service role) chala sake.
REVOKE ALL ON FUNCTION public.attendance_apply_punch(UUID, UUID, TIMESTAMPTZ) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.attendance_device_seen(TEXT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.attendance_ingest_punches(TEXT, JSONB) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.attendance_device_seen(TEXT, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.attendance_ingest_punches(TEXT, JSONB) TO service_role;
REVOKE ALL ON FUNCTION public.attendance_reapply_pending() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.attendance_reapply_pending() TO authenticated;

ALTER PUBLICATION supabase_realtime ADD TABLE public.attendance_devices;

NOTIFY pgrst, 'reload schema';
