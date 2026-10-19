-- ─────────────────────────────────────────────────────────────────────────────
-- AUTO-LINK: pehli baar fingerprint register nahi hota.
--   1. Naya employee (machine_user_id khali) app se Check In karta hai.
--   2. Baad mein machine par thumb lagata hai (check out) — machine ka PIN
--      kisi user se linked nahi hota.
--   3. Us branch mein agar SIRF EK aisa user ho jo check in hai (khula
--      record), jiska machine_user_id khali hai, to PIN usi se link ho jata
--      hai aur ye punch uska check out ban jata hai.
-- Ek se zyada candidate ho (ya koi na ho) to punch pending rehta hai — galat
-- banday se link na ho. Manager/admin "Machine ID" khud set kar sakta hai,
-- phir attendance_reapply_pending() punch laga deta hai.
-- STATUS: NOT applied yet — Supabase SQL editor mein chalao.
-- ─────────────────────────────────────────────────────────────────────────────

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
    v_cnt INT;
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

            -- PIN kisi se linked nahi — check out ke waqt auto-link try karo.
            IF v_uid IS NULL THEN
                SELECT count(*) INTO v_cnt
                FROM public.branch_attendance a
                JOIN public.users u ON u.id = a.user_id
                WHERE a.branch_id = d.branch_id
                  AND a.check_out_at IS NULL
                  AND a.check_in_at <= v_ts - INTERVAL '2 minutes'
                  AND a.check_in_at >= v_ts - INTERVAL '24 hours'
                  AND u.machine_user_id IS NULL
                  AND u.role IN ('manager', 'cashier', 'salesman')
                  AND COALESCE(u.is_active, true);

                IF v_cnt = 1 THEN
                    SELECT u.id INTO v_uid
                    FROM public.branch_attendance a
                    JOIN public.users u ON u.id = a.user_id
                    WHERE a.branch_id = d.branch_id
                      AND a.check_out_at IS NULL
                      AND a.check_in_at <= v_ts - INTERVAL '2 minutes'
                      AND a.check_in_at >= v_ts - INTERVAL '24 hours'
                      AND u.machine_user_id IS NULL
                      AND u.role IN ('manager', 'cashier', 'salesman')
                      AND COALESCE(u.is_active, true);
                    BEGIN
                        UPDATE public.users SET machine_user_id = r->>'pin'
                        WHERE id = v_uid AND machine_user_id IS NULL;
                    EXCEPTION WHEN unique_violation THEN
                        v_uid := NULL;  -- PIN ab kisi aur se link ho chuka
                    END;
                END IF;
            END IF;

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

REVOKE ALL ON FUNCTION public.attendance_ingest_punches(TEXT, JSONB) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.attendance_ingest_punches(TEXT, JSONB) TO service_role;
