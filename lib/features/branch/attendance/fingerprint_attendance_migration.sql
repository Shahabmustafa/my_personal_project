-- ─────────────────────────────────────────────────────────────────────────────
-- FINGERPRINT ATTENDANCE (DigitalPersona U.are.U 4500 + branch PC helper)
--
--   1. Manager Staff Attendance mein "Register" dabata hai, staff finger lagata
--      hai → helper template banata hai → fingerprint_register() save karta hai.
--   2. Roz: staff finger lagata hai → helper branch ke templates se match karke
--      user_id nikalta hai → fingerprint_punch() chalta hai:
--         aaj ka check in nahi  → CHECK IN
--         check in hai, out nahi → CHECK OUT
--      Waqt hamesha server ka now().
--
-- Templates (biometric) table par seedha access nahi — sirf neeche ke RPC.
-- STATUS: NOT applied yet — Supabase SQL editor mein chalao.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.user_fingerprints (
    user_id      UUID         PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    template     TEXT         NOT NULL,          -- base64 FMD (helper ka banaya)
    registered_by UUID        REFERENCES public.users(id) ON DELETE SET NULL,
    registered_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.user_fingerprints ENABLE ROW LEVEL SECURITY;
-- Koi policy nahi + koi grant nahi: sirf SECURITY DEFINER functions access.
REVOKE ALL ON public.user_fingerprints FROM PUBLIC, anon, authenticated;

-- Caller us branch ka assigned user ho ya superadmin/admin/supervisor.
CREATE OR REPLACE FUNCTION public._fp_can_use_branch(p_branch_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
    SELECT EXISTS (SELECT 1 FROM public.user_branches
                   WHERE user_id = auth.uid() AND branch_id = p_branch_id)
        OR EXISTS (SELECT 1 FROM public.users
                   WHERE id = auth.uid()
                     AND role IN ('superadmin', 'admin', 'supervisor'));
$$;

-- Register / dobara register (purani template replace).
CREATE OR REPLACE FUNCTION public.fingerprint_register(
    p_user_id UUID, p_branch_id UUID, p_template TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
    IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Please log in again'; END IF;
    IF NOT public._fp_can_use_branch(p_branch_id) THEN
        RAISE EXCEPTION 'You are not assigned to this branch';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.user_branches
                   WHERE user_id = p_user_id AND branch_id = p_branch_id) THEN
        RAISE EXCEPTION 'This user is not in this branch';
    END IF;
    IF COALESCE(length(p_template), 0) < 20 THEN
        RAISE EXCEPTION 'Invalid fingerprint data';
    END IF;

    INSERT INTO public.user_fingerprints (user_id, template, registered_by)
    VALUES (p_user_id, p_template, auth.uid())
    ON CONFLICT (user_id) DO UPDATE
        SET template = EXCLUDED.template,
            registered_by = EXCLUDED.registered_by,
            registered_at = now();
END;
$$;

CREATE OR REPLACE FUNCTION public.fingerprint_remove(p_user_id UUID, p_branch_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
    IF NOT public._fp_can_use_branch(p_branch_id) THEN
        RAISE EXCEPTION 'You are not assigned to this branch';
    END IF;
    DELETE FROM public.user_fingerprints f
    USING public.user_branches ub
    WHERE f.user_id = p_user_id AND ub.user_id = f.user_id
      AND ub.branch_id = p_branch_id;
END;
$$;

-- Helper ko match ke liye is branch ke saare registered staff ki templates.
CREATE OR REPLACE FUNCTION public.fingerprint_templates_for_branch(p_branch_id UUID)
RETURNS TABLE (user_id UUID, template TEXT)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
    IF NOT public._fp_can_use_branch(p_branch_id) THEN
        RAISE EXCEPTION 'You are not assigned to this branch';
    END IF;
    RETURN QUERY
    SELECT f.user_id, f.template
    FROM public.user_fingerprints f
    JOIN public.user_branches ub ON ub.user_id = f.user_id
    JOIN public.users u ON u.id = f.user_id
    WHERE ub.branch_id = p_branch_id AND COALESCE(u.is_active, true);
END;
$$;

-- Kis kis ne fingerprint register ki (template wapas nahi aata).
CREATE OR REPLACE FUNCTION public.fingerprint_registered_users(p_branch_id UUID)
RETURNS TABLE (user_id UUID)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
    IF NOT public._fp_can_use_branch(p_branch_id) THEN
        RAISE EXCEPTION 'You are not assigned to this branch';
    END IF;
    RETURN QUERY
    SELECT f.user_id FROM public.user_fingerprints f
    JOIN public.user_branches ub ON ub.user_id = f.user_id
    WHERE ub.branch_id = p_branch_id;
END;
$$;

-- Punch: pehle check in nahi to check in, warna (khula record ho to) check out.
-- Result: action = 'check_in' | 'check_out'.
CREATE OR REPLACE FUNCTION public.fingerprint_punch(p_user_id UUID, p_branch_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_now   TIMESTAMPTZ := now();
    v_today DATE := (v_now AT TIME ZONE 'Asia/Karachi')::date;
    v_open  public.branch_attendance;
    v_day   public.branch_attendance;
    v_name  TEXT;
BEGIN
    IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Please log in again'; END IF;
    IF NOT public._fp_can_use_branch(p_branch_id) THEN
        RAISE EXCEPTION 'You are not assigned to this branch';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.user_branches
                   WHERE user_id = p_user_id AND branch_id = p_branch_id) THEN
        RAISE EXCEPTION 'This user is not in this branch';
    END IF;

    SELECT username INTO v_name FROM public.users WHERE id = p_user_id;

    -- Khula record (raat 12 ke baad bhi) → check out.
    SELECT * INTO v_open FROM public.branch_attendance
    WHERE user_id = p_user_id AND check_out_at IS NULL
      AND check_in_at >= v_now - INTERVAL '24 hours'
    ORDER BY check_in_at DESC LIMIT 1
    FOR UPDATE;

    IF FOUND THEN
        IF v_now < v_open.check_in_at + INTERVAL '2 minutes' THEN
            RAISE EXCEPTION '% has just checked in — try again in a moment', v_name;
        END IF;
        UPDATE public.branch_attendance SET check_out_at = v_now
        WHERE id = v_open.id;
        RETURN jsonb_build_object('action', 'check_out', 'username', v_name, 'at', v_now);
    END IF;

    SELECT * INTO v_day FROM public.branch_attendance
    WHERE user_id = p_user_id AND attendance_date = v_today;
    IF FOUND THEN
        RAISE EXCEPTION '% has already checked in and out today', v_name;
    END IF;

    INSERT INTO public.branch_attendance (user_id, branch_id, attendance_date, check_in_at)
    VALUES (p_user_id, p_branch_id, v_today, v_now);
    RETURN jsonb_build_object('action', 'check_in', 'username', v_name, 'at', v_now);
END;
$$;

REVOKE ALL ON FUNCTION public._fp_can_use_branch(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.fingerprint_register(UUID, UUID, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.fingerprint_remove(UUID, UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.fingerprint_templates_for_branch(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.fingerprint_registered_users(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.fingerprint_punch(UUID, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public._fp_can_use_branch(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fingerprint_register(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fingerprint_remove(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fingerprint_templates_for_branch(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fingerprint_registered_users(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fingerprint_punch(UUID, UUID) TO authenticated;

NOTIFY pgrst, 'reload schema';

-- ─────────────────────────────────────────────────────────────────────────────
-- OPTIONAL CLEANUP (purani ZKTeco machine ka DB). Sirf tab chalao jab
-- machine ka purana data nahi chahiye:
--   DROP FUNCTION IF EXISTS public.attendance_reapply_pending();
--   DROP FUNCTION IF EXISTS public.attendance_ingest_punches(TEXT, JSONB);
--   DROP FUNCTION IF EXISTS public.attendance_device_seen(TEXT, TEXT);
--   DROP FUNCTION IF EXISTS public.attendance_apply_punch(UUID, UUID, TIMESTAMPTZ);
--   DROP TABLE IF EXISTS public.attendance_punches;
--   DROP TABLE IF EXISTS public.attendance_devices;
--   ALTER TABLE public.users DROP COLUMN IF EXISTS machine_user_id;
-- ─────────────────────────────────────────────────────────────────────────────
