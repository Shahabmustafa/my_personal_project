-- ─────────────────────────────────────────────────────────────────────────────
-- 1. PRINTER HEADS
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.printer_heads (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name         TEXT NOT NULL,
  image_url    TEXT NOT NULL DEFAULT '',
  address      TEXT NOT NULL DEFAULT '',
  phone_number TEXT NOT NULL DEFAULT '',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.printer_heads TO authenticated;
ALTER TABLE public.printer_heads DISABLE ROW LEVEL SECURITY;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. ASSIGN PRINTER (branch ↔ printer head mapping)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.assign_printer (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id        UUID NOT NULL REFERENCES public.branches(id)       ON DELETE CASCADE,
  printer_head_id  UUID NOT NULL REFERENCES public.printer_heads(id)  ON DELETE CASCADE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.assign_printer TO authenticated;
ALTER TABLE public.assign_printer DISABLE ROW LEVEL SECURITY;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. STORAGE BUCKET (printer head images)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO storage.buckets (id, name, public)
VALUES ('printer-images', 'printer-images', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "printer-images public read"
ON storage.objects FOR SELECT
USING (bucket_id = 'printer-images');

CREATE POLICY "printer-images authenticated upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'printer-images');

CREATE POLICY "printer-images authenticated update"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'printer-images')
WITH CHECK (bucket_id = 'printer-images');

CREATE POLICY "printer-images authenticated delete"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'printer-images');

-- Reload schema cache
NOTIFY pgrst, 'reload schema';
