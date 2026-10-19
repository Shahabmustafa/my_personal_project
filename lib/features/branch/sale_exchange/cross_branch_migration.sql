-- Cross-branch exchange: customer ne maal Branch A se kharida, exchange
-- Branch B par ho raha hai.
--
--   * Return items ka stock  -> original invoice ki branch (A): branch_stock_id
--     pehle se A ki inventory row ko point karta hai, triggers wahi update karte hain.
--   * Collect / refund paisa -> A ka branch_cash_counter, jaise sale return mein.
--
-- Payment row ka branch_id B hi rehta hai (RLS: B ka user sirf apni branch ki
-- row likh sakta hai). Cash counter kis branch ka badle, ye naya column
-- cash_branch_id batata hai (NULL ho to branch_id hi).

ALTER TABLE public.sale_exchange_payments
    ADD COLUMN IF NOT EXISTS cash_branch_id UUID REFERENCES public.branches(id) ON DELETE RESTRICT;

CREATE OR REPLACE FUNCTION public.sync_exchange_to_cash_counter()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
DECLARE
    v_branch uuid;
BEGIN
    IF TG_OP IN ('UPDATE', 'DELETE') THEN
        v_branch := COALESCE(OLD.cash_branch_id, OLD.branch_id);
        IF OLD.direction = 'collect' THEN
            UPDATE public.branch_cash_counter
            SET received_amount_in_exchange = received_amount_in_exchange - OLD.amount,
                total_amount                = total_amount - OLD.amount
            WHERE branch_id = v_branch
              AND (created_at AT TIME ZONE 'Asia/Karachi')::date = (OLD.created_at AT TIME ZONE 'Asia/Karachi')::date;
        ELSE
            UPDATE public.branch_cash_counter
            SET return_amount_in_exchange = return_amount_in_exchange - OLD.amount,
                total_amount              = total_amount + OLD.amount
            WHERE branch_id = v_branch
              AND (created_at AT TIME ZONE 'Asia/Karachi')::date = (OLD.created_at AT TIME ZONE 'Asia/Karachi')::date;
        END IF;
    END IF;

    IF TG_OP IN ('INSERT', 'UPDATE') THEN
        v_branch := COALESCE(NEW.cash_branch_id, NEW.branch_id);
        IF NEW.direction = 'collect' THEN
            UPDATE public.branch_cash_counter
            SET received_amount_in_exchange = received_amount_in_exchange + NEW.amount,
                total_amount                = total_amount + NEW.amount
            WHERE branch_id = v_branch
              AND (created_at AT TIME ZONE 'Asia/Karachi')::date = (NEW.created_at AT TIME ZONE 'Asia/Karachi')::date;
        ELSE
            UPDATE public.branch_cash_counter
            SET return_amount_in_exchange = return_amount_in_exchange + NEW.amount,
                total_amount              = total_amount - NEW.amount
            WHERE branch_id = v_branch
              AND (created_at AT TIME ZONE 'Asia/Karachi')::date = (NEW.created_at AT TIME ZONE 'Asia/Karachi')::date;
        END IF;
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$;

NOTIFY pgrst, 'reload schema';
