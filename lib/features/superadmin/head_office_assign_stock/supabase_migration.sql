-- ============================================================
-- Head Office → "Assign Stock to Branch"
-- Warehouse wala hi flow, bas source head office ka stock_inventory hai
-- (warehouse_stock_inventory nahi) aur record par head_office_id save hota hai.
--
-- Ye same table `assign_stock_to_branch` reuse karta hai taake branch ki
-- "Assign Stock to My Branch" screen bina kisi change ke accept/reject kar sake.
-- ============================================================

-- 1. warehouse_id ab optional (head office assignments par NULL hota hai)
ALTER TABLE public.assign_stock_to_branch
  ALTER COLUMN warehouse_id DROP NOT NULL;

-- 2. head_office_id column
ALTER TABLE public.assign_stock_to_branch
  ADD COLUMN IF NOT EXISTS head_office_id UUID REFERENCES public.head_offices(id);

CREATE INDEX IF NOT EXISTS idx_astb_head_office_id
  ON public.assign_stock_to_branch(head_office_id);

-- 3. Reject RPC: agar assignment head office se aayi hai to stock wapas
--    public.stock_inventory mein, warna purana warehouse behaviour.
CREATE OR REPLACE FUNCTION public.reject_stock_assignment(p_assignment_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_item           RECORD;
  v_head_office_id UUID;
BEGIN
  SELECT head_office_id INTO v_head_office_id
  FROM public.assign_stock_to_branch
  WHERE id = p_assignment_id AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Assignment not found or not pending: %', p_assignment_id;
  END IF;

  FOR v_item IN
    SELECT stock_id, quantity
    FROM public.assign_stock_to_branch_items
    WHERE assignment_id = p_assignment_id
  LOOP
    IF v_head_office_id IS NOT NULL THEN
      UPDATE public.stock_inventory
      SET quantity   = quantity + v_item.quantity,
          updated_at = now()
      WHERE id = v_item.stock_id;
    ELSE
      UPDATE public.warehouse_stock_inventory
      SET quantity   = quantity + v_item.quantity,
          updated_at = now()
      WHERE id = v_item.stock_id;

      UPDATE public.branch_stock_inventory
      SET quantity   = quantity + v_item.quantity,
          updated_at = now()
      WHERE id = v_item.stock_id;
    END IF;
  END LOOP;

  UPDATE public.assign_stock_to_branch
  SET status = 'rejected'
  WHERE id = p_assignment_id;
END;
$function$;

-- 4. Sirf ek hi head office allowed hai — constant expression par unique index.
--    Har row ke liye value (1) same hoti hai, is liye doosri row insert nahi hoti.
CREATE UNIQUE INDEX IF NOT EXISTS head_offices_singleton
  ON public.head_offices ((1));

-- accept_stock_assignment ko change ki zaroorat nahi:
-- wo sirf branch_stock_inventory mein items daalta hai + status accepted karta hai.
-- Head office stock ki kami (pending par) Dart datasource khud handle karta hai,
-- bilkul warehouse flow ki tarah.

NOTIFY pgrst, 'reload schema';
