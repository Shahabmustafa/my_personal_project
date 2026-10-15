-- =============================================================================
-- BUY 1 GET 1 FREE (superadmin/admin → "Discount → Buy 1 Get 1")
--
-- Admin offer banata hai aur chunta hai ke kin Articles / Brands / Categories
-- par lagega (koi bhi ek match ho jaye to item offer mein). Sab branches par
-- ek sath lagta hai. Sale Invoice mein offer wale har 2 pairs mein se sasta
-- wala free hota hai (us unit par 100% discount).
--
-- Rules:
--   * B1G1 lagi invoice par koi aur discount (tier / extra %) nahi lagta.
--   * Offer wale items (paid + free dono) return/exchange nahi ho sakte —
--     sale_invoice_items.is_b1g1 se pehchane jate hain.
-- STATUS (2026-10-14): applied to LIVE database.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.b1g1_offers (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  product_ids   uuid[] NOT NULL DEFAULT '{}',
  brand_ids     uuid[] NOT NULL DEFAULT '{}',
  category_ids  uuid[] NOT NULL DEFAULT '{}',
  start_date    DATE,
  end_date      DATE,
  is_active     BOOLEAN NOT NULL DEFAULT true,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.b1g1_offers ENABLE ROW LEVEL SECURITY;

CREATE POLICY authenticated_full_access ON public.b1g1_offers
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.b1g1_offers TO authenticated;

-- Realtime — admin offer badle to khule Sale Invoice screens foran naya
-- offer use karein.
ALTER PUBLICATION supabase_realtime ADD TABLE public.b1g1_offers;

-- Invoice line par offer ka record.
ALTER TABLE public.sale_invoice_items
  ADD COLUMN IF NOT EXISTS is_b1g1       BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS b1g1_free_qty INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS b1g1_offer_id uuid REFERENCES public.b1g1_offers(id) ON DELETE SET NULL;

-- Article ka khaas variant (size / color / brand / category / type) —
-- "productId|sizeId|colorId|brandId|categoryId|typeId".
-- STATUS (2026-10-15): applied to LIVE database.
ALTER TABLE public.b1g1_offers
  ADD COLUMN IF NOT EXISTS variant_keys TEXT[] NOT NULL DEFAULT '{}';

NOTIFY pgrst, 'reload schema';
