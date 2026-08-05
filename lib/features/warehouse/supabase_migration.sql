-- ============================================================
-- Warehouse Product Tables Migration (no warehouse_id)
-- ============================================================

-- 1. BRANDS
CREATE TABLE IF NOT EXISTS public.brands (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS brands_name_unique ON public.brands (lower(name));

-- 2. SIZES
CREATE TABLE IF NOT EXISTS public.sizes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  number     TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS sizes_number_unique ON public.sizes (lower(number));

-- 3. COLORS
CREATE TABLE IF NOT EXISTS public.colors (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS colors_name_unique ON public.colors (lower(name));

-- 4. CATEGORIES
CREATE TABLE IF NOT EXISTS public.categories (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS categories_name_unique ON public.categories (lower(name));

-- 5. TYPES
CREATE TABLE IF NOT EXISTS public.types (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS types_name_unique ON public.types (lower(name));

-- 6. PRODUCTS
CREATE TABLE IF NOT EXISTS public.products (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_name   TEXT NOT NULL,
  sale_price     NUMERIC(12,2) NOT NULL DEFAULT 0,
  purchase_price NUMERIC(12,2) NOT NULL DEFAULT 0,
  image_url      TEXT NOT NULL DEFAULT '',
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-update updated_at triggers
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER brands_updated_at BEFORE UPDATE ON public.brands
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER sizes_updated_at BEFORE UPDATE ON public.sizes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER colors_updated_at BEFORE UPDATE ON public.colors
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER categories_updated_at BEFORE UPDATE ON public.categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER types_updated_at BEFORE UPDATE ON public.types
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER products_updated_at BEFORE UPDATE ON public.products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Grants
GRANT SELECT, INSERT, UPDATE, DELETE ON public.brands TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.sizes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.colors TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.categories TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.types TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.products TO authenticated;
