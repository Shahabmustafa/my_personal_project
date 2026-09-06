-- ============================================================
-- Companies Table Migration
-- ============================================================

CREATE TABLE IF NOT EXISTS public.companies (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  head_office_id   UUID NOT NULL REFERENCES public.head_offices(id) ON DELETE CASCADE,
  name             TEXT NOT NULL,
  phone_number     TEXT NOT NULL DEFAULT '',
  email            TEXT NOT NULL DEFAULT '',
  address          TEXT NOT NULL DEFAULT '',
  opening_balance  NUMERIC(12, 2) NOT NULL DEFAULT 0,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Unique constraint: same name cannot exist twice under the same head office (case-insensitive)
CREATE UNIQUE INDEX IF NOT EXISTS companies_head_office_name_unique
  ON public.companies (head_office_id, lower(name));

-- Index for fast head-office lookups
CREATE INDEX IF NOT EXISTS companies_head_office_id_idx
  ON public.companies (head_office_id);

-- Grant permissions (consistent with project: no RLS, direct grant)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.companies TO authenticated;

-- ============================================================
-- Migration: warehouse_id -> head_office_id  (applied 2026-09-07)
-- Companies belong to the singleton head office, not a warehouse.
-- ============================================================
-- ALTER TABLE public.companies
--   ADD COLUMN head_office_id UUID REFERENCES public.head_offices(id) ON DELETE CASCADE;
-- UPDATE public.companies
--   SET head_office_id = (SELECT id FROM public.head_offices ORDER BY created_at LIMIT 1)
--   WHERE head_office_id IS NULL;
-- ALTER TABLE public.companies ALTER COLUMN head_office_id SET NOT NULL;
-- DROP INDEX IF EXISTS public.companies_warehouse_name_unique;
-- DROP INDEX IF EXISTS public.companies_warehouse_id_idx;
-- ALTER TABLE public.companies DROP COLUMN warehouse_id;
-- CREATE UNIQUE INDEX IF NOT EXISTS companies_head_office_name_unique
--   ON public.companies (head_office_id, lower(name));
-- CREATE INDEX IF NOT EXISTS companies_head_office_id_idx
--   ON public.companies (head_office_id);
