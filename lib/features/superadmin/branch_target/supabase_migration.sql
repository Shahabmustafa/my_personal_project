-- =============================================================================
-- BRANCH TARGET feature (superadmin/admin → "Branch Target" screen +
-- "Branch Target" report)
--
-- Per-branch monthly sale target (Rs.), set by superadmin/admin. The
-- Branch Target report divides this by 30 to get a daily target and
-- compares it against each branch's net sale for the current day.
-- 0 = no target set for that branch.
-- =============================================================================

ALTER TABLE public.branches
  ADD COLUMN IF NOT EXISTS monthly_target NUMERIC(14, 2) NOT NULL DEFAULT 0;

NOTIFY pgrst, 'reload schema';
