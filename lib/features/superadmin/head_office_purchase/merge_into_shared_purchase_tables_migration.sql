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
-- purchase_invoice_items.stock_id / purchase_return_items.stock_id ab EITHER
-- warehouse_stock_inventory (warehouse purchases) OR stock_inventory
-- (head-office purchases) ko point kar sakta hai — isliye stock_id ka FK
-- constraint drop kar diya gaya hai (ek column do tables ko reference nahi
-- kar sakta); referential integrity app-level par handled hai.
--
-- STATUS (2026-09-17): Sab steps neeche apply ho chuke hain LIVE database par
-- (columns added, constraints updated, purani 5 ho_purchase_invoices / 7
-- ho_purchase_invoice_items ka data naye numbers Pur-000023..027 ke sath
-- merge ho chuka hai). Sirf DROP TABLE wala aakhri step baqi hai — Claude
-- Code ke auto-mode safety classifier ne ise "Cloud Storage Mass Delete"
-- flag kar diya (agent khud apply nahi kar saka), isliye ye purani (ab khali
-- pade) tables abhi bhi maujood hain aur inhe Supabase SQL Editor se manually
-- drop karna hoga.
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

ALTER TABLE public.purchase_invoice_items
  DROP CONSTRAINT IF EXISTS purchase_invoice_items_stock_id_fkey;

ALTER TABLE public.purchase_return_items
  DROP CONSTRAINT IF EXISTS purchase_return_items_stock_id_fkey;

-- Data migration (already applied — kept here for reference/history only):
--
-- WITH renumbered AS (
--   SELECT id,
--          'Pur-' || LPAD((22 + ROW_NUMBER() OVER (ORDER BY created_at))::text, 6, '0') AS new_number
--   FROM public.ho_purchase_invoices
-- )
-- INSERT INTO public.purchase_invoices (
--   id, invoice_number, company_id, head_office_id, invoice_date,
--   total_amount, total_discount, net_amount, paid_amount, credit_amount,
--   payment_mode, notes, created_at, updated_at
-- )
-- SELECT
--   h.id, r.new_number, h.company_id, (SELECT id FROM public.head_offices LIMIT 1), h.invoice_date,
--   h.total_amount, h.total_discount, h.net_amount, h.paid_amount, h.credit_amount,
--   h.payment_mode, h.notes, h.created_at, h.updated_at
-- FROM public.ho_purchase_invoices h
-- JOIN renumbered r ON r.id = h.id;
--
-- INSERT INTO public.purchase_invoice_items (
--   id, purchase_invoice_id, stock_id, barcode, product_id, size_id, color_id,
--   brand_id, category_id, type_id, quantity, sale_price, purchase_price,
--   discount_pct, discount_amount, net_price, line_total, created_at
-- )
-- SELECT
--   id, purchase_invoice_id, stock_id, barcode, product_id, size_id, color_id,
--   brand_id, category_id, type_id, quantity, sale_price, purchase_price,
--   discount_pct, discount_amount, net_price, line_total, created_at
-- FROM public.ho_purchase_invoice_items;

-- ── STILL TO RUN MANUALLY (Supabase SQL Editor) ────────────────────────────
DROP TABLE IF EXISTS public.ho_purchase_invoice_items CASCADE;
DROP TABLE IF EXISTS public.ho_purchase_return_items CASCADE;
DROP TABLE IF EXISTS public.ho_purchase_invoices CASCADE;
DROP TABLE IF EXISTS public.ho_purchase_returns CASCADE;

NOTIFY pgrst, 'reload schema';
