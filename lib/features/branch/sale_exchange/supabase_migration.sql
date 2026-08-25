-- Pehle drop karo
DROP TABLE IF EXISTS public.sale_exchange_payments;
DROP TABLE IF EXISTS public.sale_exchange_new_items;
DROP TABLE IF EXISTS public.sale_exchange_return_items;
DROP TABLE IF EXISTS public.sale_exchanges;

-- =============================================
-- STEP 1: sale_exchanges table
-- =============================================
CREATE TABLE public.sale_exchanges (
    id                          UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    exchange_number             TEXT            NOT NULL UNIQUE,
    branch_id                   UUID            NOT NULL REFERENCES public.branches(id) ON DELETE RESTRICT,
    original_invoice_id         UUID            REFERENCES public.sale_invoices(id) ON DELETE SET NULL,
    printer_id                  UUID            REFERENCES public.assign_printer(id) ON DELETE RESTRICT,
    cashier_id                  UUID            REFERENCES public.users(id) ON DELETE RESTRICT,
    customer_id                 UUID            REFERENCES public.customers(id) ON DELETE SET NULL,
    salesman_id                 UUID            REFERENCES public.employee_salary(id) ON DELETE RESTRICT,
    return_subtotal              NUMERIC(15,2)   NOT NULL DEFAULT 0,
    return_discount               NUMERIC(15,2)   NOT NULL DEFAULT 0,
    return_total                  NUMERIC(15,2)   NOT NULL DEFAULT 0,
    new_subtotal                  NUMERIC(15,2)   NOT NULL DEFAULT 0,
    new_discount                  NUMERIC(15,2)   NOT NULL DEFAULT 0,
    new_total                     NUMERIC(15,2)   NOT NULL DEFAULT 0,
    difference_amount             NUMERIC(15,2)   NOT NULL DEFAULT 0,
    salesman_commission_percent   NUMERIC(5,2)    NOT NULL DEFAULT 0,
    salesman_commission_amount    NUMERIC(15,2)   NOT NULL DEFAULT 0,
    note                        TEXT,
    created_at                  TIMESTAMPTZ     DEFAULT now(),
    updated_at                  TIMESTAMPTZ     DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.sale_exchanges TO authenticated;
ALTER TABLE public.sale_exchanges DISABLE ROW LEVEL SECURITY;


-- =============================================
-- STEP 2: sale_exchange_payments table
-- =============================================
CREATE TABLE public.sale_exchange_payments (
    id                  UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    sale_exchange_id    UUID            NOT NULL REFERENCES public.sale_exchanges(id) ON DELETE CASCADE,
    branch_id           UUID            NOT NULL REFERENCES public.branches(id) ON DELETE RESTRICT,
    bank_entry_id       UUID            REFERENCES public.bank_entries(id) ON DELETE RESTRICT,
    direction           TEXT            NOT NULL CHECK (direction IN ('collect', 'refund')),
    payment_type        TEXT            NOT NULL CHECK (payment_type IN ('cash', 'card')),
    amount              NUMERIC(15,2)   NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ     DEFAULT now(),
    updated_at          TIMESTAMPTZ     DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.sale_exchange_payments TO authenticated;
ALTER TABLE public.sale_exchange_payments DISABLE ROW LEVEL SECURITY;


-- =============================================
-- STEP 3: sale_exchange_return_items table
--         (customer wapas kar raha hai)
-- =============================================
CREATE TABLE public.sale_exchange_return_items (
    id                              UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    sale_exchange_id                UUID            NOT NULL REFERENCES public.sale_exchanges(id) ON DELETE CASCADE,
    branch_id                       UUID            NOT NULL REFERENCES public.branches(id) ON DELETE RESTRICT,
    branch_stock_id                 UUID            NOT NULL REFERENCES public.branch_stock_inventory(id) ON DELETE RESTRICT,
    original_sale_invoice_item_id   UUID            REFERENCES public.sale_invoice_items(id) ON DELETE SET NULL,
    product_id                      UUID            NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
    size_id                         UUID            REFERENCES public.sizes(id) ON DELETE RESTRICT,
    color_id                        UUID            REFERENCES public.colors(id) ON DELETE RESTRICT,
    brand_id                        UUID            REFERENCES public.brands(id) ON DELETE RESTRICT,
    category_id                     UUID            REFERENCES public.categories(id) ON DELETE RESTRICT,
    type_id                         UUID            REFERENCES public.types(id) ON DELETE RESTRICT,
    barcode                         TEXT,
    quantity                        INTEGER         NOT NULL DEFAULT 1,
    sale_price                      NUMERIC(15,2)   NOT NULL DEFAULT 0,
    purchase_price                  NUMERIC(15,2)   NOT NULL DEFAULT 0,
    discount_pct                    NUMERIC(5,2)    NOT NULL DEFAULT 0,
    discount                        NUMERIC(15,2)   NOT NULL DEFAULT 0,
    total_price                     NUMERIC(15,2)   NOT NULL DEFAULT 0,
    created_at                      TIMESTAMPTZ     DEFAULT now(),
    updated_at                      TIMESTAMPTZ     DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.sale_exchange_return_items TO authenticated;
ALTER TABLE public.sale_exchange_return_items DISABLE ROW LEVEL SECURITY;


-- =============================================
-- STEP 4: sale_exchange_new_items table
--         (customer naya le raha hai)
-- =============================================
CREATE TABLE public.sale_exchange_new_items (
    id                  UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    sale_exchange_id    UUID            NOT NULL REFERENCES public.sale_exchanges(id) ON DELETE CASCADE,
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

GRANT SELECT, INSERT, UPDATE, DELETE ON public.sale_exchange_new_items TO authenticated;
ALTER TABLE public.sale_exchange_new_items DISABLE ROW LEVEL SECURITY;


-- =============================================
-- STEP 5: updated_at triggers
-- =============================================
CREATE OR REPLACE FUNCTION update_sale_exchanges_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sale_exchanges_updated_at
BEFORE UPDATE ON public.sale_exchanges
FOR EACH ROW EXECUTE FUNCTION update_sale_exchanges_updated_at();

CREATE OR REPLACE FUNCTION update_sale_exchange_payments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sale_exchange_payments_updated_at
BEFORE UPDATE ON public.sale_exchange_payments
FOR EACH ROW EXECUTE FUNCTION update_sale_exchange_payments_updated_at();

CREATE OR REPLACE FUNCTION update_sale_exchange_return_items_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sale_exchange_return_items_updated_at
BEFORE UPDATE ON public.sale_exchange_return_items
FOR EACH ROW EXECUTE FUNCTION update_sale_exchange_return_items_updated_at();

CREATE OR REPLACE FUNCTION update_sale_exchange_new_items_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sale_exchange_new_items_updated_at
BEFORE UPDATE ON public.sale_exchange_new_items
FOR EACH ROW EXECUTE FUNCTION update_sale_exchange_new_items_updated_at();


-- =============================================
-- STEP 6: branch_stock_inventory sync
--         return items => stock wapas add
--         new items    => stock minus
-- =============================================
CREATE OR REPLACE FUNCTION sync_exchange_return_to_branch_stock()
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

CREATE TRIGGER trg_sync_exchange_return_to_branch_stock
AFTER INSERT OR UPDATE OR DELETE ON public.sale_exchange_return_items
FOR EACH ROW EXECUTE FUNCTION sync_exchange_return_to_branch_stock();

CREATE OR REPLACE FUNCTION sync_exchange_new_to_branch_stock()
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

CREATE TRIGGER trg_sync_exchange_new_to_branch_stock
AFTER INSERT OR UPDATE OR DELETE ON public.sale_exchange_new_items
FOR EACH ROW EXECUTE FUNCTION sync_exchange_new_to_branch_stock();


-- =============================================
-- STEP 7: sale_exchange_payments => branch_cash_counter
--         collect => received_amount_in_exchange
--         refund  => return_amount_in_exchange
--         cash_sale/card_sale/total_sale ko touch nahi karte
-- =============================================
CREATE OR REPLACE FUNCTION sync_exchange_to_cash_counter()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.direction = 'collect' THEN
            UPDATE public.branch_cash_counter
            SET
                received_amount_in_exchange = received_amount_in_exchange + NEW.amount,
                total_amount                = total_amount + NEW.amount
            WHERE branch_id = NEW.branch_id
              AND DATE(created_at) = CURRENT_DATE;
        ELSE
            UPDATE public.branch_cash_counter
            SET
                return_amount_in_exchange = return_amount_in_exchange + NEW.amount,
                total_amount              = total_amount - NEW.amount
            WHERE branch_id = NEW.branch_id
              AND DATE(created_at) = CURRENT_DATE;
        END IF;

    ELSIF TG_OP = 'UPDATE' THEN
        -- Pehle purana reverse karo
        IF OLD.direction = 'collect' THEN
            UPDATE public.branch_cash_counter
            SET
                received_amount_in_exchange = received_amount_in_exchange - OLD.amount,
                total_amount                = total_amount - OLD.amount
            WHERE branch_id = OLD.branch_id
              AND DATE(created_at) = CURRENT_DATE;
        ELSE
            UPDATE public.branch_cash_counter
            SET
                return_amount_in_exchange = return_amount_in_exchange - OLD.amount,
                total_amount              = total_amount + OLD.amount
            WHERE branch_id = OLD.branch_id
              AND DATE(created_at) = CURRENT_DATE;
        END IF;

        -- Phir naya apply karo
        IF NEW.direction = 'collect' THEN
            UPDATE public.branch_cash_counter
            SET
                received_amount_in_exchange = received_amount_in_exchange + NEW.amount,
                total_amount                = total_amount + NEW.amount
            WHERE branch_id = NEW.branch_id
              AND DATE(created_at) = CURRENT_DATE;
        ELSE
            UPDATE public.branch_cash_counter
            SET
                return_amount_in_exchange = return_amount_in_exchange + NEW.amount,
                total_amount              = total_amount - NEW.amount
            WHERE branch_id = NEW.branch_id
              AND DATE(created_at) = CURRENT_DATE;
        END IF;

    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.direction = 'collect' THEN
            UPDATE public.branch_cash_counter
            SET
                received_amount_in_exchange = received_amount_in_exchange - OLD.amount,
                total_amount                = total_amount - OLD.amount
            WHERE branch_id = OLD.branch_id
              AND DATE(created_at) = CURRENT_DATE;
        ELSE
            UPDATE public.branch_cash_counter
            SET
                return_amount_in_exchange = return_amount_in_exchange - OLD.amount,
                total_amount              = total_amount + OLD.amount
            WHERE branch_id = OLD.branch_id
              AND DATE(created_at) = CURRENT_DATE;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_exchange_to_cash_counter
AFTER INSERT OR UPDATE OR DELETE ON public.sale_exchange_payments
FOR EACH ROW EXECUTE FUNCTION sync_exchange_to_cash_counter();


-- =============================================
-- STEP 8: sale_exchanges => employee_salary commission
--         difference_amount (signed) directly total_sales mein
-- =============================================
CREATE OR REPLACE FUNCTION sync_exchange_commission_to_salary()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.salesman_id IS NOT NULL THEN
            UPDATE public.employee_salary
            SET total_sales = total_sales + NEW.difference_amount
            WHERE id = NEW.salesman_id;
        END IF;

    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.salesman_id IS NOT NULL THEN
            UPDATE public.employee_salary
            SET total_sales = total_sales - OLD.difference_amount
            WHERE id = OLD.salesman_id;
        END IF;

        IF NEW.salesman_id IS NOT NULL THEN
            UPDATE public.employee_salary
            SET total_sales = total_sales + NEW.difference_amount
            WHERE id = NEW.salesman_id;
        END IF;

    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.salesman_id IS NOT NULL THEN
            UPDATE public.employee_salary
            SET total_sales = total_sales - OLD.difference_amount
            WHERE id = OLD.salesman_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_exchange_commission_to_salary
AFTER INSERT OR UPDATE OR DELETE ON public.sale_exchanges
FOR EACH ROW EXECUTE FUNCTION sync_exchange_commission_to_salary();


-- =============================================
-- STEP 9: Exchange number generate function
-- =============================================
CREATE OR REPLACE FUNCTION generate_sale_exchange_number()
RETURNS TEXT AS $$
DECLARE
    last_num INTEGER;
    new_num  TEXT;
BEGIN
    SELECT COALESCE(
        MAX(CAST(SUBSTRING(exchange_number FROM 5) AS INTEGER)), 0
    ) INTO last_num
    FROM public.sale_exchanges
    WHERE exchange_number LIKE 'EXC-%';

    new_num := 'EXC-' || LPAD((last_num + 1)::TEXT, 6, '0');
    RETURN new_num;
END;
$$ LANGUAGE plpgsql;

-- Reload schema cache
NOTIFY pgrst, 'reload schema';
