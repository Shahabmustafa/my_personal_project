-- ─────────────────────────────────────────────────────────────────────────────
-- head_office_stock_stats(): Stock Inventory screen ke summary cards ke liye
-- do naye keys — total_articles (alag products ki ginti) aur
-- total_purchase_value (quantity × purchase_price). Purane keys same hain.
-- STATUS (2026-10-05): applied to LIVE database.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.head_office_stock_stats()
 RETURNS json
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  SELECT json_build_object(
    'total_skus',           COUNT(*),
    'total_articles',       COUNT(DISTINCT s.product_id),
    'total_qty',            COALESCE(SUM(s.quantity), 0),
    'total_value',          COALESCE(SUM(s.quantity * p.sale_price), 0),
    'total_purchase_value', COALESCE(SUM(s.quantity * p.purchase_price), 0),
    'low_stock_count',      COUNT(*) FILTER (WHERE s.quantity <= 5)
  )
  FROM public.stock_inventory s
  JOIN public.products p ON p.id = s.product_id;
$function$;
