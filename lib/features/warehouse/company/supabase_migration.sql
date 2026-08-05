-- ============================================================
-- Companies Table Migration
-- ============================================================

CREATE TABLE IF NOT EXISTS public.companies (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  warehouse_id     UUID NOT NULL REFERENCES public.warehouses(id) ON DELETE CASCADE,
  name             TEXT NOT NULL,
  phone_number     TEXT NOT NULL DEFAULT '',
  email            TEXT NOT NULL DEFAULT '',
  address          TEXT NOT NULL DEFAULT '',
  opening_balance  NUMERIC(12, 2) NOT NULL DEFAULT 0,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Unique constraint: same name cannot exist twice in same warehouse (case-insensitive)
CREATE UNIQUE INDEX IF NOT EXISTS companies_warehouse_name_unique
  ON public.companies (warehouse_id, lower(name));

-- Index for fast warehouse lookups
CREATE INDEX IF NOT EXISTS companies_warehouse_id_idx
  ON public.companies (warehouse_id);

-- Grant permissions (consistent with project: no RLS, direct grant)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.companies TO authenticated;
