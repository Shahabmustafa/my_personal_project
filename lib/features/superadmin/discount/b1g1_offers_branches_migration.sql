-- B1G1 offers: kin branches par lagega. Khali array = sab branches.
-- STATUS (2026-11-01): applied to Supabase project "Testing" (jjqhglmaxlcrusmmxwgi).
ALTER TABLE public.b1g1_offers
  ADD COLUMN IF NOT EXISTS branch_ids uuid[] NOT NULL DEFAULT '{}';

NOTIFY pgrst, 'reload schema';
