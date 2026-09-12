-- ─────────────────────────────────────────────────────────────────────────────
-- MERGE head-office purchase tables into the shared warehouse purchase tables
--
-- Pehle head office ke purchase invoices/returns alag ho_purchase_invoices/
-- ho_purchase_invoice_items/ho_purchase_returns/ho_purchase_return_items
-- tables mein store hote thay. Ab warehouse aur head office dono ke purchase
-- records isi ek pair mein rehte hain — purchase_invoices/purchase_invoice_items
-- aur purchase_returns/purchase_return_items — head_office_id (nullable)
-- column se distinguish hote hain (warehouse_id bhi ab nullable hai, dono
-- mutually exclusive hain, CHECK constraint se enforce).
--
-- NOTE: Yeh migration Claude Code ke auto-mode safety classifier ne
-- "Cloud Storage Mass Delete" / destructive-schema-change flag kar diya
-- (DROP TABLE), isliye ise Supabase SQL Editor se manually apply kiya gaya
-- hai (agent khud apply nahi kar saka) — yeh file sirf documentation/source
-- control ke liye hai.
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.purchase_invoices
  ADD COLUMN IF NOT EXISTS head_office_id UUID REFERENCES public.head_offices(id) ON DELETE CASCADE,
  ALTER COLUMN warehouse_id DROP NOT NULL;

ALTER TABLE public.purchase_invoices
  DROP CONSTRAINT IF EXISTS purchase_invoices_source_check,
  ADD CONSTRAINT purchase_invoices_source_check
    CHECK ((warehouse_id IS NOT NULL) <> (head_office_id IS NOT NULL));

ALTER TABLE public.purchase_returns
  ADD COLUMN IF NOT EXISTS head_office_id UUID REFERENCES public.head_offices(id) ON DELETE CASCADE,
  ALTER COLUMN warehouse_id DROP NOT NULL;

ALTER TABLE public.purchase_returns
  DROP CONSTRAINT IF EXISTS purchase_returns_source_check,
  ADD CONSTRAINT purchase_returns_source_check
    CHECK ((warehouse_id IS NOT NULL) <> (head_office_id IS NOT NULL));

DROP TABLE IF EXISTS public.ho_purchase_invoice_items CASCADE;
DROP TABLE IF EXISTS public.ho_purchase_return_items CASCADE;
DROP TABLE IF EXISTS public.ho_purchase_invoices CASCADE;
DROP TABLE IF EXISTS public.ho_purchase_returns CASCADE;

NOTIFY pgrst, 'reload schema';
