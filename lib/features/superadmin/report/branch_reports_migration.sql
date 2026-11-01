-- ─────────────────────────────────────────────────────────────────────────────
-- STOCK REPORT (admin + branch Reports) — branch x brand x category ka
-- summary: articles, sizes (SKUs), pairs, value, low/out stock, discount aur
-- B1G1 wale SKUs. Row click par app us group ke articles khud laati hai.
-- Depends on: v_branch_stock, v_branch_stock_b1g1.
-- STATUS (2026-11-02): applied to LIVE database.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.branch_stock_group_report(p_branch_id UUID DEFAULT NULL)
RETURNS TABLE (
    branch_id UUID, branch_name TEXT,
    brand_id UUID, category_id UUID, brand_name TEXT, category_name TEXT,
    articles INT, skus INT, pairs BIGINT, stock_value NUMERIC,
    low_skus INT, out_skus INT, discount_skus INT, b1g1_skus INT)
LANGUAGE sql STABLE
SET search_path TO 'public'
AS $$
    SELECT s.branch_id, b.branch_name, s.brand_id, s.category_id,
           s.brand_name, s.category_name,
           count(DISTINCT s.product_id)::int,
           count(*)::int,
           COALESCE(sum(s.quantity), 0)::bigint,
           COALESCE(sum(s.quantity * s.sale_price), 0),
           (count(*) FILTER (WHERE s.quantity >= 1 AND s.quantity < 5))::int,
           (count(*) FILTER (WHERE s.quantity <= 0))::int,
           (count(*) FILTER (WHERE s.discount > 0))::int,
           (count(*) FILTER (WHERE x.id IS NOT NULL))::int
    FROM public.v_branch_stock s
    JOIN public.branches b ON b.id = s.branch_id
    LEFT JOIN public.v_branch_stock_b1g1 x ON x.id = s.id
    WHERE p_branch_id IS NULL OR s.branch_id = p_branch_id
    GROUP BY s.branch_id, b.branch_name, s.brand_id, s.category_id,
             s.brand_name, s.category_name
    ORDER BY b.branch_name, s.brand_name, s.category_name;
$$;
GRANT EXECUTE ON FUNCTION public.branch_stock_group_report(UUID) TO authenticated;
NOTIFY pgrst, 'reload schema';
