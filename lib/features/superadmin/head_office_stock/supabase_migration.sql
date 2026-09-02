-- ============================================================
-- stock_inventory  (Head office stock)
-- warehouse_stock_inventory jaisa hi, bas warehouse_id ke baghair.
-- Superadmin dashboard ka "Stock Inventory" screen isi table par chalta hai.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.stock_inventory (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  barcode      TEXT NOT NULL UNIQUE,
  product_id   UUID NOT NULL REFERENCES public.products(id)   ON DELETE CASCADE,
  size_id      UUID NOT NULL REFERENCES public.sizes(id)      ON DELETE RESTRICT,
  brand_id     UUID NOT NULL REFERENCES public.brands(id)     ON DELETE RESTRICT,
  company_id   UUID          REFERENCES public.companies(id)  ON DELETE SET NULL,
  color_id     UUID NOT NULL REFERENCES public.colors(id)     ON DELETE RESTRICT,
  category_id  UUID NOT NULL REFERENCES public.categories(id) ON DELETE RESTRICT,
  type_id      UUID NOT NULL REFERENCES public.types(id)      ON DELETE RESTRICT,
  quantity     INTEGER NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  discount     NUMERIC(12,2) NOT NULL DEFAULT 0,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- No duplicate SKU (poori table mein — warehouse dimension nahi hai)
ALTER TABLE public.stock_inventory
  DROP CONSTRAINT IF EXISTS stock_inventory_unique_sku;
ALTER TABLE public.stock_inventory
  ADD CONSTRAINT stock_inventory_unique_sku
  UNIQUE (product_id, size_id, color_id, type_id, category_id, brand_id);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS stock_inventory_updated_at ON public.stock_inventory;
CREATE TRIGGER stock_inventory_updated_at
  BEFORE UPDATE ON public.stock_inventory
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

GRANT ALL ON public.stock_inventory TO authenticated;
GRANT ALL ON public.stock_inventory TO anon;
ALTER TABLE public.stock_inventory DISABLE ROW LEVEL SECURITY;

NOTIFY pgrst, 'reload schema';
