-- =============================================
-- Invoice-wise discount permission (per branch)
-- Superadmin "Invoice Discount Access" screen se on/off hoti hai.
-- Jis branch ke liye false hai, us branch ki Sale Invoice screen par
-- discount field dikhta hi nahi.
-- =============================================
ALTER TABLE public.branches
  ADD COLUMN IF NOT EXISTS can_apply_invoice_discount BOOLEAN NOT NULL DEFAULT false;

NOTIFY pgrst, 'reload schema';
