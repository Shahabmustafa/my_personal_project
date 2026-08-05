-- ============================================================
-- 1. Add discount column to warehouse_stock_inventory
--    (sale_price and purchase_price come from products table)
-- ============================================================
ALTER TABLE public.warehouse_stock_inventory
  ADD COLUMN IF NOT EXISTS discount_pct NUMERIC(5,2) NOT NULL DEFAULT 0
    CHECK (discount_pct >= 0 AND discount_pct <= 100);

-- ============================================================
-- 2. Add sale_price and purchase_price to products (if missing)
-- ============================================================
ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS sale_price     NUMERIC(10,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS purchase_price NUMERIC(10,2) NOT NULL DEFAULT 0;

-- ============================================================
-- 3. Purchase Invoices (header)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.purchase_invoices (
  id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number  TEXT          NOT NULL UNIQUE,
  company_id      UUID          REFERENCES public.companies(id) ON DELETE SET NULL,
  warehouse_id    UUID          NOT NULL REFERENCES public.warehouses(id) ON DELETE CASCADE,
  invoice_date    DATE          NOT NULL DEFAULT CURRENT_DATE,
  total_amount    NUMERIC(12,2) NOT NULL DEFAULT 0,
  total_discount  NUMERIC(12,2) NOT NULL DEFAULT 0,
  net_amount      NUMERIC(12,2) NOT NULL DEFAULT 0,
  notes           TEXT,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TRIGGER purchase_invoices_updated_at
  BEFORE UPDATE ON public.purchase_invoices
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

GRANT ALL ON public.purchase_invoices TO authenticated;
GRANT ALL ON public.purchase_invoices TO anon;

-- ============================================================
-- 4. Purchase Invoice Items (line items)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.purchase_invoice_items (
  id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_invoice_id UUID          NOT NULL REFERENCES public.purchase_invoices(id) ON DELETE CASCADE,
  stock_id            UUID          NOT NULL REFERENCES public.warehouse_stock_inventory(id) ON DELETE RESTRICT,
  barcode             TEXT          NOT NULL,
  product_id          UUID          NOT NULL REFERENCES public.products(id)    ON DELETE RESTRICT,
  size_id             UUID          NOT NULL REFERENCES public.sizes(id)       ON DELETE RESTRICT,
  color_id            UUID          NOT NULL REFERENCES public.colors(id)      ON DELETE RESTRICT,
  brand_id            UUID          NOT NULL REFERENCES public.brands(id)      ON DELETE RESTRICT,
  category_id         UUID          NOT NULL REFERENCES public.categories(id)  ON DELETE RESTRICT,
  type_id             UUID          NOT NULL REFERENCES public.types(id)       ON DELETE RESTRICT,
  quantity            INTEGER       NOT NULL CHECK (quantity > 0),
  sale_price          NUMERIC(10,2) NOT NULL DEFAULT 0,
  purchase_price      NUMERIC(10,2) NOT NULL DEFAULT 0,
  discount_pct        NUMERIC(5,2)  NOT NULL DEFAULT 0,
  discount_amount     NUMERIC(10,2) NOT NULL DEFAULT 0,
  net_price           NUMERIC(10,2) NOT NULL DEFAULT 0,
  line_total          NUMERIC(12,2) NOT NULL DEFAULT 0,
  created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

GRANT ALL ON public.purchase_invoice_items TO authenticated;
GRANT ALL ON public.purchase_invoice_items TO anon;

-- ============================================================
-- 5. Auto-generate invoice number sequence
-- ============================================================
CREATE SEQUENCE IF NOT EXISTS purchase_invoice_seq START 10001 INCREMENT 1;

CREATE OR REPLACE FUNCTION generate_purchase_invoice_number()
RETURNS TEXT AS $$
BEGIN
  RETURN 'PI-' || LPAD(nextval('purchase_invoice_seq')::TEXT, 6, '0');
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION generate_purchase_invoice_number() TO authenticated;
GRANT EXECUTE ON FUNCTION generate_purchase_invoice_number() TO anon;
