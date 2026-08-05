-- ============================================================
-- warehouse_stock_inventory table
-- Each row = one unique SKU (product + size + color + type + category + brand + company)
-- per warehouse, with its own barcode and quantity
-- ============================================================

CREATE TABLE IF NOT EXISTS public.warehouse_stock_inventory (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  barcode         TEXT NOT NULL UNIQUE,
  warehouse_id    UUID NOT NULL REFERENCES public.warehouses(id)   ON DELETE CASCADE,
  product_id      UUID NOT NULL REFERENCES public.products(id)     ON DELETE CASCADE,
  size_id         UUID NOT NULL REFERENCES public.sizes(id)        ON DELETE RESTRICT,
  brand_id        UUID NOT NULL REFERENCES public.brands(id)       ON DELETE RESTRICT,
  company_id      UUID          REFERENCES public.companies(id)    ON DELETE SET NULL,
  color_id        UUID NOT NULL REFERENCES public.colors(id)       ON DELETE RESTRICT,
  category_id     UUID NOT NULL REFERENCES public.categories(id)   ON DELETE RESTRICT,
  type_id         UUID NOT NULL REFERENCES public.types(id)        ON DELETE RESTRICT,
  quantity        INTEGER NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Unique constraint: no duplicate SKU per warehouse
ALTER TABLE public.warehouse_stock_inventory
  ADD CONSTRAINT warehouse_stock_unique_sku
  UNIQUE (warehouse_id, product_id, size_id, color_id, type_id, category_id, brand_id);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER warehouse_stock_inventory_updated_at
  BEFORE UPDATE ON public.warehouse_stock_inventory
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grant access (RLS disabled, direct grants like rest of the project)
GRANT ALL ON public.warehouse_stock_inventory TO authenticated;
GRANT ALL ON public.warehouse_stock_inventory TO anon;
