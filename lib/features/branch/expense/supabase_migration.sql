-- =============================================
-- STEP 1: expense_heads table
-- =============================================
CREATE TABLE public.expense_heads (
    id          UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    name        TEXT        NOT NULL,
    description TEXT,
    is_active   BOOLEAN     DEFAULT true,
    created_at  TIMESTAMPTZ DEFAULT now(),
    updated_at  TIMESTAMPTZ DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.expense_heads TO authenticated;
ALTER TABLE public.expense_heads DISABLE ROW LEVEL SECURITY;


-- =============================================
-- STEP 2: expense_entries table
-- =============================================
CREATE TABLE public.expense_entries (
    id                      UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    branch_id               UUID        NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    branch_cash_counter_id  UUID        NOT NULL REFERENCES public.branch_cash_counter(id) ON DELETE CASCADE,
    expense_head_id         UUID        NOT NULL REFERENCES public.expense_heads(id) ON DELETE RESTRICT,
    amount                  NUMERIC(15,2) NOT NULL DEFAULT 0,
    note                    TEXT,
    created_at              TIMESTAMPTZ DEFAULT now(),
    updated_at              TIMESTAMPTZ DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.expense_entries TO authenticated;
ALTER TABLE public.expense_entries DISABLE ROW LEVEL SECURITY;


-- =============================================
-- STEP 3: updated_at triggers
-- =============================================
CREATE OR REPLACE FUNCTION update_expense_heads_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_expense_heads_updated_at
BEFORE UPDATE ON public.expense_heads
FOR EACH ROW EXECUTE FUNCTION update_expense_heads_updated_at();

-- ----

CREATE OR REPLACE FUNCTION update_expense_entries_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_expense_entries_updated_at
BEFORE UPDATE ON public.expense_entries
FOR EACH ROW EXECUTE FUNCTION update_expense_entries_updated_at();


-- =============================================
-- STEP 4: Expense add hone par branch_cash_counter
--         update karne ka trigger
-- =============================================
CREATE OR REPLACE FUNCTION sync_expense_to_cash_counter()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.branch_cash_counter
        SET
            expense     = expense + NEW.amount,
            total_amount = total_amount - NEW.amount
        WHERE id = NEW.branch_cash_counter_id;

    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE public.branch_cash_counter
        SET
            expense      = expense - OLD.amount + NEW.amount,
            total_amount = total_amount + OLD.amount - NEW.amount
        WHERE id = NEW.branch_cash_counter_id;

    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.branch_cash_counter
        SET
            expense      = expense - OLD.amount,
            total_amount = total_amount + OLD.amount
        WHERE id = OLD.branch_cash_counter_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_expense_to_cash_counter
AFTER INSERT OR UPDATE OR DELETE ON public.expense_entries
FOR EACH ROW EXECUTE FUNCTION sync_expense_to_cash_counter();
