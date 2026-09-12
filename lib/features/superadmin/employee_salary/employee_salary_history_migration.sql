-- ─────────────────────────────────────────────────────────────────────────────
-- EMPLOYEE SALARY HISTORY
-- Har mahine ki 1 tareekh ko employee_salary reset hone se pehle, us
-- (abhi khatam hue) mahine ka total_sales/total_sales_return/net_salary
-- yahan ek naya row ban kar preserve ho jata hai — is se purana data
-- kho nahi jata, sirf live counter 0 hota hai.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.employee_salary_history (
    id                  UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    employee_salary_id  UUID            NOT NULL REFERENCES public.employee_salary(id) ON DELETE CASCADE,
    user_id             UUID            NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    branch_id           UUID            NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    period_month        DATE            NOT NULL,
    salary              NUMERIC(12, 2)  DEFAULT 0,
    commission_percent  NUMERIC(5, 2)   DEFAULT 0,
    total_sales         NUMERIC(12, 2)  DEFAULT 0,
    total_sales_return  NUMERIC(12, 2)  DEFAULT 0,
    net_salary          NUMERIC(12, 2)  DEFAULT 0,
    created_at          TIMESTAMPTZ     DEFAULT now(),

    UNIQUE (employee_salary_id, period_month)
);

CREATE INDEX IF NOT EXISTS idx_employee_salary_history_employee_salary_id
    ON public.employee_salary_history(employee_salary_id);

ALTER TABLE public.employee_salary_history DISABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.employee_salary_history TO authenticated;

-- =============================================
-- monthly-employee-salary-reset ko update kiya: ab 1 tareekh ko reset
-- karne se pehle current (khatam hone wale) mahine ka total_sales/
-- total_sales_return/net_salary employee_salary_history mein archive
-- ho jata hai, phir hi employee_salary par reset hota hai.
-- =============================================
SELECT cron.schedule(
    'monthly-employee-salary-reset',
    '0 19 * * *',
    $$
    DO $do$
    BEGIN
        IF EXTRACT(DAY FROM (now() AT TIME ZONE 'Asia/Karachi')) = 1 THEN
            INSERT INTO public.employee_salary_history (
                employee_salary_id, user_id, branch_id, period_month,
                salary, commission_percent, total_sales, total_sales_return, net_salary
            )
            SELECT
                id, user_id, branch_id,
                date_trunc('month', (now() AT TIME ZONE 'Asia/Karachi') - interval '1 day')::date,
                salary, commission_percent, total_sales, total_sales_return, net_salary
            FROM public.employee_salary
            WHERE total_sales <> 0 OR total_sales_return <> 0
            ON CONFLICT (employee_salary_id, period_month) DO NOTHING;

            UPDATE public.employee_salary
            SET total_sales = 0,
                total_sales_return = 0;
        END IF;
    END;
    $do$;
    $$
);

-- Reload schema cache
NOTIFY pgrst, 'reload schema';
