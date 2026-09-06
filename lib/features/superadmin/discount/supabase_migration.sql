-- =============================================================================
-- DISCOUNT feature (superadmin → "Discount" group)
--
-- 1) Branch Invoice Discount
--    Per-branch max percentage jo cashier sale invoice par invoice-wise
--    (extra) discount ke taur par laga sakta hai. Superadmin
--    "Discount → Branch Invoice Discount" screen se set karta hai.
--    0  = branch koi invoice discount nahi laga sakta.
--
-- 2) Branch Stock Discount  — REMOVED (2026-09-07)
--    Per-article branch discount ab support nahi. Screen/provider/datasource
--    delete kar diye; sale invoice/return/exchange ab `stock.discount` ko
--    apply nahi karte (hamesha 0). `branch_stock_inventory.discount` column
--    chhor di gayi hai (kuch nahi parhta), aur mojood values ek dafa 0 kar
--    di gayi hain. Sirf Branch Invoice Discount reh gaya hai.
-- =============================================================================

-- 1. branches: max invoice-wise discount percentage per branch
ALTER TABLE public.branches
  ADD COLUMN IF NOT EXISTS max_invoice_discount_pct NUMERIC(5, 2) NOT NULL DEFAULT 0;

-- Purani boolean `can_apply_invoice_discount` = true wali branches ka
-- behaviour na toote — inko default 100% (jitna bhi) allow kar dete hain.
-- Superadmin baad mein screen se ghata sakta hai.
UPDATE public.branches
   SET max_invoice_discount_pct = 100
 WHERE can_apply_invoice_discount = TRUE
   AND max_invoice_discount_pct = 0;

-- App dono columns sync mein rakhti hai (pct > 0  ⇔  can_apply = true).

NOTIFY pgrst, 'reload schema';
