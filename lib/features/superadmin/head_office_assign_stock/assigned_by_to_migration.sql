-- assign_stock_to_branch: warehouse_id / branch_id ki jagah assigned_by / assigned_to.
--   assigned_by = bhejne wala (head office / warehouse / branch ki id) — FK nahi,
--                 kyunki id teen alag tables ki ho sakti hai.
--   assigned_to = lene wali branch (branches.id FK).
-- head_office_id waisa hi rehta hai (reject_stock_assignment isi se head office
-- stock wapas karta hai).

UPDATE public.assign_stock_to_branch
   SET assigned_by = COALESCE(head_office_id, warehouse_id);
ALTER TABLE public.assign_stock_to_branch ALTER COLUMN assigned_by SET NOT NULL;

ALTER TABLE public.assign_stock_to_branch ADD COLUMN assigned_to uuid;
UPDATE public.assign_stock_to_branch SET assigned_to = branch_id;
ALTER TABLE public.assign_stock_to_branch
  ALTER COLUMN assigned_to SET NOT NULL,
  ADD CONSTRAINT assign_stock_to_branch_assigned_to_fkey
    FOREIGN KEY (assigned_to) REFERENCES public.branches(id);

DROP INDEX IF EXISTS public.idx_astb_wh_created;
DROP INDEX IF EXISTS public.idx_astb_branch_status;
ALTER TABLE public.assign_stock_to_branch
  DROP COLUMN warehouse_id,
  DROP COLUMN branch_id;

CREATE INDEX idx_astb_by_created
  ON public.assign_stock_to_branch (assigned_by, created_at DESC);
CREATE INDEX idx_astb_to_status
  ON public.assign_stock_to_branch (assigned_to, status);

-- accept: branch_id ki jagah assigned_to.
CREATE OR REPLACE FUNCTION public.accept_stock_assignment(p_assignment_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_branch_id UUID;
  v_item      RECORD;
BEGIN
  SELECT assigned_to INTO v_branch_id
  FROM public.assign_stock_to_branch
  WHERE id = p_assignment_id AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Assignment not found or not pending: %', p_assignment_id;
  END IF;

  FOR v_item IN
    SELECT * FROM public.assign_stock_to_branch_items
    WHERE assignment_id = p_assignment_id
  LOOP
    INSERT INTO public.branch_stock_inventory (
      branch_id, stock_id, barcode,
      product_id, size_id, color_id, brand_id, category_id, type_id,
      quantity, sale_price, purchase_price, discount
    )
    VALUES (
      v_branch_id, v_item.stock_id, v_item.barcode,
      v_item.product_id, v_item.size_id, v_item.color_id,
      v_item.brand_id, v_item.category_id, v_item.type_id,
      v_item.quantity, v_item.sale_price, v_item.purchase_price,
      v_item.discount
    )
    ON CONFLICT (branch_id, stock_id)
    DO UPDATE SET
      quantity   = branch_stock_inventory.quantity + EXCLUDED.quantity,
      discount   = EXCLUDED.discount,
      updated_at = now();
  END LOOP;

  UPDATE public.assign_stock_to_branch
  SET status      = 'accepted',
      accepted_at = now()
  WHERE id = p_assignment_id;
END;
$function$;

NOTIFY pgrst, 'reload schema';
