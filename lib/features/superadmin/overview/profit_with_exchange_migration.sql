-- superadmin_dashboard_stats: today_profit mein exchange ka munafa bhi.
--   Profit = sale items ka munafa
--          − sale return items ka munafa
--          + exchange: (nayi di hui items ka munafa − wapas li hui items ka munafa)
--   Munafa = total_price − purchase_price × quantity. Expense/commission nahi katte.
CREATE OR REPLACE FUNCTION public.superadmin_dashboard_stats()
 RETURNS json
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  WITH today_profit AS (
    SELECT
      COALESCE((
        SELECT SUM(sii.total_price - sii.purchase_price * sii.quantity)
        FROM public.sale_invoice_items sii
        JOIN public.sale_invoices si ON si.id = sii.sale_invoice_id
        WHERE (si.created_at AT TIME ZONE 'Asia/Karachi')::date = (now() AT TIME ZONE 'Asia/Karachi')::date
      ), 0)
      -
      COALESCE((
        SELECT SUM(sri.total_price - sri.purchase_price * sri.quantity)
        FROM public.sale_return_items sri
        JOIN public.sale_returns sr ON sr.id = sri.sale_return_id
        WHERE (sr.created_at AT TIME ZONE 'Asia/Karachi')::date = (now() AT TIME ZONE 'Asia/Karachi')::date
      ), 0)
      +
      COALESCE((
        SELECT SUM(sxn.total_price - sxn.purchase_price * sxn.quantity)
        FROM public.sale_exchange_new_items sxn
        JOIN public.sale_exchanges sx ON sx.id = sxn.sale_exchange_id
        WHERE (sx.created_at AT TIME ZONE 'Asia/Karachi')::date = (now() AT TIME ZONE 'Asia/Karachi')::date
      ), 0)
      -
      COALESCE((
        SELECT SUM(sxr.total_price - sxr.purchase_price * sxr.quantity)
        FROM public.sale_exchange_return_items sxr
        JOIN public.sale_exchanges sx ON sx.id = sxr.sale_exchange_id
        WHERE (sx.created_at AT TIME ZONE 'Asia/Karachi')::date = (now() AT TIME ZONE 'Asia/Karachi')::date
      ), 0) AS p
  ),
  counts AS (
    SELECT
      (SELECT COUNT(*) FROM public.products) AS total_articles,
      (SELECT COUNT(*) FROM public.branches) AS total_branches,
      (SELECT COUNT(*) FROM public.warehouses) AS total_warehouses,
      (SELECT COALESCE(SUM(quantity), 0) FROM public.branch_stock_inventory) AS branch_stock_pairs
  ),
  weekly AS (
    SELECT json_agg(json_build_object('day', day, 'amount', amount) ORDER BY day) AS data
    FROM (
      SELECT gs::date AS day,
             COALESCE(SUM(si.total_amount), 0) AS amount
      FROM generate_series(
        ((now() AT TIME ZONE 'Asia/Karachi')::date - INTERVAL '6 days'),
        ((now() AT TIME ZONE 'Asia/Karachi')::date),
        INTERVAL '1 day'
      ) gs
      LEFT JOIN public.sale_invoices si
        ON (si.created_at AT TIME ZONE 'Asia/Karachi')::date = gs::date
      GROUP BY gs::date
    ) d
  ),
  top_article AS (
    SELECT json_build_object(
             'product_id', p.id,
             'article_name', p.article_name,
             'quantity', t.qty,
             'amount', t.amt
           ) AS data
    FROM (
      SELECT product_id, SUM(quantity) AS qty, SUM(total_price) AS amt
      FROM public.sale_invoice_items
      GROUP BY product_id
      ORDER BY SUM(quantity) DESC
      LIMIT 1
    ) t
    JOIN public.products p ON p.id = t.product_id
  )
  SELECT json_build_object(
    'today_profit',      (SELECT p FROM today_profit),
    'total_articles',    (SELECT total_articles FROM counts),
    'total_branches',    (SELECT total_branches FROM counts),
    'total_warehouses',  (SELECT total_warehouses FROM counts),
    'branch_stock_pairs',(SELECT branch_stock_pairs FROM counts),
    'weekly_sale',       COALESCE((SELECT data FROM weekly), '[]'::json),
    'top_article',       (SELECT data FROM top_article)
  );
$function$;
