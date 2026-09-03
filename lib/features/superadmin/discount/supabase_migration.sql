-- =============================================================================
-- DISCOUNT feature (superadmin → "Discount" group)
--
-- 1) Branch Invoice Discount
--    Per-branch max percentage jo cashier sale invoice par invoice-wise
--    (extra) discount ke taur par laga sakta hai. Superadmin
--    "Discount → Branch Invoice Discount" screen se set karta hai.
--    0  = branch koi invoice discount nahi laga sakta.
--
-- 2) Branch Stock Discount
--    Per-article discount % already `branch_stock_inventory.discount` column
--    mein hai (discount_rename_migration.sql se). Yahan sirf superadmin ko
--    us column ko har branch ke liye edit karne ki screen di gayi hai —
--    koi naya column nahi chahiye.
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
