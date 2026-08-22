-- ─────────────────────────────────────────────────────────────────────────────
-- 1. BANK HEADS
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.bank_heads (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bank_name   TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.bank_heads TO authenticated;
ALTER TABLE public.bank_heads DISABLE ROW LEVEL SECURITY;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. BANK ENTRIES
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.bank_entries (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bank_id          UUID NOT NULL REFERENCES public.bank_heads(id) ON DELETE CASCADE,
  branch_id        UUID NOT NULL REFERENCES public.branches(id)   ON DELETE CASCADE,
  account_number   TEXT NOT NULL DEFAULT '',
  opening_balance  NUMERIC(15, 2) NOT NULL DEFAULT 0,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.bank_entries TO authenticated;
ALTER TABLE public.bank_entries DISABLE ROW LEVEL SECURITY;

-- ─────────────────────────────────────────────────────────────────────────────
-- Agar table pehle se exist kare aur sirf account_number add karna ho:
-- ─────────────────────────────────────────────────────────────────────────────
-- ALTER TABLE public.bank_entries
--   ADD COLUMN IF NOT EXISTS account_number TEXT NOT NULL DEFAULT '';
