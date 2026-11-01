-- ─────────────────────────────────────────────────────────────────────────────
-- v_branch_stock_b1g1 — branch stock ke sirf wo variants jo aaj chalte
-- Buy 1 Get 1 Free offer mein hain (offer active, aaj start/end ke andar, us
-- branch par lagta ho; article / variant / brand / category mein se koi match).
-- Columns v_branch_stock jaise hi — "Buy 1 Get 1 Stock" screen yahan se padhti
-- hai. Variant key = product|size|color|brand|category|type (app jaisa).
-- STATUS (2026-11-02): applied to LIVE database.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.v_branch_stock_b1g1
WITH (security_invoker = true) AS
SELECT s.*
FROM public.v_branch_stock s
WHERE EXISTS (
    SELECT 1
    FROM public.b1g1_offers o
    WHERE o.is_active
      AND (o.start_date IS NULL
           OR o.start_date <= (now() AT TIME ZONE 'Asia/Karachi')::date)
      AND (o.end_date IS NULL
           OR o.end_date >= (now() AT TIME ZONE 'Asia/Karachi')::date)
      AND (COALESCE(cardinality(o.branch_ids), 0) = 0
           OR s.branch_id = ANY (o.branch_ids))
      AND (s.product_id = ANY (o.product_ids)
           OR s.brand_id = ANY (o.brand_ids)
           OR s.category_id = ANY (o.category_ids)
           OR concat_ws('|', s.product_id, COALESCE(s.size_id::text, ''),
                        COALESCE(s.color_id::text, ''), COALESCE(s.brand_id::text, ''),
                        COALESCE(s.category_id::text, ''), COALESCE(s.type_id::text, ''))
              = ANY (o.variant_keys))
);

GRANT SELECT ON public.v_branch_stock_b1g1 TO authenticated;
NOTIFY pgrst, 'reload schema';
