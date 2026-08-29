-- Pehle drop karo
DROP TABLE IF EXISTS public.sale_return_items;
DROP TABLE IF EXISTS public.sale_return_payments;
DROP TABLE IF EXISTS public.sale_returns;

-- =============================================
-- STEP 1: sale_returns table
-- =============================================
CREATE TABLE public.sale_returns (
    id                  UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    return_number       TEXT            NOT NULL UNIQUE,
    branch_id           UUID            NOT NULL REFERENCES public.branches(id) ON DELETE RESTRICT,
    original_invoice_id UUID            REFERENCES public.sale_invoices(id) ON DELETE SET NULL,
    printer_id          UUID            REFERENCES public.assign_printer(id) ON DELETE RESTRICT,
    cashier_id          UUID            REFERENCES public.users(id) ON DELETE RESTRICT,
    salesman_id         UUID            REFERENCES public.employee_salary(id) ON DELETE RESTRICT,
    customer_id         UUID            REFERENCES public.customers(id) ON DELETE RESTRICT,
    subtotal            NUMERIC(15,2)   NOT NULL DEFAULT 0,
    total_discount       NUMERIC(15,2)   NOT NULL DEFAULT 0,
    total_amount        NUMERIC(15,2)   NOT NULL DEFAULT 0,
    note                TEXT,
    created_at          TIMESTAMPTZ     DEFAULT now(),
    updated_at          TIMESTAMPTZ     DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.sale_returns TO authenticated;
ALTER TABLE public.sale_returns DISABLE ROW LEVEL SECURITY;


-- =============================================
-- STEP 2: sale_return_payments table
-- =============================================
CREATE TABLE public.sale_return_payments (
    id                  UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    sale_return_id      UUID            NOT NULL REFERENCES public.sale_returns(id) ON DELETE CASCADE,
    branch_id           UUID            NOT NULL REFERENCES public.branches(id) ON DELETE RESTRICT,
    bank_entry_id       UUID            REFERENCES public.bank_entries(id) ON DELETE RESTRICT,
    payment_type        TEXT            NOT NULL CHECK (payment_type IN ('cash', 'card')),
    amount              NUMERIC(15,2)   NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ     DEFAULT now(),
    updated_at          TIMESTAMPTZ     DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.sale_return_payments TO authenticated;
ALTER TABLE public.sale_return_payments DISABLE ROW LEVEL SECURITY;


-- =============================================
-- STEP 3: sale_return_items table
-- =============================================
CREATE TABLE public.sale_return_items (
    id                  UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    sale_return_id      UUID            NOT NULL REFERENCES public.sale_returns(id) ON DELETE CASCADE,
    branch_id           UUID            NOT NULL REFERENCES public.branches(id) ON DELETE RESTRICT,
    branch_stock_id     UUID            NOT NULL REFERENCES public.branch_stock_inventory(id) ON DELETE RESTRICT,
    product_id          UUID            NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
    size_id             UUID            REFERENCES public.sizes(id) ON DELETE RESTRICT,
    color_id            UUID            REFERENCES public.colors(id) ON DELETE RESTRICT,
    brand_id            UUID            REFERENCES public.brands(id) ON DELETE RESTRICT,
    category_id         UUID            REFERENCES public.categories(id) ON DELETE RESTRICT,
    type_id             UUID            REFERENCES public.types(id) ON DELETE RESTRICT,
    barcode             TEXT,
    quantity            INTEGER         NOT NULL DEFAULT 1,
    sale_price          NUMERIC(15,2)   NOT NULL DEFAULT 0,
    purchase_price      NUMERIC(15,2)   NOT NULL DEFAULT 0,
    discount_pct        NUMERIC(5,2)    NOT NULL DEFAULT 0,
    discount            NUMERIC(15,2)   NOT NULL DEFAULT 0,
    total_price         NUMERIC(15,2)   NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ     DEFAULT now(),
    updated_at          TIMESTAMPTZ     DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.sale_return_items TO authenticated;
ALTER TABLE public.sale_return_items DISABLE ROW LEVEL SECURITY;


-- =============================================
-- STEP 4: updated_at auto-touch triggers
-- =============================================
CREATE OR REPLACE FUNCTION update_sale_returns_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sale_returns_updated_at
BEFORE UPDATE ON public.sale_returns
FOR EACH ROW EXECUTE FUNCTION update_sale_returns_updated_at();

CREATE OR REPLACE FUNCTION update_sale_return_payments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sale_return_payments_updated_at
BEFORE UPDATE ON public.sale_return_payments
FOR EACH ROW EXECUTE FUNCTION update_sale_return_payments_updated_at();

CREATE OR REPLACE FUNCTION update_sale_return_items_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sale_return_items_updated_at
BEFORE UPDATE ON public.sale_return_items
FOR EACH ROW EXECUTE FUNCTION update_sale_return_items_updated_at();


-- =============================================
-- STEP 5: sale_return_items => branch_stock_inventory
--         return hone par stock wapis (quantity +) ho
-- =============================================
CREATE OR REPLACE FUNCTION sync_return_to_branch_stock()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.branch_stock_inventory
        SET quantity = quantity + NEW.quantity
        WHERE id = NEW.branch_stock_id;

    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE public.branch_stock_inventory
        SET quantity = quantity - OLD.quantity + NEW.quantity
        WHERE id = NEW.branch_stock_id;

    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.branch_stock_inventory
        SET quantity = quantity - OLD.quantity
        WHERE id = OLD.branch_stock_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_return_to_branch_stock
AFTER INSERT OR UPDATE OR DELETE ON public.sale_return_items
FOR EACH ROW EXECUTE FUNCTION sync_return_to_branch_stock();


-- =============================================
-- STEP 6: sale_return_payments => branch_cash_counter
--         refund => return_sale (+) aur total_amount (-)
--         apne hi (NEW/OLD) created_at ke din se match,
--         now() se nahi -- warna backdated/late payment
--         galat din mein (ya kabhi bhi nahi) sync hota
-- =============================================
CREATE OR REPLACE FUNCTION sync_refund_to_cash_counter()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.branch_cash_counter
        SET
            return_sale  = return_sale + NEW.amount,
            total_amount = total_amount - NEW.amount
        WHERE branch_id = NEW.branch_id
          AND (created_at AT TIME ZONE 'Asia/Karachi')::date = (NEW.created_at AT TIME ZONE 'Asia/Karachi')::date;

    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE public.branch_cash_counter
        SET
            return_sale  = return_sale - OLD.amount + NEW.amount,
            total_amount = total_amount + OLD.amount - NEW.amount
        WHERE branch_id = NEW.branch_id
          AND (created_at AT TIME ZONE 'Asia/Karachi')::date = (NEW.created_at AT TIME ZONE 'Asia/Karachi')::date;

    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.branch_cash_counter
        SET
            return_sale  = return_sale - OLD.amount,
            total_amount = total_amount + OLD.amount
        WHERE branch_id = OLD.branch_id
          AND (created_at AT TIME ZONE 'Asia/Karachi')::date = (OLD.created_at AT TIME ZONE 'Asia/Karachi')::date;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_refund_to_cash_counter
AFTER INSERT OR UPDATE OR DELETE ON public.sale_return_payments
FOR EACH ROW EXECUTE FUNCTION sync_refund_to_cash_counter();


-- =============================================
-- STEP 7: sale_returns => employee_salary
--         salesman ke total_sales_return mein return_total add/subtract ho
-- =============================================
CREATE OR REPLACE FUNCTION sync_return_to_employee_salary()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.salesman_id IS NOT NULL THEN
            UPDATE public.employee_salary
            SET total_sales_return = total_sales_return + NEW.total_amount
            WHERE id = NEW.salesman_id;
        END IF;

    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.salesman_id IS NOT NULL THEN
            UPDATE public.employee_salary
            SET total_sales_return = total_sales_return - OLD.total_amount
            WHERE id = OLD.salesman_id;
        END IF;
        IF NEW.salesman_id IS NOT NULL THEN
            UPDATE public.employee_salary
            SET total_sales_return = total_sales_return + NEW.total_amount
            WHERE id = NEW.salesman_id;
        END IF;

    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.salesman_id IS NOT NULL THEN
            UPDATE public.employee_salary
            SET total_sales_return = total_sales_return - OLD.total_amount
            WHERE id = OLD.salesman_id;
        END IF;
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_return_to_employee_salary
AFTER INSERT OR UPDATE OR DELETE ON public.sale_returns
FOR EACH ROW EXECUTE FUNCTION sync_return_to_employee_salary();
