-- ============================================================
-- HEAD OFFICES
-- Branch / Warehouse ki tarah CRUD table.
-- SuperAdmin add / edit / delete kar sakta hai.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.head_offices (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  head_office_name  TEXT NOT NULL,
  address           TEXT NOT NULL DEFAULT '',
  phone_number      TEXT NOT NULL DEFAULT '',
  city              TEXT NOT NULL DEFAULT '',
  status            TEXT NOT NULL DEFAULT 'active',
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS head_offices_updated_at ON public.head_offices;
CREATE TRIGGER head_offices_updated_at
  BEFORE UPDATE ON public.head_offices
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grants (RLS disabled, baaki project ki tarah)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.head_offices TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.head_offices TO anon;
ALTER TABLE public.head_offices DISABLE ROW LEVEL SECURITY;

-- ============================================================
-- USER <-> HEAD OFFICE assignment (user_branches / user_warehouses ki tarah)
-- Sirf superadmin users ko head office assign kiya jaata hai.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_head_offices (
  user_id         UUID NOT NULL REFERENCES public.users(id)         ON DELETE CASCADE,
  head_office_id  UUID NOT NULL REFERENCES public.head_offices(id)  ON DELETE CASCADE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, head_office_id)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_head_offices TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_head_offices TO anon;
ALTER TABLE public.user_head_offices DISABLE ROW LEVEL SECURITY;

NOTIFY pgrst, 'reload schema';
