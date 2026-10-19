-- H1 Stage 2: branch-wise WRITE scoping (read sab authenticated ko — cross-branch
-- lookups jaise sale return ke invoice dropdown pehle jaise chalte hain).
-- Stage 1 (rls_stage1_migration.sql) pehle lag chuki honi chahiye (is_superadmin()).
--
-- Zaroori: sync_* triggers doosri branch ke stock / salary rows bhi update karte
-- hain (cross-branch sale return, manager/salesman doosri branch ke). Isliye pehle
-- unhein SECURITY DEFINER kiya jata hai (search_path pehle se fixed hai).

CREATE OR REPLACE FUNCTION public.can_access_branch(b uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp AS $$
  SELECT public.is_superadmin() OR EXISTS (
    SELECT 1 FROM public.user_branches ub WHERE ub.user_id = auth.uid() AND ub.branch_id = b)
$$;
REVOKE ALL ON FUNCTION public.can_access_branch(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.can_access_branch(uuid) TO authenticated, service_role;

DO $$
DECLARE f record;
BEGIN
  FOR f IN SELECT p.oid::regprocedure AS sig FROM pg_proc p
           WHERE p.pronamespace = 'public'::regnamespace AND p.proname LIKE 'sync\_%'
  LOOP
    EXECUTE format('ALTER FUNCTION %s SECURITY DEFINER', f.sig);
  END LOOP;
END $$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'bank_entries','branch_attendance','branch_cash_counter','branch_stock_inventory',
    'expense_entries','sale_exchange_new_items','sale_exchange_payments',
    'sale_exchange_return_items','sale_exchanges','sale_invoice_items',
    'sale_invoice_payments','sale_invoices','sale_return_items','sale_return_payments',
    'sale_returns','sale_claims','attendance_devices'
  ] LOOP
    EXECUTE format('DROP POLICY IF EXISTS authenticated_full_access ON public.%I', t);
    EXECUTE format('DROP POLICY IF EXISTS read_all ON public.%I', t);
    EXECUTE format('DROP POLICY IF EXISTS branch_write ON public.%I', t);
    EXECUTE format('CREATE POLICY read_all ON public.%I FOR SELECT TO authenticated USING (true)', t);
    EXECUTE format('CREATE POLICY branch_write ON public.%I FOR ALL TO authenticated USING (public.can_access_branch(branch_id)) WITH CHECK (public.can_access_branch(branch_id))', t);
  END LOOP;
END $$;

-- Walk-in customer branches ke darmiyan shared hai.
DROP POLICY IF EXISTS authenticated_full_access ON public.customers;
DROP POLICY IF EXISTS read_all ON public.customers;
DROP POLICY IF EXISTS branch_write ON public.customers;
CREATE POLICY read_all ON public.customers FOR SELECT TO authenticated USING (true);
CREATE POLICY branch_write ON public.customers FOR ALL TO authenticated
  USING (public.can_access_branch(branch_id) OR is_walkin)
  WITH CHECK (public.can_access_branch(branch_id) OR is_walkin);

-- Salary rows sirf superadmin client se badal sakta hai; commission/return
-- totals triggers (ab SECURITY DEFINER) se update hote hain.
DROP POLICY IF EXISTS authenticated_full_access ON public.employee_salary;
DROP POLICY IF EXISTS read_all ON public.employee_salary;
DROP POLICY IF EXISTS superadmin_write ON public.employee_salary;
CREATE POLICY read_all ON public.employee_salary FOR SELECT TO authenticated USING (true);
CREATE POLICY superadmin_write ON public.employee_salary FOR ALL TO authenticated
  USING (public.is_superadmin()) WITH CHECK (public.is_superadmin());

-- Abhi nahi chhede (Stage 3): head office / warehouse tables, branch_payments,
-- branch_return_to_warehouse, branch_stock_returns, companies, products & masters.
