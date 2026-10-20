-- ─────────────────────────────────────────────────────────────────────────────
-- Branch Stock Inventory: Category / Type / Brand / Size dropdown filters.
-- branch_stock_stats ko optional p_category_id / p_type_id / p_brand_id /
-- p_size_id milte hain, taake Total Pairs aur Total Sale Price cards selected
-- filters ke mutabiq badlein. low_count / out_count poore stock ke rehte hain.
-- STATUS (2026-10-20): applied to LIVE database.
-- ─────────────────────────────────────────────────────────────────────────────

DROP FUNCTION IF EXISTS public.branch_stock_stats(uuid, text);

CREATE FUNCTION public.branch_stock_stats(
  p_branch_id   uuid,
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
    'total_skus',      COUNT(*) FILTER (WHERE m),
    'total_qty',       COALESCE(SUM(b.quantity) FILTER (WHERE m), 0),
    'total_value',     COALESCE(SUM(b.quantity * b.sale_price) FILTER (WHERE m), 0),
    'low_stock_count', COUNT(*) FILTER (WHERE b.quantity <= 5),
    'low_count',       COUNT(*) FILTER (WHERE b.quantity BETWEEN 1 AND 4),
    'out_count',       COUNT(*) FILTER (WHERE b.quantity <= 0)
  )
  FROM public.branch_stock_inventory b
  CROSS JOIN LATERAL (SELECT (CASE p_level
    WHEN 'low' THEN b.quantity BETWEEN 1 AND 4
    WHEN 'out' THEN b.quantity <= 0
    ELSE true END)
    AND (p_category_id IS NULL OR b.category_id = p_category_id)
    AND (p_type_id     IS NULL OR b.type_id     = p_type_id)
    AND (p_brand_id    IS NULL OR b.brand_id    = p_brand_id)
    AND (p_size_id     IS NULL OR b.size_id     = p_size_id) AS m) f
  WHERE b.branch_id = p_branch_id;
$function$;

REVOKE ALL ON FUNCTION public.branch_stock_stats(uuid, text, uuid, uuid, uuid, uuid) FROM anon, service_role;
GRANT EXECUTE ON FUNCTION public.branch_stock_stats(uuid, text, uuid, uuid, uuid, uuid) TO authenticated;
