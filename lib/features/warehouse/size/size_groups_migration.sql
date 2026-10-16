-- =============================================================================
-- SIZE GROUPS (Catalog → Sizes → "Size Groups")
--
-- Admin sizes ke groups banata hai, jaise "Gents = 6,7,8,9,10,11" ya
-- "Kids = 1,2,3,4,5". Add Stock Entry mein group chunne se us group ke
-- saare sizes grid mein aa jate hain — har size ki qty seedhi likhi jati hai.
-- STATUS (2026-10-16): applied to LIVE database.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.size_groups (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  size_ids    uuid[] NOT NULL DEFAULT '{}',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS size_groups_name_unique
  ON public.size_groups (lower(name));

ALTER TABLE public.size_groups ENABLE ROW LEVEL SECURITY;

CREATE POLICY authenticated_full_access ON public.size_groups
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.size_groups TO authenticated;

NOTIFY pgrst, 'reload schema';
