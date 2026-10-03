-- Branch dashboard weekly line graph: net sale = invoices - returns + exchange ka farq
-- (admin dashboard aur "Today Sale" card jaisa).
CREATE OR REPLACE FUNCTION public.branch_dashboard_stats(p_branch_id uuid)
 RETURNS json
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  WITH days AS (
    SELECT gs::date AS day
    FROM generate_series(
      ((now() AT TIME ZONE 'Asia/Karachi')::date - INTERVAL '6 days'),
      ((now() AT TIME ZONE 'Asia/Karachi')::date),
      INTERVAL '1 day'
    ) gs
  ),
  weekly AS (
    SELECT json_agg(json_build_object('day', d.day, 'amount',
      COALESCE((SELECT SUM(si.total_amount) FROM public.sale_invoices si
                WHERE si.branch_id = p_branch_id
                  AND (si.created_at AT TIME ZONE 'Asia/Karachi')::date = d.day), 0)
      - COALESCE((SELECT SUM(sr.total_amount) FROM public.sale_returns sr
                WHERE sr.branch_id = p_branch_id
                  AND (sr.created_at AT TIME ZONE 'Asia/Karachi')::date = d.day), 0)
      + COALESCE((SELECT SUM(se.difference_amount) FROM public.sale_exchanges se
                WHERE se.branch_id = p_branch_id
                  AND (se.created_at AT TIME ZONE 'Asia/Karachi')::date = d.day), 0)
    ) ORDER BY d.day) AS data
    FROM days d
  ),
  top_articles AS (
    SELECT COALESCE(json_agg(json_build_object(
             'product_id',   x.product_id,
             'article_name', p.article_name,
             'quantity',     x.qty,
             'amount',       x.amt
           ) ORDER BY x.qty DESC), '[]'::json) AS data
    FROM (
      SELECT product_id, SUM(quantity) AS qty, SUM(total_price) AS amt
      FROM public.sale_invoice_items
      WHERE branch_id = p_branch_id
      GROUP BY product_id
      ORDER BY SUM(quantity) DESC
      LIMIT 10
    ) x
    JOIN public.products p ON p.id = x.product_id
  )
  SELECT json_build_object(
    'weekly_sale',  COALESCE((SELECT data FROM weekly), '[]'::json),
    'top_articles', COALESCE((SELECT data FROM top_articles), '[]'::json)
  );
$function$;
