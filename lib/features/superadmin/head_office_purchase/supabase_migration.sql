-- ============================================================
-- HEAD OFFICE PURCHASE INVOICE + RETURN + CASH COUNTER
-- warehouse waale system ka mirror, bina warehouse_id ke.
-- Stock: public.stock_inventory
-- ============================================================

-- 1. Head office cash counter (daily, single)
CREATE TABLE IF NOT EXISTS public.head_office_cash_counter (
  id                     UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  counter_date           DATE          NOT NULL DEFAULT CURRENT_DATE UNIQUE,
  net_amount             NUMERIC(14,2) NOT NULL DEFAULT 0,
  total_purchase         NUMERIC(14,2) NOT NULL DEFAULT 0,
  total_return_purchase  NUMERIC(14,2) NOT NULL DEFAULT 0,
  expense                NUMERIC(14,2) NOT NULL DEFAULT 0,
  created_at             TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at             TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS head_office_cash_counter_updated_at ON public.head_office_cash_counter;
CREATE TRIGGER head_office_cash_counter_updated_at
  BEFORE UPDATE ON public.head_office_cash_counter
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

GRANT ALL ON public.head_office_cash_counter TO authenticated;
GRANT ALL ON public.head_office_cash_counter TO anon;
ALTER TABLE public.head_office_cash_counter DISABLE ROW LEVEL SECURITY;

-- 2. get_or_create today's counter
CREATE OR REPLACE FUNCTION get_or_create_ho_counter()
RETURNS public.head_office_cash_counter AS $$
DECLARE
  v_row      public.head_office_cash_counter;
  v_prev_net NUMERIC(14,2) := 0;
BEGIN
  SELECT * INTO v_row FROM public.head_office_cash_counter WHERE counter_date = CURRENT_DATE;
  IF FOUND THEN
    RETURN v_row;
  END IF;

  SELECT net_amount INTO v_prev_net
  FROM public.head_office_cash_counter
  WHERE counter_date < CURRENT_DATE
  ORDER BY counter_date DESC
  LIMIT 1;

  INSERT INTO public.head_office_cash_counter
    (counter_date, net_amount, total_purchase, total_return_purchase, expense)
  VALUES
    (CURRENT_DATE, COALESCE(v_prev_net, 0), 0, 0, 0)
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION get_or_create_ho_counter() TO authenticated;
GRANT EXECUTE ON FUNCTION get_or_create_ho_counter() TO anon;

-- 3. Purchase invoices (head office)
CREATE TABLE IF NOT EXISTS public.ho_purchase_invoices (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number TEXT NOT NULL UNIQUE,
  company_id     UUID REFERENCES public.companies(id) ON DELETE SET NULL,
  invoice_date   DATE NOT NULL DEFAULT CURRENT_DATE,
  total_amount   NUMERIC(12,2) NOT NULL DEFAULT 0,
  total_discount NUMERIC(12,2) NOT NULL DEFAULT 0,
  net_amount     NUMERIC(12,2) NOT NULL DEFAULT 0,
  paid_amount    NUMERIC(12,2) NOT NULL DEFAULT 0,
  credit_amount  NUMERIC(12,2) NOT NULL DEFAULT 0,
  payment_mode   TEXT NOT NULL DEFAULT 'cash',
  notes          TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS ho_purchase_invoices_updated_at ON public.ho_purchase_invoices;
CREATE TRIGGER ho_purchase_invoices_updated_at
  BEFORE UPDATE ON public.ho_purchase_invoices
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

GRANT ALL ON public.ho_purchase_invoices TO authenticated;
GRANT ALL ON public.ho_purchase_invoices TO anon;
ALTER TABLE public.ho_purchase_invoices DISABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.ho_purchase_invoice_items (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_invoice_id UUID NOT NULL REFERENCES public.ho_purchase_invoices(id) ON DELETE CASCADE,
  stock_id            UUID NOT NULL REFERENCES public.stock_inventory(id) ON DELETE RESTRICT,
  barcode             TEXT NOT NULL,
  product_id          UUID NOT NULL REFERENCES public.products(id)    ON DELETE RESTRICT,
  size_id             UUID NOT NULL REFERENCES public.sizes(id)       ON DELETE RESTRICT,
  color_id            UUID NOT NULL REFERENCES public.colors(id)      ON DELETE RESTRICT,
  brand_id            UUID NOT NULL REFERENCES public.brands(id)      ON DELETE RESTRICT,
  category_id         UUID NOT NULL REFERENCES public.categories(id)  ON DELETE RESTRICT,
  type_id             UUID NOT NULL REFERENCES public.types(id)       ON DELETE RESTRICT,
  quantity            INTEGER NOT NULL CHECK (quantity > 0),
  sale_price          NUMERIC(10,2) NOT NULL DEFAULT 0,
  purchase_price      NUMERIC(10,2) NOT NULL DEFAULT 0,
  discount_pct        NUMERIC(5,2)  NOT NULL DEFAULT 0,
  discount_amount     NUMERIC(10,2) NOT NULL DEFAULT 0,
  net_price           NUMERIC(10,2) NOT NULL DEFAULT 0,
  line_total          NUMERIC(12,2) NOT NULL DEFAULT 0,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

GRANT ALL ON public.ho_purchase_invoice_items TO authenticated;
GRANT ALL ON public.ho_purchase_invoice_items TO anon;
ALTER TABLE public.ho_purchase_invoice_items DISABLE ROW LEVEL SECURITY;

-- 4. Purchase returns (head office)
CREATE TABLE IF NOT EXISTS public.ho_purchase_returns (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  return_number       TEXT NOT NULL UNIQUE,
  original_invoice_id UUID REFERENCES public.ho_purchase_invoices(id) ON DELETE SET NULL,
  company_id          UUID REFERENCES public.companies(id) ON DELETE SET NULL,
  return_date         DATE NOT NULL DEFAULT CURRENT_DATE,
  total_amount        NUMERIC(12,2) NOT NULL DEFAULT 0,
  total_discount      NUMERIC(12,2) NOT NULL DEFAULT 0,
  net_amount          NUMERIC(12,2) NOT NULL DEFAULT 0,
  notes               TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS ho_purchase_returns_updated_at ON public.ho_purchase_returns;
CREATE TRIGGER ho_purchase_returns_updated_at
  BEFORE UPDATE ON public.ho_purchase_returns
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

GRANT ALL ON public.ho_purchase_returns TO authenticated;
GRANT ALL ON public.ho_purchase_returns TO anon;
ALTER TABLE public.ho_purchase_returns DISABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.ho_purchase_return_items (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_return_id UUID NOT NULL REFERENCES public.ho_purchase_returns(id) ON DELETE CASCADE,
  stock_id           UUID NOT NULL REFERENCES public.stock_inventory(id) ON DELETE RESTRICT,
  barcode            TEXT NOT NULL,
  product_id         UUID NOT NULL REFERENCES public.products(id)    ON DELETE RESTRICT,
  size_id            UUID NOT NULL REFERENCES public.sizes(id)       ON DELETE RESTRICT,
  color_id           UUID NOT NULL REFERENCES public.colors(id)      ON DELETE RESTRICT,
  brand_id           UUID NOT NULL REFERENCES public.brands(id)      ON DELETE RESTRICT,
  category_id        UUID NOT NULL REFERENCES public.categories(id)  ON DELETE RESTRICT,
  type_id            UUID NOT NULL REFERENCES public.types(id)       ON DELETE RESTRICT,
  quantity           INTEGER NOT NULL CHECK (quantity > 0),
  sale_price         NUMERIC(10,2) NOT NULL DEFAULT 0,
  purchase_price     NUMERIC(10,2) NOT NULL DEFAULT 0,
  discount_pct       NUMERIC(5,2)  NOT NULL DEFAULT 0,
  discount_amount    NUMERIC(10,2) NOT NULL DEFAULT 0,
  net_price          NUMERIC(10,2) NOT NULL DEFAULT 0,
  line_total         NUMERIC(12,2) NOT NULL DEFAULT 0,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

GRANT ALL ON public.ho_purchase_return_items TO authenticated;
GRANT ALL ON public.ho_purchase_return_items TO anon;
ALTER TABLE public.ho_purchase_return_items DISABLE ROW LEVEL SECURITY;

NOTIFY pgrst, 'reload schema';
