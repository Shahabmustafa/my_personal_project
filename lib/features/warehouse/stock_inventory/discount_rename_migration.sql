-- ─────────────────────────────────────────────────────────────────────────────
-- DISCOUNT: rename warehouse_stock_inventory.discount_pct → discount,
-- and add matching "discount" columns to branch_stock_inventory and
-- assign_stock_to_branch_items so the discount carries through the whole
-- warehouse → assign → branch flow.
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. warehouse_stock_inventory: rename discount_pct -> discount
ALTER TABLE public.warehouse_stock_inventory
RENAME COLUMN discount_pct TO discount;

-- 2. branch_stock_inventory: new discount column
ALTER TABLE public.branch_stock_inventory
ADD COLUMN IF NOT EXISTS discount NUMERIC(5, 2) DEFAULT 0.00;

-- 3. assign_stock_to_branch_items: new discount column
-- (carries the warehouse discount into the assignment line item; the app
-- now writes this column when saving an assignment)
ALTER TABLE public.assign_stock_to_branch_items
ADD COLUMN IF NOT EXISTS discount NUMERIC(5, 2) DEFAULT 0.00;

-- Reload schema cache
NOTIFY pgrst, 'reload schema';

-- ─────────────────────────────────────────────────────────────────────────────
-- ⚠️ MANUAL STEP REQUIRED
-- ─────────────────────────────────────────────────────────────────────────────
-- The RPC function `accept_stock_assignment` (called when a branch accepts a
-- pending assignment) is NOT tracked in this repo — it lives only in the live
-- Supabase database and was created directly via the SQL editor.
--
-- It currently reads columns from assign_stock_to_branch_items and inserts /
-- upserts rows into branch_stock_inventory. To make discount flow through to
-- the branch, it must also copy the new `discount` column from
-- assign_stock_to_branch_items into branch_stock_inventory.discount.
--
-- To let this be updated safely, run the following in the Supabase SQL editor
-- and share the output so the function body can be patched precisely:
--
--   SELECT pg_get_functiondef('accept_stock_assignment'::regproc);
--
-- Then add `discount` to whichever INSERT/UPDATE ... branch_stock_inventory
-- statement is inside it, taking the value from the corresponding
-- assign_stock_to_branch_items row.
