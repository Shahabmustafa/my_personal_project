-- =============================================================================
-- BRANCH TARGET feature (superadmin/admin → "Branch Target" screen +
-- "Branch Target" report)
--
-- Har branch ke liye din-wise sale target (Rs.). Admin aaj se end date tak
-- ek total amount deta hai jo barabar divide hota hai, phir kisi bhi din
-- (jaise Sat/Sun) ka target alag se badha sakta hai. Ek row = ek din.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.branch_daily_targets (
  branch_id   UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  target_date DATE NOT NULL,
  amount      NUMERIC(14, 2) NOT NULL DEFAULT 0 CHECK (amount >= 0),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (branch_id, target_date)
);

ALTER TABLE public.branch_daily_targets ENABLE ROW LEVEL SECURITY;

CREATE POLICY authenticated_full_access ON public.branch_daily_targets
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

NOTIFY pgrst, 'reload schema';
