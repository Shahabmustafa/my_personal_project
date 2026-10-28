-- Sale Summary: server-side totals + pagination.
--
--   * sale_summary_totals: top cards ke totals sale_invoices / sale_returns /
--     sale_exchanges par SUM/COUNT se (rows client tak fetch nahi hoti).
--   * sale_summary_page: teeno tables ki combined list (newest first), sirf
--     ek page. Har table se pehle p_offset + p_limit rows hi lete hain
--     (idx_*_created_at / branch_created indexes), phir union ko sort karke
--     page kaat te hain.
--   p_start inclusive, p_end exclusive (UTC instants); null = unbounded,
--   p_branch null = All Branches.

CREATE INDEX IF NOT EXISTS idx_sale_invoices_created_at ON public.sale_invoices (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sale_returns_created_at ON public.sale_returns (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sale_exchanges_created_at ON public.sale_exchanges (created_at DESC);

CREATE OR REPLACE FUNCTION public.sale_summary_totals(
  p_start  timestamptz DEFAULT NULL,
  p_end    timestamptz DEFAULT NULL,
  p_branch uuid        DEFAULT NULL
) RETURNS json
LANGUAGE sql STABLE
SET search_path = public
AS $$
  SELECT json_build_object(
    'total_sale',   COALESCE((SELECT sum(total_amount) FROM sale_invoices
                              WHERE (p_start IS NULL OR created_at >= p_start)
                                AND (p_end IS NULL OR created_at < p_end)
                                AND (p_branch IS NULL OR branch_id = p_branch)), 0),
    'invoice_count', (SELECT count(*) FROM sale_invoices
                      WHERE (p_start IS NULL OR created_at >= p_start)
                        AND (p_end IS NULL OR created_at < p_end)
                        AND (p_branch IS NULL OR branch_id = p_branch)),
    'total_return', COALESCE((SELECT sum(total_amount) FROM sale_returns
                              WHERE (p_start IS NULL OR created_at >= p_start)
                                AND (p_end IS NULL OR created_at < p_end)
                                AND (p_branch IS NULL OR branch_id = p_branch)), 0),
    'return_count', (SELECT count(*) FROM sale_returns
                     WHERE (p_start IS NULL OR created_at >= p_start)
                       AND (p_end IS NULL OR created_at < p_end)
                       AND (p_branch IS NULL OR branch_id = p_branch)),
    'exchange_change',   x.change,
    'exchange_received', x.received,
    'exchange_refunded', x.refunded,
    'exchange_count',    x.cnt
  )
  FROM (
    SELECT COALESCE(sum(difference_amount), 0)                                         AS change,
           COALESCE(sum(difference_amount) FILTER (WHERE difference_amount > 0), 0)    AS received,
           COALESCE(-sum(difference_amount) FILTER (WHERE difference_amount < 0), 0)   AS refunded,
           count(*)                                                                    AS cnt
    FROM sale_exchanges
    WHERE (p_start IS NULL OR created_at >= p_start)
      AND (p_end IS NULL OR created_at < p_end)
      AND (p_branch IS NULL OR branch_id = p_branch)
  ) x;
$$;

CREATE OR REPLACE FUNCTION public.sale_summary_page(
  p_start  timestamptz DEFAULT NULL,
  p_end    timestamptz DEFAULT NULL,
  p_branch uuid        DEFAULT NULL,
  p_limit  int         DEFAULT 20,
  p_offset int         DEFAULT 0
) RETURNS json
LANGUAGE sql STABLE
SET search_path = public
AS $$
  SELECT COALESCE(json_agg(t ORDER BY t.created_at DESC, t.id), '[]'::json)
  FROM (
    SELECT u.type, u.id, u.number, u.created_at, u.amount,
           b.branch_name, c.name AS customer_name
    FROM (
      (SELECT 'sale'::text AS type, i.id, i.invoice_number AS number, i.created_at,
              i.total_amount AS amount, i.branch_id, i.customer_id
       FROM sale_invoices i
       WHERE (p_start IS NULL OR i.created_at >= p_start)
         AND (p_end IS NULL OR i.created_at < p_end)
         AND (p_branch IS NULL OR i.branch_id = p_branch)
       ORDER BY i.created_at DESC, i.id LIMIT p_offset + p_limit)
      UNION ALL
      (SELECT 'return'::text, r.id, r.return_number, r.created_at,
              -r.total_amount, r.branch_id, r.customer_id
       FROM sale_returns r
       WHERE (p_start IS NULL OR r.created_at >= p_start)
         AND (p_end IS NULL OR r.created_at < p_end)
         AND (p_branch IS NULL OR r.branch_id = p_branch)
       ORDER BY r.created_at DESC, r.id LIMIT p_offset + p_limit)
      UNION ALL
      (SELECT 'exchange'::text, x.id, x.exchange_number, x.created_at,
              x.difference_amount, x.branch_id, x.customer_id
       FROM sale_exchanges x
       WHERE (p_start IS NULL OR x.created_at >= p_start)
         AND (p_end IS NULL OR x.created_at < p_end)
         AND (p_branch IS NULL OR x.branch_id = p_branch)
       ORDER BY x.created_at DESC, x.id LIMIT p_offset + p_limit)
    ) u
    LEFT JOIN branches  b ON b.id = u.branch_id
    LEFT JOIN customers c ON c.id = u.customer_id
    ORDER BY u.created_at DESC, u.id
    LIMIT p_limit OFFSET p_offset
  ) t;
$$;

GRANT EXECUTE ON FUNCTION public.sale_summary_totals(timestamptz, timestamptz, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.sale_summary_page(timestamptz, timestamptz, uuid, int, int) TO authenticated;

NOTIFY pgrst, 'reload schema';
