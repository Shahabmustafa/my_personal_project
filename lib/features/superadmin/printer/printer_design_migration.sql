-- ─────────────────────────────────────────────────────────────────────────────
-- Printer head receipt design (Sale Invoice / Exchange / Return header)
--   logo_position : left | center | right (name/phone/address same side)
--   show_*        : header ki cheezein on/off
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.printer_heads
  ADD COLUMN IF NOT EXISTS logo_position TEXT    NOT NULL DEFAULT 'center'
    CHECK (logo_position IN ('left', 'center', 'right')),
  ADD COLUMN IF NOT EXISTS show_logo     BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS show_name     BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS show_phone    BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS show_address  BOOLEAN NOT NULL DEFAULT TRUE;

-- ─────────────────────────────────────────────────────────────────────────────
-- Receipt ke baqi hisse on/off (doc no, date, customer, salesman, columns,
-- sub total, discount, payments, notes, thank-you text, extra note)
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.printer_heads
  ADD COLUMN IF NOT EXISTS receipt_options JSONB NOT NULL DEFAULT '{}'::jsonb;
