-- Head office Stock Inventory: Category / Type / Brand / Size dropdown filters.
-- head_office_stock_stats ko optional p_category_id / p_type_id / p_brand_id /
-- p_size_id milte hain, taake cards selected filters ke mutabiq badlein.
-- STATUS (2026-10-20): applied to LIVE database.

DROP FUNCTION IF EXISTS public.head_office_stock_stats(text);

CREATE FUNCTION public.head_office_stock_stats(
  p_level       text DEFAULT NULL,
  p_category_id uuid DEFAULT NULL,
  p_type_id     uuid DEFAULT NULL,
  p_brand_id    uuid DEFAULT NULL,
  p_size_id     uuid DEFAULT NULL)
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
  CROSS JOIN LATERAL (SELECT (CASE p_level
    WHEN 'low' THEN s.quantity BETWEEN 1 AND 4
    WHEN 'out' THEN s.quantity <= 0
    ELSE true END)
    AND (p_category_id IS NULL OR s.category_id = p_category_id)
    AND (p_type_id     IS NULL OR s.type_id     = p_type_id)
    AND (p_brand_id    IS NULL OR s.brand_id    = p_brand_id)
    AND (p_size_id     IS NULL OR s.size_id     = p_size_id) AS m) f;
$function$;

REVOKE ALL ON FUNCTION public.head_office_stock_stats(text, uuid, uuid, uuid, uuid) FROM anon, service_role;
GRANT EXECUTE ON FUNCTION public.head_office_stock_stats(text, uuid, uuid, uuid, uuid) TO authenticated;
