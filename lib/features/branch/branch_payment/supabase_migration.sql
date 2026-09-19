-- =============================================
-- Branch -> Head Office payments
--
-- Flow:
--   1. Branch pays an amount        -> create_branch_payment()
--        branch_cash_counter (today): paid_amount + amount, total_amount - amount
--        payment status = 'pending'
--   2. Admin accepts                -> accept_branch_payment()
--        head_office_cash_counter (today): net_amount + amount
--   3. Admin rejects                -> reject_branch_payment()
--        branch_cash_counter is restored (paid_amount / total_amount)
-- =============================================

CREATE TABLE IF NOT EXISTS public.branch_payments (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_number  TEXT          NOT NULL UNIQUE,
    branch_id       UUID          NOT NULL REFERENCES public.branches(id)     ON DELETE CASCADE,
    head_office_id  UUID          NOT NULL REFERENCES public.head_offices(id) ON DELETE RESTRICT,
    amount          NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    status          TEXT          NOT NULL DEFAULT 'pending'
                                  CHECK (status IN ('pending', 'accepted', 'rejected')),
    notes           TEXT,
    paid_at         TIMESTAMPTZ   NOT NULL DEFAULT now(),
    accepted_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_branch_payments_head_office ON public.branch_payments (head_office_id, paid_at DESC);
CREATE INDEX IF NOT EXISTS idx_branch_payments_branch      ON public.branch_payments (branch_id, paid_at DESC);

GRANT ALL ON public.branch_payments TO authenticated;
GRANT ALL ON public.branch_payments TO anon;
-- Supabase keeps RLS on for new tables; without a policy the app's SELECT
-- returns no rows. Same policy the other cash-counter tables use.
ALTER TABLE public.branch_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS authenticated_full_access ON public.branch_payments;
CREATE POLICY authenticated_full_access ON public.branch_payments
    FOR ALL TO authenticated USING (true) WITH CHECK (true);


-- ---------------------------------------------
-- Branch pays the Head Office
-- ---------------------------------------------
CREATE OR REPLACE FUNCTION public.create_branch_payment(
    p_branch_id UUID,
    p_amount    NUMERIC,
    p_notes     TEXT DEFAULT NULL
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_head_office UUID;
    v_counter_id  UUID;
    v_available   NUMERIC;
    v_last_num    INTEGER;
    v_number      TEXT;
    v_id          UUID;
BEGIN
    IF p_amount IS NULL OR p_amount <= 0 THEN
        RAISE EXCEPTION 'Amount must be greater than zero';
    END IF;

    -- System has a single head office.
    SELECT id INTO v_head_office FROM public.head_offices ORDER BY created_at LIMIT 1;
    IF v_head_office IS NULL THEN
        RAISE EXCEPTION 'No head office configured';
    END IF;

    SELECT id, total_amount INTO v_counter_id, v_available
    FROM public.branch_cash_counter
    WHERE branch_id = p_branch_id
      AND (created_at AT TIME ZONE 'Asia/Karachi')::date = (now() AT TIME ZONE 'Asia/Karachi')::date
    ORDER BY created_at DESC
    LIMIT 1
    FOR UPDATE;

    IF v_counter_id IS NULL THEN
        RAISE EXCEPTION 'No cash counter found for today';
    END IF;

    IF p_amount > v_available THEN
        RAISE EXCEPTION 'Amount exceeds available cash counter balance (%)', v_available;
    END IF;

    PERFORM pg_advisory_xact_lock(hashtext('branch_payment_number'));
    SELECT COALESCE(MAX(CAST(SUBSTRING(payment_number FROM 5) AS INTEGER)), 0)
    INTO v_last_num FROM public.branch_payments WHERE payment_number LIKE 'BPY-%';
    v_number := 'BPY-' || LPAD((v_last_num + 1)::TEXT, 6, '0');

    INSERT INTO public.branch_payments (payment_number, branch_id, head_office_id, amount, notes)
    VALUES (v_number, p_branch_id, v_head_office, p_amount, NULLIF(BTRIM(p_notes), ''))
    RETURNING id INTO v_id;

    UPDATE public.branch_cash_counter
    SET paid_amount  = paid_amount + p_amount,
        total_amount = total_amount - p_amount
    WHERE id = v_counter_id;

    RETURN v_id;
END;
$$;


-- ---------------------------------------------
-- Admin accepts -> Head Office net amount grows
-- ---------------------------------------------
CREATE OR REPLACE FUNCTION public.accept_branch_payment(p_payment_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_amount NUMERIC;
BEGIN
    SELECT amount INTO v_amount
    FROM public.branch_payments
    WHERE id = p_payment_id AND status = 'pending'
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Payment not found or not pending: %', p_payment_id;
    END IF;

    PERFORM public.get_or_create_ho_counter();

    UPDATE public.head_office_cash_counter
    SET net_amount = net_amount + v_amount
    WHERE counter_date = CURRENT_DATE;

    UPDATE public.branch_payments
    SET status = 'accepted', accepted_at = now()
    WHERE id = p_payment_id;
END;
$$;


-- ---------------------------------------------
-- Admin rejects -> money goes back to the branch counter
-- ---------------------------------------------
CREATE OR REPLACE FUNCTION public.reject_branch_payment(p_payment_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_amount    NUMERIC;
    v_branch_id UUID;
    v_paid_at   TIMESTAMPTZ;
BEGIN
    SELECT amount, branch_id, paid_at INTO v_amount, v_branch_id, v_paid_at
    FROM public.branch_payments
    WHERE id = p_payment_id AND status = 'pending'
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Payment not found or not pending: %', p_payment_id;
    END IF;

    -- paid_amount is undone on the day the payment was made ...
    UPDATE public.branch_cash_counter
    SET paid_amount = paid_amount - v_amount
    WHERE branch_id = v_branch_id
      AND (created_at AT TIME ZONE 'Asia/Karachi')::date = (v_paid_at AT TIME ZONE 'Asia/Karachi')::date;

    -- ... while the cash returns to today's running balance.
    UPDATE public.branch_cash_counter
    SET total_amount = total_amount + v_amount
    WHERE branch_id = v_branch_id
      AND (created_at AT TIME ZONE 'Asia/Karachi')::date = (now() AT TIME ZONE 'Asia/Karachi')::date;

    UPDATE public.branch_payments
    SET status = 'rejected'
    WHERE id = p_payment_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_branch_payment(UUID, NUMERIC, TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.accept_branch_payment(UUID)                TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.reject_branch_payment(UUID)                TO authenticated, anon;

NOTIFY pgrst, 'reload schema';
