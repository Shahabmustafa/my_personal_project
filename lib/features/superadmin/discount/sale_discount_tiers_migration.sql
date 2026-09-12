-- =============================================================================
-- SALE DISCOUNT TIERS (superadmin/admin → "Discount → Sale Discount Tiers")
--
-- Head office ke liye ek global sale-amount discount table — koi branch_id
-- nahi, sab branches ko turant milta hai. Jab kisi sale invoice ka items
-- total (invoice-wise discount lagne se pehle) kisi tier ke min_sale_amount
-- tak pohanch jaye, us tier ka discount (flat Rs. ya %) automatically
-- invoice ke total mein lag jata hai — cashier isko chhed nahi sakta. Jab
-- ek se zyada tiers qualify karein, sab se zyada min_sale_amount wali jeet
-- ti hai (stacking nahi hoti).
--
-- Sale Invoice provider isko [invoice_discount] column mein cashier ke
-- manual "Extra Discount %" ke sath combine karke save karta hai — koi
-- naya column sale_invoices par nahi chahiye tha.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.sale_discount_tiers (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  min_sale_amount   NUMERIC(14, 2) NOT NULL DEFAULT 0,
  discount_type     TEXT NOT NULL DEFAULT 'percent' CHECK (discount_type IN ('flat', 'percent')),
  discount_value    NUMERIC(14, 2) NOT NULL DEFAULT 0,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.sale_discount_tiers ENABLE ROW LEVEL SECURITY;

CREATE POLICY authenticated_full_access ON public.sale_discount_tiers
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

NOTIFY pgrst, 'reload schema';
