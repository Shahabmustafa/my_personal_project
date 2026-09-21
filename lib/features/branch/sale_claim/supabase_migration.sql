-- =============================================
-- Sale Claim
--
-- Customer ne shoe khareedi, kuch din baad kharab nikla (return/exchange
-- ho chuka). Branch us product ka "claim" banata hai Head Office ke naam.
-- Claim 'pending' rehta hai; Head Office approve kare to branch stock se
-- claim ki quantity minus ho jati hai (approve_sale_claim), reject kare to
-- stock ko kuch nahi hota.
-- =============================================

-- =============================================
-- STEP 1: sale_claims table
--   1 claim = 1 invoice line (1 product) + quantity
-- =============================================
CREATE TABLE IF NOT EXISTS public.sale_claims (
    id                   UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    claim_number         TEXT            NOT NULL UNIQUE,
    branch_id            UUID            NOT NULL REFERENCES public.branches(id) ON DELETE RESTRICT,
    head_office_id       UUID            NOT NULL REFERENCES public.head_offices(id) ON DELETE RESTRICT,
    sale_invoice_id      UUID            NOT NULL REFERENCES public.sale_invoices(id) ON DELETE RESTRICT,
    sale_invoice_item_id UUID            NOT NULL REFERENCES public.sale_invoice_items(id) ON DELETE RESTRICT,
    customer_id          UUID            REFERENCES public.customers(id) ON DELETE SET NULL,
    branch_stock_id      UUID            NOT NULL REFERENCES public.branch_stock_inventory(id) ON DELETE RESTRICT,
    product_id           UUID            NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
    size_id              UUID            REFERENCES public.sizes(id) ON DELETE RESTRICT,
    color_id             UUID            REFERENCES public.colors(id) ON DELETE RESTRICT,
    brand_id             UUID            REFERENCES public.brands(id) ON DELETE RESTRICT,
    category_id          UUID            REFERENCES public.categories(id) ON DELETE RESTRICT,
    type_id              UUID            REFERENCES public.types(id) ON DELETE RESTRICT,
    barcode              TEXT,
    quantity             INTEGER         NOT NULL CHECK (quantity > 0),
    sale_price           NUMERIC(15,2)   NOT NULL DEFAULT 0,
    purchase_price       NUMERIC(15,2)   NOT NULL DEFAULT 0,
    total_price          NUMERIC(15,2)   NOT NULL DEFAULT 0,
    reason               TEXT            NOT NULL,
    sale_date            TIMESTAMPTZ     NOT NULL,
    claim_date           TIMESTAMPTZ     NOT NULL DEFAULT now(),
    status               TEXT            NOT NULL DEFAULT 'pending'
                                         CHECK (status IN ('pending', 'approved', 'rejected')),
    claimed_by           UUID            REFERENCES public.users(id) ON DELETE SET NULL,
    reviewed_by          UUID            REFERENCES public.users(id) ON DELETE SET NULL,
    reviewed_at          TIMESTAMPTZ,
    review_remarks       TEXT,
    created_at           TIMESTAMPTZ     DEFAULT now(),
    updated_at           TIMESTAMPTZ     DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sale_claims_branch ON public.sale_claims (branch_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sale_claims_head_office ON public.sale_claims (head_office_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sale_claims_invoice_item ON public.sale_claims (sale_invoice_item_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.sale_claims TO authenticated;

-- Baqi tables ki tarah (enable_rls_migration.sql): RLS on + authenticated ko full access.
ALTER TABLE public.sale_claims ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS authenticated_full_access ON public.sale_claims;
CREATE POLICY authenticated_full_access ON public.sale_claims
    FOR ALL TO authenticated USING (true) WITH CHECK (true);


-- =============================================
-- STEP 2: updated_at auto-touch trigger
-- =============================================
CREATE OR REPLACE FUNCTION update_sale_claims_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sale_claims_updated_at ON public.sale_claims;
CREATE TRIGGER trg_sale_claims_updated_at
BEFORE UPDATE ON public.sale_claims
FOR EACH ROW EXECUTE FUNCTION update_sale_claims_updated_at();


-- =============================================
-- STEP 3: claim number — CLM-000001
-- =============================================
CREATE OR REPLACE FUNCTION public.generate_sale_claim_number()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    last_num INTEGER;
BEGIN
    SELECT COALESCE(
        MAX(CAST(SUBSTRING(claim_number FROM 5) AS INTEGER)), 0
    ) INTO last_num
    FROM public.sale_claims
    WHERE claim_number LIKE 'CLM-%';

    RETURN 'CLM-' || LPAD((last_num + 1)::TEXT, 6, '0');
END;
$$;


-- =============================================
-- STEP 4: insert validation
--   * claim usi branch ki invoice line par ho
--   * ek invoice line par total (pending + approved) claims, bechi hui
--     quantity se zyada na hon (rejected claims count nahi hote)
-- =============================================
CREATE OR REPLACE FUNCTION public.validate_sale_claim()
RETURNS TRIGGER AS $$
DECLARE
    v_sold     INTEGER;
    v_branch   UUID;
    v_claimed  INTEGER;
BEGIN
    SELECT i.quantity, i.branch_id
    INTO v_sold, v_branch
    FROM public.sale_invoice_items i
    WHERE i.id = NEW.sale_invoice_item_id
      AND i.sale_invoice_id = NEW.sale_invoice_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invoice item not found on this invoice';
    END IF;

    IF v_branch <> NEW.branch_id THEN
        RAISE EXCEPTION 'Invoice item does not belong to this branch';
    END IF;

    SELECT COALESCE(SUM(quantity), 0) INTO v_claimed
    FROM public.sale_claims
    WHERE sale_invoice_item_id = NEW.sale_invoice_item_id
      AND status IN ('pending', 'approved');

    IF v_claimed + NEW.quantity > v_sold THEN
        RAISE EXCEPTION 'Claim quantity exceeds sold quantity (sold %, already claimed %)',
            v_sold, v_claimed;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validate_sale_claim ON public.sale_claims;
CREATE TRIGGER trg_validate_sale_claim
BEFORE INSERT ON public.sale_claims
FOR EACH ROW EXECUTE FUNCTION public.validate_sale_claim();


-- =============================================
-- STEP 5: approve — branch stock se quantity minus
--   Row lock ke sath check hota hai; stock kam ho to poora approve fail
--   (claim pending hi rehta hai).
-- =============================================
CREATE OR REPLACE FUNCTION public.approve_sale_claim(
    p_claim_id    UUID,
    p_reviewed_by UUID DEFAULT NULL,
    p_remarks     TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_claim  public.sale_claims%ROWTYPE;
    v_stock  INTEGER;
BEGIN
    SELECT * INTO v_claim
    FROM public.sale_claims
    WHERE id = p_claim_id AND status = 'pending'
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Claim not found or not pending: %', p_claim_id;
    END IF;

    SELECT quantity INTO v_stock
    FROM public.branch_stock_inventory
    WHERE id = v_claim.branch_stock_id AND branch_id = v_claim.branch_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Branch stock row not found for this claim';
    END IF;

    IF v_stock < v_claim.quantity THEN
        RAISE EXCEPTION 'Branch stock is insufficient (available %, claim %)',
            v_stock, v_claim.quantity;
    END IF;

    UPDATE public.branch_stock_inventory
    SET quantity = quantity - v_claim.quantity, updated_at = now()
    WHERE id = v_claim.branch_stock_id;

    UPDATE public.sale_claims
    SET status = 'approved',
        reviewed_by = p_reviewed_by,
        reviewed_at = now(),
        review_remarks = p_remarks
    WHERE id = p_claim_id;
END;
$$;


-- =============================================
-- STEP 6: reject — stock ko kuch nahi hota
-- =============================================
CREATE OR REPLACE FUNCTION public.reject_sale_claim(
    p_claim_id    UUID,
    p_reviewed_by UUID DEFAULT NULL,
    p_remarks     TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
    UPDATE public.sale_claims
    SET status = 'rejected',
        reviewed_by = p_reviewed_by,
        reviewed_at = now(),
        review_remarks = p_remarks
    WHERE id = p_claim_id AND status = 'pending';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Claim not found or not pending: %', p_claim_id;
    END IF;
END;
$$;
