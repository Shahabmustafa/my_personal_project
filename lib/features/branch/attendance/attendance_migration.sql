-- ─────────────────────────────────────────────────────────────────────────────
-- BRANCH ATTENDANCE — manager / cashier / salesman ka check in / check out.
-- Ek user ka ek din (Pakistan time) mein ek record. Waqt hamesha server ka
-- now() — device ki ghari se nahi. User auth.uid() se pehchana jata hai,
-- is liye koi doosre ki attendance nahi laga sakta.
-- STATUS (2026-10-07): applied to LIVE database.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.branch_attendance (
    id               UUID         DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id          UUID         NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    branch_id        UUID         NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    attendance_date  DATE         NOT NULL,
    check_in_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    check_out_at     TIMESTAMPTZ,
    created_at       TIMESTAMPTZ  DEFAULT now(),
    UNIQUE (user_id, attendance_date),
    CONSTRAINT branch_attendance_out_after_in
        CHECK (check_out_at IS NULL OR check_out_at >= check_in_at)
);

CREATE INDEX IF NOT EXISTS idx_branch_attendance_branch_date
    ON public.branch_attendance (branch_id, attendance_date DESC);
CREATE INDEX IF NOT EXISTS idx_branch_attendance_user_date
    ON public.branch_attendance (user_id, attendance_date DESC);

ALTER TABLE public.branch_attendance ENABLE ROW LEVEL SECURITY;
CREATE POLICY authenticated_full_access ON public.branch_attendance
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Check in: sirf apni assigned branch mein, din mein ek baar.
CREATE OR REPLACE FUNCTION public.attendance_check_in(p_branch_id UUID)
RETURNS public.branch_attendance
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
DECLARE
    v_uid   UUID := auth.uid();
    v_today DATE := (now() AT TIME ZONE 'Asia/Karachi')::date;
    v_row   public.branch_attendance;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Please log in again';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.user_branches
                   WHERE user_id = v_uid AND branch_id = p_branch_id) THEN
        RAISE EXCEPTION 'You are not assigned to this branch';
    END IF;

    INSERT INTO public.branch_attendance (user_id, branch_id, attendance_date)
    VALUES (v_uid, p_branch_id, v_today)
    ON CONFLICT (user_id, attendance_date) DO NOTHING
    RETURNING * INTO v_row;

    IF v_row.id IS NULL THEN
        RAISE EXCEPTION 'You have already checked in today';
    END IF;
    RETURN v_row;
END;
$$;

-- Check out: user ka sab se naya khula record band — raat 12 ke baad bhi.
CREATE OR REPLACE FUNCTION public.attendance_check_out()
RETURNS public.branch_attendance
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_row public.branch_attendance;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Please log in again';
    END IF;

    UPDATE public.branch_attendance
    SET check_out_at = now()
    WHERE id = (SELECT id FROM public.branch_attendance
                WHERE user_id = v_uid AND check_out_at IS NULL
                ORDER BY check_in_at DESC
                LIMIT 1)
    RETURNING * INTO v_row;

    IF v_row.id IS NULL THEN
        RAISE EXCEPTION 'Please check in first';
    END IF;
    RETURN v_row;
END;
$$;

-- Branch ke saare manager/cashier/salesman + [p_date] ki attendance
-- (na aaye to check_in_at NULL).
CREATE OR REPLACE FUNCTION public.branch_attendance_for_day(p_branch_id UUID, p_date DATE)
RETURNS TABLE (
    user_id      UUID,
    username     TEXT,
    role         TEXT,
    check_in_at  TIMESTAMPTZ,
    check_out_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $$
    SELECT u.id, u.username, u.role, a.check_in_at, a.check_out_at
    FROM public.user_branches ub
    JOIN public.users u ON u.id = ub.user_id
    LEFT JOIN public.branch_attendance a
           ON a.user_id = u.id
          AND a.branch_id = p_branch_id
          AND a.attendance_date = p_date
    WHERE ub.branch_id = p_branch_id
      AND u.role IN ('manager', 'cashier', 'salesman')
      AND COALESCE(u.is_active, true)
    ORDER BY CASE u.role WHEN 'manager' THEN 0 WHEN 'cashier' THEN 1 ELSE 2 END,
             lower(u.username);
$$;

GRANT EXECUTE ON FUNCTION public.attendance_check_in(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.attendance_check_out() TO authenticated;
GRANT EXECUTE ON FUNCTION public.branch_attendance_for_day(UUID, DATE) TO authenticated;

-- Manager ki screen live update ho.
ALTER PUBLICATION supabase_realtime ADD TABLE public.branch_attendance;

NOTIFY pgrst, 'reload schema';
