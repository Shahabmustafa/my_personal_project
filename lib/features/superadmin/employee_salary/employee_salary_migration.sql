-- ─────────────────────────────────────────────────────────────────────────────
-- EMPLOYEE SALARY
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.employee_salary (
    id                  UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id             UUID            NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    branch_id           UUID            NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    salary              NUMERIC(12, 2)  DEFAULT 0,
    commission_percent  NUMERIC(5, 2)   DEFAULT 0,
    total_sales         NUMERIC(12, 2)  DEFAULT 0,
    total_sales_return  NUMERIC(12, 2)  DEFAULT 0,
    net_salary          NUMERIC(12, 2)  GENERATED ALWAYS AS (
                            salary + ((total_sales - total_sales_return) * commission_percent / 100)
                        ) STORED,
    created_at          TIMESTAMPTZ     DEFAULT now(),
    updated_at          TIMESTAMPTZ     DEFAULT now(),

    UNIQUE (user_id, branch_id)
);

ALTER TABLE public.employee_salary DISABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.employee_salary TO authenticated;

-- =============================================
-- Har mahine ki 1 tareekh (00:00 Pakistan time) ko total_sales aur
-- total_sales_return 0 ho jate hain — Salary/Commission % wahi rehte hain.
-- UNIQUE(user_id, branch_id) ki wajah se ek hi row rehta hai (naya row
-- nahi banta, history nahi rakhi jati — reset in-place hota hai).
-- Job roz raat 00:00 PKT (19:00 UTC) chalti hai, sirf 1 tareekh ko kuch
-- karti hai (branch_cash_counter ki nightly job jaisa hi PKT-anchored pattern).
-- =============================================
SELECT cron.schedule(
    'monthly-employee-salary-reset',
    '0 19 * * *',
    $$
    UPDATE public.employee_salary
    SET total_sales = 0,
        total_sales_return = 0
    WHERE EXTRACT(DAY FROM (now() AT TIME ZONE 'Asia/Karachi')) = 1;
    $$
);

-- Reload schema cache
NOTIFY pgrst, 'reload schema';
