-- H1 Stage 1: privilege escalation band karo.
-- Pehle har authenticated user (cashier bhi) users.role badal kar khud ko
-- superadmin bana sakta tha, branches/discounts/user-assignments edit kar sakta tha.
-- Ab: in tables par WRITE sirf superadmin; READ sab authenticated ko (app ki
-- lists/realtime pehle jaisi). Operational tables (stock, sales, cash counter,
-- salary jin ko SECURITY INVOKER triggers cashier ke naam se likhte hain)
-- abhi nahi chhede — Stage 2 mein branch-wise scoping.

CREATE OR REPLACE FUNCTION public.app_role() RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp AS $$
  SELECT role FROM public.users WHERE id = auth.uid() AND is_active IS NOT FALSE
$$;

CREATE OR REPLACE FUNCTION public.is_superadmin() RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp AS $$
  SELECT COALESCE(public.app_role() = 'superadmin', false)
$$;

REVOKE ALL ON FUNCTION public.app_role(), public.is_superadmin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.app_role(), public.is_superadmin() TO authenticated, service_role;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'branches','head_offices','warehouses','sale_discount_tiers','b1g1_offers',
    'branch_daily_targets','bank_heads','printer_heads','assign_printer',
    'employee_salary_history','users','user_branches','user_warehouses',
    'user_head_offices'
  ] LOOP
    EXECUTE format('DROP POLICY IF EXISTS authenticated_full_access ON public.%I', t);
    EXECUTE format('DROP POLICY IF EXISTS read_all ON public.%I', t);
    EXECUTE format('DROP POLICY IF EXISTS superadmin_write ON public.%I', t);
    EXECUTE format('CREATE POLICY read_all ON public.%I FOR SELECT TO authenticated USING (true)', t);
    EXECUTE format('CREATE POLICY superadmin_write ON public.%I FOR ALL TO authenticated USING (public.is_superadmin()) WITH CHECK (public.is_superadmin())', t);
  END LOOP;
END $$;

-- createUser() auth.signUp ke baad naye user ke session se hi rows insert karta
-- hai; is liye "pehli dafa, sirf apni" insert allow hai (superadmin role nahi).
DROP POLICY IF EXISTS self_initial_insert ON public.users;
CREATE POLICY self_initial_insert ON public.users FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid() AND role <> 'superadmin');

DROP POLICY IF EXISTS self_initial_insert ON public.user_branches;
CREATE POLICY self_initial_insert ON public.user_branches FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid() AND NOT EXISTS (
    SELECT 1 FROM public.user_branches x WHERE x.user_id = auth.uid()));

DROP POLICY IF EXISTS self_initial_insert ON public.user_warehouses;
CREATE POLICY self_initial_insert ON public.user_warehouses FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid() AND NOT EXISTS (
    SELECT 1 FROM public.user_warehouses x WHERE x.user_id = auth.uid()));

DROP POLICY IF EXISTS self_initial_insert ON public.user_head_offices;
CREATE POLICY self_initial_insert ON public.user_head_offices FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid() AND NOT EXISTS (
    SELECT 1 FROM public.user_head_offices x WHERE x.user_id = auth.uid()));

DO $t$
DECLARE
  cashier uuid := '431ef597-2c92-40ec-9547-71b244157955';
  sup uuid := 'e5f41f6d-98cd-4810-8ff6-4b5285060a98';
  out text := '';
  n int; st record; b uuid; res jsonb;
BEGIN
  -- ===== cashier =====
  EXECUTE 'set local role authenticated';
  PERFORM set_config('request.jwt.claims', json_build_object('sub',cashier,'role','authenticated')::text, true);
  out := out || 'cashier app_role=' || coalesce(public.app_role(),'NULL') || E'\n';

  UPDATE public.users SET role='superadmin' WHERE id=cashier;
  GET DIAGNOSTICS n = ROW_COUNT; out := out || 'cashier self-promote rows=' || n || E' (want 0)\n';

  BEGIN INSERT INTO public.branches (branch_name) VALUES ('hack'); out := out || 'cashier insert branch: ALLOWED (BAD)' || E'\n';
  EXCEPTION WHEN OTHERS THEN out := out || 'cashier insert branch blocked: ' || SQLERRM || E'\n'; END;

  UPDATE public.sale_discount_tiers SET discount_value = discount_value;
  GET DIAGNOSTICS n = ROW_COUNT; out := out || 'cashier update tiers rows=' || n || E' (want 0)\n';

  BEGIN INSERT INTO public.user_branches (user_id, branch_id) SELECT cashier, id FROM public.branches LIMIT 1;
    out := out || 'cashier extra user_branches: ALLOWED (BAD)' || E'\n';
  EXCEPTION WHEN OTHERS THEN out := out || 'cashier extra user_branches blocked: ' || SQLERRM || E'\n'; END;

  SELECT count(*) INTO n FROM public.users; out := out || 'cashier can read users=' || n || E'\n';
  SELECT count(*) INTO n FROM public.branches; out := out || 'cashier can read branches=' || n || E'\n';

  -- cashier sale (triggers: stock, cash counter, salary, bank)
  SELECT branch_id INTO b FROM public.user_branches WHERE user_id=cashier LIMIT 1;
  SELECT * INTO st FROM public.branch_stock_inventory WHERE branch_id=b AND quantity>2 LIMIT 1;
  IF FOUND THEN
    BEGIN
      res := public.save_sale_invoice(
        jsonb_build_object('invoice_number','TEST-RLS-ROLLBACK','branch_id',b,'cashier_id',cashier,'subtotal',100,'total_discount',0,'invoice_discount',0,'total_amount',100,'salesman_commission_percent',0,'salesman_commission_amount',0,'manager_commission_percent',0,'manager_commission_amount',0),
        jsonb_build_array(jsonb_build_object('branch_id',b,'branch_stock_id',st.id,'product_id',st.product_id,'quantity',2,'sale_price',50,'purchase_price',20,'discount_pct',0,'discount',0,'total_price',100)),
        jsonb_build_array(jsonb_build_object('branch_id',b,'payment_type','cash','amount',100)));
      out := out || 'cashier sale OK id=' || (res->>'id') || E'\n';
    EXCEPTION WHEN OTHERS THEN out := out || 'cashier sale FAILED: ' || SQLERRM || E'\n'; END;
  ELSE out := out || 'no stock row for cashier branch' || E'\n'; END IF;

  -- ===== superadmin =====
  EXECUTE 'reset role'; EXECUTE 'set local role authenticated';
  PERFORM set_config('request.jwt.claims', json_build_object('sub',sup,'role','authenticated')::text, true);
  out := out || 'superadmin app_role=' || coalesce(public.app_role(),'NULL') || E'\n';
  UPDATE public.branches SET branch_name = branch_name;
  GET DIAGNOSTICS n = ROW_COUNT; out := out || 'superadmin update branches rows=' || n || E' (want >0)\n';
  UPDATE public.users SET role = role WHERE id = cashier;
  GET DIAGNOSTICS n = ROW_COUNT; out := out || 'superadmin update users rows=' || n || E' (want 1)\n';

  EXECUTE 'reset role';
  RAISE EXCEPTION E'ROLLBACK_REPORT\n%', out;
END $t$;
