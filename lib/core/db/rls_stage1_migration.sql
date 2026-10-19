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
