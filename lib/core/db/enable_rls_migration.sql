-- ============================================================
-- Row Level Security (RLS) — poore project par
-- ============================================================
-- Masla: 52 public tables par RLS disabled tha, yani jis ke paas bhi
-- anon key hai (public) wo har row parh/likh sakta tha.
--
-- Fix: har table par RLS enable + ek blanket policy jo sirf logged-in
-- (`authenticated`) users ko full access deti hai. `anon` (bina login)
-- ab kuch access nahi kar sakta.
--
-- App Supabase Auth use karti hai (auth.signInWithPassword). Login ke baad
-- saare Supabase requests `authenticated` role se jaate hain — is liye
-- poora project pehle ki tarah kaam karta rehta hai.
--
-- Aage chal kar agar fine-grained rules chahiye (e.g. cashier sirf apni
-- branch ka data dekhe), to per-table policy `USING (...)` expression
-- update karni hogi. Abhi ke liye blanket authenticated access hai.
-- ============================================================

DO $$
DECLARE
  t record;
BEGIN
  FOR t IN
    SELECT tablename FROM pg_tables WHERE schemaname = 'public'
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t.tablename);
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I',
                   'authenticated_full_access', t.tablename);
    EXECUTE format(
      'CREATE POLICY %I ON public.%I FOR ALL TO authenticated '
      'USING (true) WITH CHECK (true)',
      'authenticated_full_access', t.tablename
    );
  END LOOP;
END $$;

NOTIFY pgrst, 'reload schema';
