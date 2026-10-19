-- Cash Counter: server-side pagination.
--
--   * Index (branch_id, created_at DESC): list ka WHERE branch_id + ORDER BY
--     created_at DESC + range() aur neeche wala totals aggregate dono isi se chalte hain.
--   * branch_cash_counter_stats: summary cards ke totals poori table par SUM se
--     (page ki loaded rows se nahi) — list query ke sath nahi, alag call.
--     Search wali filters (din / amount) optional hain taake cards list se match karein.

CREATE INDEX IF NOT EXISTS idx_branch_cash_counter_branch_created
  ON public.branch_cash_counter (branch_id, created_at DESC);

CREATE OR REPLACE FUNCTION public.branch_cash_counter_stats(
  p_branch_id  uuid,
  p_from       timestamptz DEFAULT NULL,
  p_to         timestamptz DEFAULT NULL,
  p_total_sale numeric     DEFAULT NULL
) RETURNS json
LANGUAGE sql STABLE
SET search_path = public
AS $$
  SELECT json_build_object(
    'record_count', count(*),
    'total_sale',   COALESCE(sum(total_sale), 0),
    'net_sale',     COALESCE(sum(total_sale - return_sale - return_amount_in_exchange
                                 + received_amount_in_exchange), 0),
    'expense',      COALESCE(sum(expense), 0),
    'gross',        COALESCE(sum(gross), 0),
    'total_amount', COALESCE(sum(total_amount), 0)
  )
  FROM public.branch_cash_counter
  WHERE branch_id = p_branch_id
    AND (p_from IS NULL OR created_at >= p_from)
    AND (p_to IS NULL OR created_at < p_to)
    AND (p_total_sale IS NULL OR total_sale = p_total_sale);
$$;

GRANT EXECUTE ON FUNCTION public.branch_cash_counter_stats(uuid, timestamptz, timestamptz, numeric)
  TO authenticated;

NOTIFY pgrst, 'reload schema';
