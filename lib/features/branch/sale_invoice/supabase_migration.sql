-- Pehle drop karo
DROP TABLE IF EXISTS public.sale_invoice_items;
DROP TABLE IF EXISTS public.sale_invoice_payments;
DROP TABLE IF EXISTS public.sale_invoices;

-- =============================================
-- STEP 1: sale_invoices table
-- =============================================
CREATE TABLE public.sale_invoices (
    id                          UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    invoice_number              TEXT            NOT NULL UNIQUE,
    branch_id                   UUID            NOT NULL REFERENCES public.branches(id) ON DELETE RESTRICT,
    printer_id                  UUID            REFERENCES public.assign_printer(id) ON DELETE RESTRICT,
    cashier_id                  UUID            REFERENCES public.users(id) ON DELETE RESTRICT,
    salesman_id                 UUID            REFERENCES public.employee_salary(id) ON DELETE RESTRICT,
    manager_id                  UUID            REFERENCES public.employee_salary(id) ON DELETE RESTRICT,
    subtotal                    NUMERIC(15,2)   NOT NULL DEFAULT 0,
    total_discount              NUMERIC(15,2)   NOT NULL DEFAULT 0,
    total_amount                NUMERIC(15,2)   NOT NULL DEFAULT 0,
    salesman_commission_percent NUMERIC(5,2)    NOT NULL DEFAULT 0,
    salesman_commission_amount  NUMERIC(15,2)   NOT NULL DEFAULT 0,
    manager_commission_percent  NUMERIC(5,2)    NOT NULL DEFAULT 0,
    manager_commission_amount   NUMERIC(15,2)   NOT NULL DEFAULT 0,
    note                        TEXT,
    created_at                  TIMESTAMPTZ     DEFAULT now(),
    updated_at                  TIMESTAMPTZ     DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.sale_invoices TO authenticated;
ALTER TABLE public.sale_invoices DISABLE ROW LEVEL SECURITY;


-- =============================================
-- STEP 2: sale_invoice_payments table
-- =============================================
CREATE TABLE public.sale_invoice_payments (
    id                  UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    sale_invoice_id     UUID            NOT NULL REFERENCES public.sale_invoices(id) ON DELETE CASCADE,
    branch_id           UUID            NOT NULL REFERENCES public.branches(id) ON DELETE RESTRICT,
    bank_entry_id       UUID            REFERENCES public.bank_entries(id) ON DELETE RESTRICT,
    payment_type        TEXT            NOT NULL CHECK (payment_type IN ('cash', 'card')),
    amount              NUMERIC(15,2)   NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ     DEFAULT now(),
    updated_at          TIMESTAMPTZ     DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.sale_invoice_payments TO authenticated;
ALTER TABLE public.sale_invoice_payments DISABLE ROW LEVEL SECURITY;


-- =============================================
-- STEP 3: sale_invoice_items table
-- =============================================
CREATE TABLE public.sale_invoice_items (
    id                  UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    sale_invoice_id     UUID            NOT NULL REFERENCES public.sale_invoices(id) ON DELETE CASCADE,
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

GRANT SELECT, INSERT, UPDATE, DELETE ON public.sale_invoice_items TO authenticated;
ALTER TABLE public.sale_invoice_items DISABLE ROW LEVEL SECURITY;


-- =============================================
-- STEP 4: updated_at triggers
-- =============================================
CREATE OR REPLACE FUNCTION update_sale_invoices_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sale_invoices_updated_at
BEFORE UPDATE ON public.sale_invoices
FOR EACH ROW EXECUTE FUNCTION update_sale_invoices_updated_at();

CREATE OR REPLACE FUNCTION update_sale_invoice_payments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sale_invoice_payments_updated_at
BEFORE UPDATE ON public.sale_invoice_payments
FOR EACH ROW EXECUTE FUNCTION update_sale_invoice_payments_updated_at();

CREATE OR REPLACE FUNCTION update_sale_invoice_items_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sale_invoice_items_updated_at
BEFORE UPDATE ON public.sale_invoice_items
FOR EACH ROW EXECUTE FUNCTION update_sale_invoice_items_updated_at();


-- =============================================
-- STEP 5: branch_stock_inventory quantity minus
-- =============================================
CREATE OR REPLACE FUNCTION sync_sale_to_branch_stock()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.branch_stock_inventory
        SET quantity = quantity - NEW.quantity
        WHERE id = NEW.branch_stock_id;

    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE public.branch_stock_inventory
        SET quantity = quantity + OLD.quantity - NEW.quantity
        WHERE id = NEW.branch_stock_id;

    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.branch_stock_inventory
        SET quantity = quantity + OLD.quantity
        WHERE id = OLD.branch_stock_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_sale_to_branch_stock
AFTER INSERT OR UPDATE OR DELETE ON public.sale_invoice_items
FOR EACH ROW EXECUTE FUNCTION sync_sale_to_branch_stock();


-- =============================================
-- STEP 6: Payment hone par branch_cash_counter
--         update ho
-- =============================================
CREATE OR REPLACE FUNCTION sync_payment_to_cash_counter()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.payment_type = 'cash' THEN
            UPDATE public.branch_cash_counter
            SET
                cash_sale    = cash_sale + NEW.amount,
                total_sale   = total_sale + NEW.amount,
                total_amount = total_amount + NEW.amount
            WHERE branch_id = NEW.branch_id
              AND DATE(created_at) = CURRENT_DATE;
        ELSE
            UPDATE public.branch_cash_counter
            SET
                card_sale    = card_sale + NEW.amount,
                total_sale   = total_sale + NEW.amount,
                total_amount = total_amount + NEW.amount
            WHERE branch_id = NEW.branch_id
              AND DATE(created_at) = CURRENT_DATE;
        END IF;

    ELSIF TG_OP = 'UPDATE' THEN
        -- Pehle purana minus karo
        IF OLD.payment_type = 'cash' THEN
            UPDATE public.branch_cash_counter
            SET
                cash_sale    = cash_sale - OLD.amount,
                total_sale   = total_sale - OLD.amount,
                total_amount = total_amount - OLD.amount
            WHERE branch_id = OLD.branch_id
              AND DATE(created_at) = CURRENT_DATE;
        ELSE
            UPDATE public.branch_cash_counter
            SET
                card_sale    = card_sale - OLD.amount,
                total_sale   = total_sale - OLD.amount,
                total_amount = total_amount - OLD.amount
            WHERE branch_id = OLD.branch_id
              AND DATE(created_at) = CURRENT_DATE;
        END IF;

        -- Phir naya add karo
        IF NEW.payment_type = 'cash' THEN
            UPDATE public.branch_cash_counter
            SET
                cash_sale    = cash_sale + NEW.amount,
                total_sale   = total_sale + NEW.amount,
                total_amount = total_amount + NEW.amount
            WHERE branch_id = NEW.branch_id
              AND DATE(created_at) = CURRENT_DATE;
        ELSE
            UPDATE public.branch_cash_counter
            SET
                card_sale    = card_sale + NEW.amount,
                total_sale   = total_sale + NEW.amount,
                total_amount = total_amount + NEW.amount
            WHERE branch_id = NEW.branch_id
              AND DATE(created_at) = CURRENT_DATE;
        END IF;

    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.payment_type = 'cash' THEN
            UPDATE public.branch_cash_counter
            SET
                cash_sale    = cash_sale - OLD.amount,
                total_sale   = total_sale - OLD.amount,
                total_amount = total_amount - OLD.amount
            WHERE branch_id = OLD.branch_id
              AND DATE(created_at) = CURRENT_DATE;
        ELSE
            UPDATE public.branch_cash_counter
            SET
                card_sale    = card_sale - OLD.amount,
                total_sale   = total_sale - OLD.amount,
                total_amount = total_amount - OLD.amount
            WHERE branch_id = OLD.branch_id
              AND DATE(created_at) = CURRENT_DATE;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_payment_to_cash_counter
AFTER INSERT OR UPDATE OR DELETE ON public.sale_invoice_payments
FOR EACH ROW EXECUTE FUNCTION sync_payment_to_cash_counter();


-- =============================================
-- STEP 7: employee_salary commission update
-- =============================================
CREATE OR REPLACE FUNCTION sync_commission_to_salary()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.salesman_id IS NOT NULL THEN
            UPDATE public.employee_salary
            SET total_sales = total_sales + NEW.total_amount
            WHERE id = NEW.salesman_id;
        END IF;

        IF NEW.manager_id IS NOT NULL THEN
            UPDATE public.employee_salary
            SET total_sales = total_sales + NEW.total_amount
            WHERE id = NEW.manager_id;
        END IF;

    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.salesman_id IS NOT NULL THEN
            UPDATE public.employee_salary
            SET total_sales = total_sales - OLD.total_amount
            WHERE id = OLD.salesman_id;
        END IF;

        IF NEW.salesman_id IS NOT NULL THEN
            UPDATE public.employee_salary
            SET total_sales = total_sales + NEW.total_amount
            WHERE id = NEW.salesman_id;
        END IF;

        IF OLD.manager_id IS NOT NULL THEN
            UPDATE public.employee_salary
            SET total_sales = total_sales - OLD.total_amount
            WHERE id = OLD.manager_id;
        END IF;

        IF NEW.manager_id IS NOT NULL THEN
            UPDATE public.employee_salary
            SET total_sales = total_sales + NEW.total_amount
            WHERE id = NEW.manager_id;
        END IF;

    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.salesman_id IS NOT NULL THEN
            UPDATE public.employee_salary
            SET total_sales = total_sales - OLD.total_amount
            WHERE id = OLD.salesman_id;
        END IF;

        IF OLD.manager_id IS NOT NULL THEN
            UPDATE public.employee_salary
            SET total_sales = total_sales - OLD.total_amount
            WHERE id = OLD.manager_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_commission_to_salary
AFTER INSERT OR UPDATE OR DELETE ON public.sale_invoices
FOR EACH ROW EXECUTE FUNCTION sync_commission_to_salary();


-- =============================================
-- STEP 8: Invoice number generate function
-- =============================================
CREATE OR REPLACE FUNCTION generate_sale_invoice_number()
RETURNS TEXT AS $$
DECLARE
    last_num INTEGER;
    new_num  TEXT;
BEGIN
    SELECT COALESCE(
        MAX(CAST(SUBSTRING(invoice_number FROM 5) AS INTEGER)), 0
    ) INTO last_num
    FROM public.sale_invoices
    WHERE invoice_number LIKE 'SAL-%';

    new_num := 'SAL-' || LPAD((last_num + 1)::TEXT, 6, '0');
    RETURN new_num;
END;
$$ LANGUAGE plpgsql;

-- Reload schema cache
NOTIFY pgrst, 'reload schema';


-- =============================================
-- STEP 10 (later addition): invoice-wise discount
--         Har branch ke liye superadmin se access
--         milta hai (branches.can_apply_invoice_discount) —
--         dekho lib/features/superadmin/branch/supabase_migration.sql
-- =============================================
ALTER TABLE public.sale_invoices
  ADD COLUMN IF NOT EXISTS invoice_discount NUMERIC(15,2) NOT NULL DEFAULT 0;

NOTIFY pgrst, 'reload schema';
