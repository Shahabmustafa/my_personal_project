-- ─────────────────────────────────────────────────────────────────────────────
-- Stock Inventory "Low Stock" / "Out of Stock" buttons (head office + branch).
-- Dono stats functions ko optional p_level milta hai:
--   'low' -> quantity 1..4 (5 se kam),  'out' -> quantity 0,  NULL -> sab.
-- Cards ke totals usi filter par bante hain; low_count / out_count hamesha
-- poore stock ke hain (buttons par dikhte hain).
-- Signature badla hai, is liye purane functions drop kar ke dobara bane.
-- STATUS (2026-10-08): applied to LIVE database.
-- ─────────────────────────────────────────────────────────────────────────────

DROP FUNCTION IF EXISTS public.head_office_stock_stats();
DROP FUNCTION IF EXISTS public.branch_stock_stats(uuid);

CREATE FUNCTION public.head_office_stock_stats(p_level text DEFAULT NULL)
 RETURNS json
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  SELECT json_build_object(
    'total_skus',           COUNT(*) FILTER (WHERE m),
    'total_articles',       COUNT(DISTINCT s.product_id) FILTER (WHERE m),
    'total_qty',            COALESCE(SUM(s.quantity) FILTER (WHERE m), 0),
    'total_value',          COALESCE(SUM(s.quantity * p.sale_price) FILTER (WHERE m), 0),
    'total_purchase_value', COALESCE(SUM(s.quantity * p.purchase_price) FILTER (WHERE m), 0),
    'low_stock_count',      COUNT(*) FILTER (WHERE s.quantity <= 5),
    'low_count',            COUNT(*) FILTER (WHERE s.quantity BETWEEN 1 AND 4),
    'out_count',            COUNT(*) FILTER (WHERE s.quantity <= 0)
  )
  FROM public.stock_inventory s
  JOIN public.products p ON p.id = s.product_id
  CROSS JOIN LATERAL (SELECT CASE p_level
    WHEN 'low' THEN s.quantity BETWEEN 1 AND 4
    WHEN 'out' THEN s.quantity <= 0
    ELSE true END AS m) f;
$function$;

CREATE FUNCTION public.branch_stock_stats(p_branch_id uuid, p_level text DEFAULT NULL)
 RETURNS json
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  SELECT json_build_object(
    'total_skus',      COUNT(*) FILTER (WHERE m),
    'total_qty',       COALESCE(SUM(b.quantity) FILTER (WHERE m), 0),
    'total_value',     COALESCE(SUM(b.quantity * b.sale_price) FILTER (WHERE m), 0),
    'low_stock_count', COUNT(*) FILTER (WHERE b.quantity <= 5),
    'low_count',       COUNT(*) FILTER (WHERE b.quantity BETWEEN 1 AND 4),
    'out_count',       COUNT(*) FILTER (WHERE b.quantity <= 0)
  )
  FROM public.branch_stock_inventory b
  CROSS JOIN LATERAL (SELECT CASE p_level
    WHEN 'low' THEN b.quantity BETWEEN 1 AND 4
    WHEN 'out' THEN b.quantity <= 0
    ELSE true END AS m) f
  WHERE b.branch_id = p_branch_id;
$function$;

-- Purane grants jaise hi (anon ko direct grant nahi).
REVOKE ALL ON FUNCTION public.head_office_stock_stats(text) FROM anon, service_role;
REVOKE ALL ON FUNCTION public.branch_stock_stats(uuid, text) FROM anon, service_role;
GRANT EXECUTE ON FUNCTION public.head_office_stock_stats(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.branch_stock_stats(uuid, text) TO authenticated;
