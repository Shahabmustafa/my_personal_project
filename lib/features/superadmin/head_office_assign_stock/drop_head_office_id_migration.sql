-- assign_stock_to_branch: head_office_id bhi hata diya — head office wali
-- assignments mein assigned_by = head office id hota hai.
-- reject_stock_assignment ab assigned_by ko head_offices mein dhoond kar
-- decide karta hai ke stock kis table mein wapas jaye.

CREATE OR REPLACE FUNCTION public.reject_stock_assignment(p_assignment_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_item           RECORD;
  v_assigned_by    UUID;
  v_from_head_office BOOLEAN;
BEGIN
  SELECT assigned_by INTO v_assigned_by
  FROM public.assign_stock_to_branch
  WHERE id = p_assignment_id AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Assignment not found or not pending: %', p_assignment_id;
  END IF;

  v_from_head_office := EXISTS (
    SELECT 1 FROM public.head_offices WHERE id = v_assigned_by
  );

  FOR v_item IN
    SELECT stock_id, quantity
    FROM public.assign_stock_to_branch_items
    WHERE assignment_id = p_assignment_id
  LOOP
    IF v_from_head_office THEN
      UPDATE public.stock_inventory
      SET quantity = quantity + v_item.quantity, updated_at = now()
      WHERE id = v_item.stock_id;
    ELSE
      UPDATE public.warehouse_stock_inventory
      SET quantity = quantity + v_item.quantity, updated_at = now()
      WHERE id = v_item.stock_id;

      UPDATE public.branch_stock_inventory
      SET quantity = quantity + v_item.quantity, updated_at = now()
      WHERE id = v_item.stock_id;
    END IF;
  END LOOP;

  UPDATE public.assign_stock_to_branch
  SET status = 'rejected'
  WHERE id = p_assignment_id;
END;
$function$;

DROP INDEX IF EXISTS public.idx_astb_head_office_id;
ALTER TABLE public.assign_stock_to_branch DROP COLUMN head_office_id;

NOTIFY pgrst, 'reload schema';
