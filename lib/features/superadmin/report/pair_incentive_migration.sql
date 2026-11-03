-- ─────────────────────────────────────────────────────────────────────────────
-- PAIR INCENTIVE (per-pair commission) — salesman + manager
--
--   * Admin har employee (salesman / manager) ka "Rs per pair" rate set karta
--     hai (employee_salary.pair_rate).
--   * Salesman: apne sale_invoices ke pairs − apne sale_returns ke pairs.
--     Manager: apni branch ke (invoice.manager_id) pairs − unke returns.
--     Return ka pair dono se katta hai. Exchange bhi: exchange ke NAYE pairs
--     "sold" mein jur-te hain, WAPAS aaye pairs "returned" mein (salesman =
--     exchange.salesman_id, manager = original invoice ka manager). Barabar
--     pairs ka exchange net 0 rehta hai.
--   * Mahina PKT (Asia/Karachi) ke hisaab se.
--   * Paisa seedha nahi milta: branch ka mahine ka net sale (invoices − returns
--     + exchange difference — Branch Target report jaisa) mahine ke target
--     (branch_daily_targets ka jama) tak pahunche to admin ko "Accept" milta
--     hai. Accept par us waqt ke pairs/rate ka snapshot save hota hai.
--   * Report: pair_incentive_report (employee-wise) + pair_incentive_months
--     (branch-wise target / approve status). Monthly aur yearly dono.
-- STATUS: NOT applied yet — Supabase SQL editor mein chalao.
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.employee_salary
    ADD COLUMN IF NOT EXISTS pair_rate NUMERIC(8, 2) NOT NULL DEFAULT 0
        CHECK (pair_rate >= 0);

CREATE TABLE IF NOT EXISTS public.pair_incentive_payouts (
    id          UUID          DEFAULT gen_random_uuid() PRIMARY KEY,
    branch_id   UUID          NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    month       DATE          NOT NULL,            -- mahine ka pehla din
    target      NUMERIC(15,2) NOT NULL DEFAULT 0,
    net_sale    NUMERIC(15,2) NOT NULL DEFAULT 0,
    approved_by UUID          REFERENCES public.users(id) ON DELETE SET NULL,
    approved_at TIMESTAMPTZ   NOT NULL DEFAULT now(),
    UNIQUE (branch_id, month)
);

CREATE TABLE IF NOT EXISTS public.pair_incentive_payout_lines (
    payout_id          UUID          NOT NULL REFERENCES public.pair_incentive_payouts(id) ON DELETE CASCADE,
    employee_salary_id UUID          NOT NULL REFERENCES public.employee_salary(id) ON DELETE CASCADE,
    pairs_sold         INT           NOT NULL DEFAULT 0,
    pairs_returned     INT           NOT NULL DEFAULT 0,
    rate               NUMERIC(8,2)  NOT NULL DEFAULT 0,
    amount             NUMERIC(15,2) NOT NULL DEFAULT 0,
    PRIMARY KEY (payout_id, employee_salary_id)
);

ALTER TABLE public.pair_incentive_payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pair_incentive_payout_lines ENABLE ROW LEVEL SECURITY;
-- Sirf SECURITY DEFINER functions se access.
REVOKE ALL ON public.pair_incentive_payouts FROM PUBLIC, anon, authenticated;
REVOKE ALL ON public.pair_incentive_payout_lines FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public._pi_is_admin()
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
    SELECT EXISTS (SELECT 1 FROM public.users
                   WHERE id = auth.uid()
                     AND role IN ('superadmin', 'admin', 'supervisor'));
$$;

-- Admin sab branches dekhta hai; baqi sirf apni assigned branch(es).
CREATE OR REPLACE FUNCTION public._pi_can_view(p_branch_id UUID)
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
    SELECT public._pi_is_admin()
        OR EXISTS (SELECT 1 FROM public.user_branches
                   WHERE user_id = auth.uid() AND branch_id = p_branch_id);
$$;

-- Branch + mahine ka target, net sale, achieved, approve status.
-- p_from / p_to: tareekhein (PKT), mahine ki hadd par round hoti hain.
CREATE OR REPLACE FUNCTION public.pair_incentive_months(
    p_from DATE, p_to DATE, p_branch_id UUID DEFAULT NULL)
RETURNS TABLE (
    month DATE, branch_id UUID, branch_name TEXT,
    target NUMERIC, net_sale NUMERIC, achieved BOOLEAN,
    approved BOOLEAN, approved_at TIMESTAMPTZ)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
    WITH rng AS (
        SELECT date_trunc('month', p_from)::date AS m_from,
               (date_trunc('month', p_to) + INTERVAL '1 month')::date AS m_to
    ),
    months AS (
        SELECT generate_series(m_from, m_to - 1, INTERVAL '1 month')::date AS month
        FROM rng
    ),
    br AS (
        SELECT b.id, b.branch_name FROM public.branches b
        WHERE b.status = 'active'
          AND (p_branch_id IS NULL OR b.id = p_branch_id)
          AND public._pi_can_view(b.id)
    ),
    tgt AS (
        SELECT t.branch_id, date_trunc('month', t.target_date)::date AS month,
               SUM(t.amount) AS target
        FROM public.branch_daily_targets t, rng
        WHERE t.target_date >= rng.m_from AND t.target_date < rng.m_to
        GROUP BY 1, 2
    ),
    sales AS (
        SELECT x.branch_id, x.month, SUM(x.amt) AS net_sale FROM (
            SELECT i.branch_id,
                   date_trunc('month', i.created_at AT TIME ZONE 'Asia/Karachi')::date AS month,
                   i.total_amount AS amt
            FROM public.sale_invoices i, rng
            WHERE (i.created_at AT TIME ZONE 'Asia/Karachi') >= rng.m_from
              AND (i.created_at AT TIME ZONE 'Asia/Karachi') <  rng.m_to
            UNION ALL
            SELECT r.branch_id,
                   date_trunc('month', r.created_at AT TIME ZONE 'Asia/Karachi')::date,
                   -r.total_amount
            FROM public.sale_returns r, rng
            WHERE (r.created_at AT TIME ZONE 'Asia/Karachi') >= rng.m_from
              AND (r.created_at AT TIME ZONE 'Asia/Karachi') <  rng.m_to
            UNION ALL
            SELECT e.branch_id,
                   date_trunc('month', e.created_at AT TIME ZONE 'Asia/Karachi')::date,
                   e.difference_amount
            FROM public.sale_exchanges e, rng
            WHERE (e.created_at AT TIME ZONE 'Asia/Karachi') >= rng.m_from
              AND (e.created_at AT TIME ZONE 'Asia/Karachi') <  rng.m_to
        ) x GROUP BY 1, 2
    )
    SELECT m.month, br.id, br.branch_name,
           COALESCE(CASE WHEN po.id IS NOT NULL THEN po.target END, tgt.target, 0),
           COALESCE(CASE WHEN po.id IS NOT NULL THEN po.net_sale END, s.net_sale, 0),
           (COALESCE(CASE WHEN po.id IS NOT NULL THEN po.target END, tgt.target, 0) > 0
            AND COALESCE(CASE WHEN po.id IS NOT NULL THEN po.net_sale END, s.net_sale, 0)
                >= COALESCE(CASE WHEN po.id IS NOT NULL THEN po.target END, tgt.target, 0)),
           po.id IS NOT NULL,
           po.approved_at
    FROM months m
    CROSS JOIN br
    LEFT JOIN tgt ON tgt.branch_id = br.id AND tgt.month = m.month
    LEFT JOIN sales s ON s.branch_id = br.id AND s.month = m.month
    LEFT JOIN public.pair_incentive_payouts po
           ON po.branch_id = br.id AND po.month = m.month
    ORDER BY m.month, br.branch_name;
$$;

-- Employee-wise pairs (salesman + manager). Approved mahine ka snapshot
-- dikhta hai, warna live hisab (rate = employee ka mojooda pair_rate).
CREATE OR REPLACE FUNCTION public.pair_incentive_report(
    p_from DATE, p_to DATE, p_branch_id UUID DEFAULT NULL)
RETURNS TABLE (
    month DATE, branch_id UUID, branch_name TEXT,
    employee_id UUID, user_id UUID, username TEXT, role TEXT,
    pairs_sold INT, pairs_returned INT, rate NUMERIC, amount NUMERIC,
    approved BOOLEAN)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
    WITH rng AS (
        SELECT date_trunc('month', p_from)::date AS m_from,
               (date_trunc('month', p_to) + INTERVAL '1 month')::date AS m_to
    ),
    months AS (
        SELECT generate_series(m_from, m_to - 1, INTERVAL '1 month')::date AS month
        FROM rng
    ),
    emp AS (
        SELECT es.id, es.user_id, es.branch_id, es.pair_rate, u.username, u.role,
               b.branch_name
        FROM public.employee_salary es
        JOIN public.users u ON u.id = es.user_id
        JOIN public.branches b ON b.id = es.branch_id
        WHERE u.role IN ('manager', 'salesman')
          AND COALESCE(u.is_active, true)
          AND b.status = 'active'
          AND (p_branch_id IS NULL OR es.branch_id = p_branch_id)
          AND public._pi_can_view(es.branch_id)
    ),
    -- kind: 'manager' (invoice.manager_id) ya 'salesman' (invoice.salesman_id)
    -- sold = sale invoice pairs + exchange ke NAYE pairs
    sold AS (
        SELECT u.kind, u.emp_id, u.month, SUM(u.pairs)::int AS pairs FROM (
            SELECT k.kind,
                   CASE k.kind WHEN 'manager' THEN i.manager_id ELSE i.salesman_id END AS emp_id,
                   date_trunc('month', i.created_at AT TIME ZONE 'Asia/Karachi')::date AS month,
                   it.quantity AS pairs
            FROM public.sale_invoices i
            JOIN public.sale_invoice_items it ON it.sale_invoice_id = i.id
            CROSS JOIN rng
            CROSS JOIN (VALUES ('manager'), ('salesman')) AS k(kind)
            WHERE (i.created_at AT TIME ZONE 'Asia/Karachi') >= rng.m_from
              AND (i.created_at AT TIME ZONE 'Asia/Karachi') <  rng.m_to
            UNION ALL
            SELECT k.kind,
                   CASE k.kind
                       WHEN 'manager' THEN public.return_manager_salary_id(x.original_invoice_id, x.branch_id)
                       ELSE x.salesman_id END,
                   date_trunc('month', x.created_at AT TIME ZONE 'Asia/Karachi')::date,
                   it.quantity
            FROM public.sale_exchanges x
            JOIN public.sale_exchange_new_items it ON it.sale_exchange_id = x.id
            CROSS JOIN rng
            CROSS JOIN (VALUES ('manager'), ('salesman')) AS k(kind)
            WHERE (x.created_at AT TIME ZONE 'Asia/Karachi') >= rng.m_from
              AND (x.created_at AT TIME ZONE 'Asia/Karachi') <  rng.m_to
        ) u GROUP BY 1, 2, 3
    ),
    -- ret = sale return pairs + exchange ke WAPAS aaye pairs
    ret AS (
        SELECT u.kind, u.emp_id, u.month, SUM(u.pairs)::int AS pairs FROM (
            SELECT k.kind,
                   CASE k.kind
                       WHEN 'manager' THEN public.return_manager_salary_id(r.original_invoice_id, r.branch_id)
                       ELSE r.salesman_id END AS emp_id,
                   date_trunc('month', r.created_at AT TIME ZONE 'Asia/Karachi')::date AS month,
                   it.quantity AS pairs
            FROM public.sale_returns r
            JOIN public.sale_return_items it ON it.sale_return_id = r.id
            CROSS JOIN rng
            CROSS JOIN (VALUES ('manager'), ('salesman')) AS k(kind)
            WHERE (r.created_at AT TIME ZONE 'Asia/Karachi') >= rng.m_from
              AND (r.created_at AT TIME ZONE 'Asia/Karachi') <  rng.m_to
            UNION ALL
            SELECT k.kind,
                   CASE k.kind
                       WHEN 'manager' THEN public.return_manager_salary_id(x.original_invoice_id, x.branch_id)
                       ELSE x.salesman_id END,
                   date_trunc('month', x.created_at AT TIME ZONE 'Asia/Karachi')::date,
                   it.quantity
            FROM public.sale_exchanges x
            JOIN public.sale_exchange_return_items it ON it.sale_exchange_id = x.id
            CROSS JOIN rng
            CROSS JOIN (VALUES ('manager'), ('salesman')) AS k(kind)
            WHERE (x.created_at AT TIME ZONE 'Asia/Karachi') >= rng.m_from
              AND (x.created_at AT TIME ZONE 'Asia/Karachi') <  rng.m_to
        ) u GROUP BY 1, 2, 3
    ),
    live AS (
        SELECT e.*, m.month,
               COALESCE((SELECT SUM(s.pairs) FROM sold s
                         WHERE s.emp_id = e.id AND s.kind = e.role AND s.month = m.month), 0)::int AS p_sold,
               COALESCE((SELECT SUM(t.pairs) FROM ret t
                         WHERE t.emp_id = e.id AND t.kind = e.role AND t.month = m.month), 0)::int AS p_ret
        FROM emp e CROSS JOIN months m
    )
    SELECT l.month, l.branch_id, l.branch_name, l.id, l.user_id, l.username, l.role,
           COALESCE(pl.pairs_sold, l.p_sold),
           COALESCE(pl.pairs_returned, l.p_ret),
           COALESCE(pl.rate, l.pair_rate),
           COALESCE(pl.amount,
                    GREATEST(l.p_sold - l.p_ret, 0) * l.pair_rate),
           pl.payout_id IS NOT NULL
    FROM live l
    LEFT JOIN public.pair_incentive_payouts po
           ON po.branch_id = l.branch_id AND po.month = l.month
    LEFT JOIN public.pair_incentive_payout_lines pl
           ON pl.payout_id = po.id AND pl.employee_salary_id = l.id
    ORDER BY l.month, l.branch_name,
             CASE l.role WHEN 'manager' THEN 0 ELSE 1 END, lower(l.username);
$$;

-- Admin "Accept": target poora ho to us mahine ka snapshot save.
CREATE OR REPLACE FUNCTION public.pair_incentive_approve(p_branch_id UUID, p_month DATE)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_month  DATE := date_trunc('month', p_month)::date;
    v_target NUMERIC;
    v_net    NUMERIC;
    v_ok     BOOLEAN;
    v_pid    UUID;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.users
                   WHERE id = auth.uid() AND role = 'superadmin') THEN
        RAISE EXCEPTION 'Only admin can accept';
    END IF;
    IF v_month >= date_trunc('month', now() AT TIME ZONE 'Asia/Karachi')::date + INTERVAL '1 month' THEN
        RAISE EXCEPTION 'This month has not started';
    END IF;
    IF EXISTS (SELECT 1 FROM public.pair_incentive_payouts
               WHERE branch_id = p_branch_id AND month = v_month) THEN
        RAISE EXCEPTION 'Already accepted for this month';
    END IF;

    SELECT m.target, m.net_sale, m.achieved INTO v_target, v_net, v_ok
    FROM public.pair_incentive_months(v_month, v_month, p_branch_id) m LIMIT 1;
    IF NOT COALESCE(v_ok, false) THEN
        RAISE EXCEPTION 'Branch target is not achieved for this month';
    END IF;

    INSERT INTO public.pair_incentive_payouts
        (branch_id, month, target, net_sale, approved_by)
    VALUES (p_branch_id, v_month, v_target, v_net, auth.uid())
    RETURNING id INTO v_pid;

    INSERT INTO public.pair_incentive_payout_lines
        (payout_id, employee_salary_id, pairs_sold, pairs_returned, rate, amount)
    SELECT v_pid, r.employee_id, r.pairs_sold, r.pairs_returned, r.rate, r.amount
    FROM public.pair_incentive_report(v_month, v_month, p_branch_id) r;
END;
$$;

REVOKE ALL ON FUNCTION public._pi_is_admin() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public._pi_can_view(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.pair_incentive_months(DATE, DATE, UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.pair_incentive_report(DATE, DATE, UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.pair_incentive_approve(UUID, DATE) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public._pi_is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public._pi_can_view(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pair_incentive_months(DATE, DATE, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pair_incentive_report(DATE, DATE, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pair_incentive_approve(UUID, DATE) TO authenticated;

NOTIFY pgrst, 'reload schema';

-- Ek employee ke ek mahine ke din-wise pairs (naya din pehle). Applied: 2026-11-01.
CREATE OR REPLACE FUNCTION public.pair_incentive_days(p_employee_id UUID, p_month DATE)
RETURNS TABLE (day DATE, pairs_sold INT, pairs_returned INT)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
    WITH e AS (
        SELECT es.id, es.branch_id, u.role
        FROM public.employee_salary es
        JOIN public.users u ON u.id = es.user_id
        WHERE es.id = p_employee_id
          AND public._pi_can_view(es.branch_id)
    ),
    rng AS (
        SELECT date_trunc('month', p_month)::date AS d_from,
               (date_trunc('month', p_month) + INTERVAL '1 month')::date AS d_to
    ),
    days AS (
        SELECT generate_series(d_from, d_to - 1, INTERVAL '1 day')::date AS day FROM rng
    ),
    sold AS (
        SELECT u.day, SUM(u.pairs)::int AS pairs FROM (
            SELECT (i.created_at AT TIME ZONE 'Asia/Karachi')::date AS day,
                   it.quantity AS pairs
            FROM e, rng, public.sale_invoices i
            JOIN public.sale_invoice_items it ON it.sale_invoice_id = i.id
            WHERE (i.created_at AT TIME ZONE 'Asia/Karachi') >= rng.d_from
              AND (i.created_at AT TIME ZONE 'Asia/Karachi') <  rng.d_to
              AND CASE WHEN e.role = 'manager' THEN i.manager_id ELSE i.salesman_id END = e.id
            UNION ALL
            -- exchange ke NAYE pairs
            SELECT (x.created_at AT TIME ZONE 'Asia/Karachi')::date, it.quantity
            FROM e, rng, public.sale_exchanges x
            JOIN public.sale_exchange_new_items it ON it.sale_exchange_id = x.id
            WHERE (x.created_at AT TIME ZONE 'Asia/Karachi') >= rng.d_from
              AND (x.created_at AT TIME ZONE 'Asia/Karachi') <  rng.d_to
              AND CASE WHEN e.role = 'manager'
                       THEN public.return_manager_salary_id(x.original_invoice_id, x.branch_id)
                       ELSE x.salesman_id END = e.id
        ) u GROUP BY 1
    ),
    ret AS (
        SELECT u.day, SUM(u.pairs)::int AS pairs FROM (
            SELECT (r.created_at AT TIME ZONE 'Asia/Karachi')::date AS day,
                   it.quantity AS pairs
            FROM e, rng, public.sale_returns r
            JOIN public.sale_return_items it ON it.sale_return_id = r.id
            WHERE (r.created_at AT TIME ZONE 'Asia/Karachi') >= rng.d_from
              AND (r.created_at AT TIME ZONE 'Asia/Karachi') <  rng.d_to
              AND CASE WHEN e.role = 'manager'
                       THEN public.return_manager_salary_id(r.original_invoice_id, r.branch_id)
                       ELSE r.salesman_id END = e.id
            UNION ALL
            -- exchange ke WAPAS aaye pairs
            SELECT (x.created_at AT TIME ZONE 'Asia/Karachi')::date, it.quantity
            FROM e, rng, public.sale_exchanges x
            JOIN public.sale_exchange_return_items it ON it.sale_exchange_id = x.id
            WHERE (x.created_at AT TIME ZONE 'Asia/Karachi') >= rng.d_from
              AND (x.created_at AT TIME ZONE 'Asia/Karachi') <  rng.d_to
              AND CASE WHEN e.role = 'manager'
                       THEN public.return_manager_salary_id(x.original_invoice_id, x.branch_id)
                       ELSE x.salesman_id END = e.id
        ) u GROUP BY 1
    )
    SELECT d.day, COALESCE(s.pairs, 0), COALESCE(t.pairs, 0)
    FROM days d
    LEFT JOIN sold s ON s.day = d.day
    LEFT JOIN ret t ON t.day = d.day
    WHERE EXISTS (SELECT 1 FROM e)
    ORDER BY d.day DESC;
$$;
REVOKE ALL ON FUNCTION public.pair_incentive_days(UUID, DATE) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.pair_incentive_days(UUID, DATE) TO authenticated;
NOTIFY pgrst, 'reload schema';
