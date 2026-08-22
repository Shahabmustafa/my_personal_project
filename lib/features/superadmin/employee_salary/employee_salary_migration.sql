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

-- Reload schema cache
NOTIFY pgrst, 'reload schema';
