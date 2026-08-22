-- ============================================================
-- MIGRATION: Replace warehouse_cashinhand with warehouse_cash_counter
-- Run this in Supabase SQL Editor
-- ============================================================

-- ============================================================
-- 1. Create warehouse_cash_counter table
--    - har warehouse ka har din ek row
--    - net_amount = warehouse ka cash in hand (opening balance)
--    - total_purchase, total_return_purchase, expense → daily track
-- ============================================================
CREATE TABLE IF NOT EXISTS public.warehouse_cash_counter (
  id                      UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  warehouse_id            UUID          NOT NULL REFERENCES public.warehouses(id) ON DELETE CASCADE,
  counter_date            DATE          NOT NULL DEFAULT CURRENT_DATE,
  net_amount              NUMERIC(14,2) NOT NULL DEFAULT 0,   -- cash in hand (carries forward)
  total_purchase          NUMERIC(14,2) NOT NULL DEFAULT 0,   -- aaj ki purchases (0 se start)
  total_return_purchase   NUMERIC(14,2) NOT NULL DEFAULT 0,   -- aaj ki purchase returns (0 se start)
  expense                 NUMERIC(14,2) NOT NULL DEFAULT 0,   -- aaj ka expense (0 se start)
  created_at              TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  UNIQUE(warehouse_id, counter_date)
);

CREATE TRIGGER warehouse_cash_counter_updated_at
  BEFORE UPDATE ON public.warehouse_cash_counter
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

GRANT ALL ON public.warehouse_cash_counter TO authenticated;
GRANT ALL ON public.warehouse_cash_counter TO anon;

-- ============================================================
-- 2. Migrate existing cashinhand data into counter (optional)
--    Agar pehle se warehouse_cashinhand table hai aur usme data hai
--    to aaj ki date ke liye ek row insert karo
-- ============================================================
INSERT INTO public.warehouse_cash_counter (warehouse_id, counter_date, net_amount)
SELECT warehouse_id, CURRENT_DATE, amount
FROM public.warehouse_cashinhand
ON CONFLICT (warehouse_id, counter_date) DO NOTHING;

-- ============================================================
-- 3. Function: get or create today's counter for a warehouse
--    Agar aaj ki row nahi hai to kal ki net_amount copy karo
-- ============================================================
CREATE OR REPLACE FUNCTION get_or_create_counter(p_warehouse_id UUID)
RETURNS public.warehouse_cash_counter AS $$
DECLARE
  v_row  public.warehouse_cash_counter;
  v_prev_net NUMERIC(14,2) := 0;
BEGIN
  -- Try to get today's row
  SELECT * INTO v_row
  FROM public.warehouse_cash_counter
  WHERE warehouse_id = p_warehouse_id AND counter_date = CURRENT_DATE;

  IF FOUND THEN
    RETURN v_row;
  END IF;

  -- Get last net_amount from most recent previous row
  SELECT net_amount INTO v_prev_net
  FROM public.warehouse_cash_counter
  WHERE warehouse_id = p_warehouse_id AND counter_date < CURRENT_DATE
  ORDER BY counter_date DESC
  LIMIT 1;

  -- Insert new row for today with previous net_amount, daily cols start at 0
  INSERT INTO public.warehouse_cash_counter
    (warehouse_id, counter_date, net_amount, total_purchase, total_return_purchase, expense)
  VALUES
    (p_warehouse_id, CURRENT_DATE, COALESCE(v_prev_net, 0), 0, 0, 0)
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION get_or_create_counter(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_or_create_counter(UUID) TO anon;

-- ============================================================
-- 4. Purchase Return table
-- ============================================================
CREATE TABLE IF NOT EXISTS public.purchase_returns (
  id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  return_number       TEXT          NOT NULL UNIQUE,
  original_invoice_id UUID          REFERENCES public.purchase_invoices(id) ON DELETE SET NULL,
  company_id          UUID          REFERENCES public.companies(id) ON DELETE SET NULL,
  warehouse_id        UUID          NOT NULL REFERENCES public.warehouses(id) ON DELETE CASCADE,
  return_date         DATE          NOT NULL DEFAULT CURRENT_DATE,
  total_amount        NUMERIC(12,2) NOT NULL DEFAULT 0,
  total_discount      NUMERIC(12,2) NOT NULL DEFAULT 0,
  net_amount          NUMERIC(12,2) NOT NULL DEFAULT 0,
  notes               TEXT,
  created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TRIGGER purchase_returns_updated_at
  BEFORE UPDATE ON public.purchase_returns
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

GRANT ALL ON public.purchase_returns TO authenticated;
GRANT ALL ON public.purchase_returns TO anon;

-- ============================================================
-- 5. Purchase Return Items table
-- ============================================================
CREATE TABLE IF NOT EXISTS public.purchase_return_items (
  id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_return_id  UUID          NOT NULL REFERENCES public.purchase_returns(id) ON DELETE CASCADE,
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

GRANT ALL ON public.purchase_return_items TO authenticated;
GRANT ALL ON public.purchase_return_items TO anon;

-- ============================================================
-- 6. Auto-generate return number sequence
-- ============================================================
CREATE SEQUENCE IF NOT EXISTS purchase_return_seq START 10001 INCREMENT 1;

CREATE OR REPLACE FUNCTION generate_purchase_return_number()
RETURNS TEXT AS $$
BEGIN
  RETURN 'PR-' || LPAD(nextval('purchase_return_seq')::TEXT, 6, '0');
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION generate_purchase_return_number() TO authenticated;
GRANT EXECUTE ON FUNCTION generate_purchase_return_number() TO anon;

-- ============================================================
-- 7. Add paid_amount, credit_amount, payment_mode to purchase_invoices
--    (if not already added by previous migration)
-- ============================================================
ALTER TABLE public.purchase_invoices
  ADD COLUMN IF NOT EXISTS paid_amount   NUMERIC(12,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS credit_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS payment_mode  TEXT          NOT NULL DEFAULT 'cash';
