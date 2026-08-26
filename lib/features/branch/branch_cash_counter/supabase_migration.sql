-- =============================================
-- STEP 1: Extension enable karo
-- =============================================
CREATE EXTENSION IF NOT EXISTS pg_cron;


-- =============================================
-- STEP 2: branch_cash_counter table banao
-- =============================================
CREATE TABLE public.branch_cash_counter (
    id                          UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    branch_id                   UUID            NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    cash_sale                   NUMERIC(15,2)   NOT NULL DEFAULT 0,
    card_sale                   NUMERIC(15,2)   NOT NULL DEFAULT 0,
    total_sale                  NUMERIC(15,2)   NOT NULL DEFAULT 0,
    return_sale                 NUMERIC(15,2)   NOT NULL DEFAULT 0,
    return_amount_in_exchange   NUMERIC(15,2)   NOT NULL DEFAULT 0,
    received_amount_in_exchange NUMERIC(15,2)   NOT NULL DEFAULT 0,
    expense                     NUMERIC(15,2)   NOT NULL DEFAULT 0,
    gross                       NUMERIC(15,2)   NOT NULL DEFAULT 0,
    paid_amount                 NUMERIC(15,2)   NOT NULL DEFAULT 0,
    total_amount                NUMERIC(15,2)   NOT NULL DEFAULT 0,
    created_at                  TIMESTAMPTZ     DEFAULT now(),
    updated_at                  TIMESTAMPTZ     DEFAULT now()
);


-- =============================================
-- STEP 3: Permissions
-- =============================================
GRANT SELECT, INSERT, UPDATE, DELETE ON public.branch_cash_counter TO authenticated;
ALTER TABLE public.branch_cash_counter DISABLE ROW LEVEL SECURITY;


-- =============================================
-- STEP 4: updated_at auto trigger
-- =============================================
CREATE OR REPLACE FUNCTION update_branch_cash_counter_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_branch_cash_counter_updated_at
BEFORE UPDATE ON public.branch_cash_counter
FOR EACH ROW EXECUTE FUNCTION update_branch_cash_counter_updated_at();


-- =============================================
-- STEP 5: Har raat 12 baje (PKT) nai rows insert
-- Sab kuch 0 se shuru hota hai, sirf total_amount pichle
-- din wale (us branch ka last row) se carry forward hota hai.
-- =============================================
SELECT cron.schedule(
    'nightly-branch-cash-counter',
    '0 19 * * *',
    $$
    INSERT INTO public.branch_cash_counter (
        branch_id,
        cash_sale,
        card_sale,
        total_sale,
        return_sale,
        return_amount_in_exchange,
        received_amount_in_exchange,
        expense,
        gross,
        paid_amount,
        total_amount
    )
    SELECT
        b.id,
        0, 0, 0, 0, 0, 0, 0, 0, 0,
        COALESCE(
            (
                SELECT total_amount
                FROM public.branch_cash_counter
                WHERE branch_id = b.id
                ORDER BY created_at DESC
                LIMIT 1
            ),
            0
        )
    FROM public.branches b;
    $$
);

-- Reload schema cache
NOTIFY pgrst, 'reload schema';
