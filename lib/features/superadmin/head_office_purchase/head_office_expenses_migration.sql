-- ─────────────────────────────────────────────────────────────────────────────
-- head_office_expenses: superadmin (head office) ke kharche — e.g. purchase
-- par Transport / Barcode. Branch ke expense_entries se alag table.
-- Expense head wahi shared `expense_heads` table se aata hai.
-- Purchase ke sath add ho to purchase_invoice_id set hota hai aur note mein
-- invoice number. Company ke khate (credit) mein ye amount NAHI jaata —
-- sirf head office cash counter ke `expense` mein jaata hai.
-- STATUS (2026-10-08): applied to LIVE database.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.head_office_expenses (
    id                          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    head_office_id              UUID          REFERENCES public.head_offices(id) ON DELETE CASCADE,
    head_office_cash_counter_id UUID          REFERENCES public.head_office_cash_counter(id) ON DELETE SET NULL,
    expense_head_id             UUID          NOT NULL REFERENCES public.expense_heads(id) ON DELETE RESTRICT,
    purchase_invoice_id         UUID          REFERENCES public.purchase_invoices(id) ON DELETE SET NULL,
    amount                      NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    note                        TEXT,
    created_at                  TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at                  TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS head_office_expenses_invoice_idx
    ON public.head_office_expenses (purchase_invoice_id);
CREATE INDEX IF NOT EXISTS head_office_expenses_created_idx
    ON public.head_office_expenses (created_at DESC);

ALTER TABLE public.head_office_expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY authenticated_full_access ON public.head_office_expenses
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

REVOKE ALL ON public.head_office_expenses FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.head_office_expenses TO authenticated;
