-- Security hardening (M4, M5, M6, L4) — Supabase SQL editor mein chalayein.
-- App sirf `authenticated` role se RPC/tables use karti hai (customer website
-- Supabase use nahi karti), is liye anon ka access hatana safe hai.

-- M6: views caller ke RLS ke hisaab se chalein (security definer nahi)
ALTER VIEW public.v_branch_stock SET (security_invoker = true);
ALTER VIEW public.v_warehouse_stock SET (security_invoker = true);
ALTER VIEW public.v_head_office_stock SET (security_invoker = true);

-- M5: employee_salary_history par RLS
ALTER TABLE public.employee_salary_history ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS authenticated_full_access ON public.employee_salary_history;
CREATE POLICY authenticated_full_access ON public.employee_salary_history
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- M4 + L4: public functions — anon/PUBLIC se EXECUTE hatao, search_path fix
-- (extension ke functions, jaise pg_trgm, chhor diye jate hain)
DO $$
DECLARE f record;
BEGIN
  FOR f IN
    SELECT p.oid::regprocedure AS sig
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prokind = 'f'
      AND NOT EXISTS (SELECT 1 FROM pg_depend d
                      WHERE d.objid = p.oid AND d.deptype = 'e')
  LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon', f.sig);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated, service_role', f.sig);
    EXECUTE format('ALTER FUNCTION %s SET search_path = public, pg_temp', f.sig);
  END LOOP;
END $$;
