-- H1 Stage 3: catalog / warehouse / purchase tables par write se branch-only
-- roles (cashier, manager, salesman) hata diye; read sab ko. Trigger functions
-- se EXECUTE hata diya (triggers ko fire hone ke liye EXECUTE nahi chahiye).
-- Live par apply ho chuki (rollback-test pass: cashier blocked, cashier sale OK,
-- superadmin/supervisor OK).
-- Abhi bhi open (branch workflows ki wajah se): assign_stock_to_branch(+items),
-- head_office_cash_counter, head_office_expenses, expense_heads, branch_payments,
-- branch_return_to_warehouse(+items), branch_stock_returns(+items), attendance_punches.
CREATE OR REPLACE FUNCTION public.can_manage_catalog() RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp AS $$
  SELECT COALESCE(public.app_role() NOT IN ('cashier','manager','salesman'), false)
$$;
REVOKE ALL ON FUNCTION public.can_manage_catalog() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.can_manage_catalog() TO authenticated, service_role;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'brands','categories','colors','sizes','size_groups','types','products','companies',
    'stock_inventory','warehouse_stock_inventory','warehouse_cash_counter',
    'purchase_invoices','purchase_invoice_items','purchase_returns','purchase_return_items'
  ] LOOP
    EXECUTE format('DROP POLICY IF EXISTS authenticated_full_access ON public.%I', t);
    EXECUTE format('DROP POLICY IF EXISTS read_all ON public.%I', t);
    EXECUTE format('DROP POLICY IF EXISTS staff_write ON public.%I', t);
    EXECUTE format('CREATE POLICY read_all ON public.%I FOR SELECT TO authenticated USING (true)', t);
    EXECUTE format('CREATE POLICY staff_write ON public.%I FOR ALL TO authenticated USING (public.can_manage_catalog()) WITH CHECK (public.can_manage_catalog())', t);
  END LOOP;
END $$;

DO $$
DECLARE f record;
BEGIN
  FOR f IN SELECT p.oid::regprocedure AS sig FROM pg_proc p
           WHERE p.pronamespace = 'public'::regnamespace AND p.prorettype = 'trigger'::regtype
  LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated', f.sig);
  END LOOP;
END $$;
