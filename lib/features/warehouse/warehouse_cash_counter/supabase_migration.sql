-- ============================================================
-- Warehouse Cash Counter Table Migration
-- ============================================================

CREATE TABLE IF NOT EXISTS public.warehouse_cash_counter (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  warehouse_id          UUID NOT NULL REFERENCES public.warehouses(id) ON DELETE CASCADE,
  counter_date          DATE NOT NULL,
  net_amount            NUMERIC(14, 2) NOT NULL DEFAULT 0,
  total_purchase        NUMERIC(14, 2) NOT NULL DEFAULT 0,
  total_return_purchase NUMERIC(14, 2) NOT NULL DEFAULT 0,
  expense               NUMERIC(14, 2) NOT NULL DEFAULT 0,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- One record per warehouse per date
CREATE UNIQUE INDEX IF NOT EXISTS warehouse_cash_counter_warehouse_date_unique
  ON public.warehouse_cash_counter (warehouse_id, counter_date);

-- Fast lookup by warehouse
CREATE INDEX IF NOT EXISTS warehouse_cash_counter_warehouse_id_idx
  ON public.warehouse_cash_counter (warehouse_id);

-- Auto-update updated_at trigger (moddatetime extension alternative)
DROP TRIGGER IF EXISTS set_updated_at_warehouse_cash_counter ON public.warehouse_cash_counter;
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at_warehouse_cash_counter
  BEFORE UPDATE ON public.warehouse_cash_counter
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Permissions (no RLS, direct grant — consistent with project)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.warehouse_cash_counter TO authenticated;
ALTER TABLE public.warehouse_cash_counter DISABLE ROW LEVEL SECURITY;

-- Notify PostgREST to reload schema
NOTIFY pgrst, 'reload schema';
