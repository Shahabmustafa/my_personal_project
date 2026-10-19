-- Branch stock accept par duplicate rows ka masla.
--
-- Branch-to-branch transfer / return mein item ka stock_id bhejne wali branch
-- ki apni inventory row ki id hoti hai, jabke receiving branch ki purani row ka
-- stock_id asli (warehouse / head office) stock ki id hai. Isi liye
-- ON CONFLICT (branch_id, stock_id) match nahi karta tha aur accept par wohi
-- product (same barcode, naam, size, color ...) ki doosri row ban jati thi.
--
-- Ab accept par pehle product ki pehchan se match hota hai:
--   branch + barcode + product + size + color + brand + category + type
-- Mil jaye to purani row ki quantity mein assign quantity jud jati hai,
-- warna nayi row banti hai. (Barcode pehchan mein shamil hai taake barcode
-- scan se bikri ke liye har barcode ki apni row rahe.)

CREATE OR REPLACE FUNCTION public.add_branch_stock_merged(
  p_branch_id      uuid,
  p_stock_id       uuid,
  p_barcode        text,
  p_product_id     uuid,
  p_size_id        uuid,
  p_color_id       uuid,
  p_brand_id       uuid,
  p_category_id    uuid,
  p_type_id        uuid,
  p_quantity       integer,
  p_sale_price     numeric,
  p_purchase_price numeric,
  p_discount       numeric
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_id uuid;
BEGIN
  -- Ek hi product par do accepts ek saath aayein to row do dafa na bane.
  PERFORM pg_advisory_xact_lock(hashtextextended(
    p_branch_id::text || '|' || p_barcode || '|' || p_product_id::text, 0));

  SELECT id INTO v_id
  FROM public.branch_stock_inventory
  WHERE branch_id   = p_branch_id
    AND barcode     = p_barcode
    AND product_id  = p_product_id
    AND size_id     IS NOT DISTINCT FROM p_size_id
    AND color_id    IS NOT DISTINCT FROM p_color_id
    AND brand_id    IS NOT DISTINCT FROM p_brand_id
    AND category_id IS NOT DISTINCT FROM p_category_id
    AND type_id     IS NOT DISTINCT FROM p_type_id
  ORDER BY created_at, id
  LIMIT 1
  FOR UPDATE;

  IF FOUND THEN
    UPDATE public.branch_stock_inventory
    SET quantity   = quantity + p_quantity,
        discount   = p_discount,
        updated_at = now()
    WHERE id = v_id;
  ELSE
    INSERT INTO public.branch_stock_inventory (
      branch_id, stock_id, barcode,
      product_id, size_id, color_id, brand_id, category_id, type_id,
      quantity, sale_price, purchase_price, discount
    ) VALUES (
      p_branch_id, p_stock_id, p_barcode,
      p_product_id, p_size_id, p_color_id, p_brand_id, p_category_id, p_type_id,
      p_quantity, p_sale_price, p_purchase_price, p_discount
    )
    ON CONFLICT (branch_id, stock_id)
    DO UPDATE SET
      quantity   = branch_stock_inventory.quantity + EXCLUDED.quantity,
      discount   = EXCLUDED.discount,
      updated_at = now();
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.add_branch_stock_merged(uuid, uuid, text, uuid, uuid, uuid, uuid, uuid, uuid, integer, numeric, numeric, numeric)
  FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.accept_stock_assignment(p_assignment_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
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
    PERFORM public.add_branch_stock_merged(
      v_branch_id, v_item.stock_id, v_item.barcode,
      v_item.product_id, v_item.size_id, v_item.color_id,
      v_item.brand_id, v_item.category_id, v_item.type_id,
      v_item.quantity, v_item.sale_price, v_item.purchase_price, v_item.discount
    );
  END LOOP;

  UPDATE public.assign_stock_to_branch
  SET status      = 'accepted',
      accepted_at = now()
  WHERE id = p_assignment_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.accept_branch_stock_return(p_return_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_to_branch UUID;
  v_item      RECORD;
BEGIN
  SELECT to_branch_id INTO v_to_branch
  FROM public.branch_stock_returns
  WHERE id = p_return_id AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Return not found or not pending: %', p_return_id;
  END IF;

  FOR v_item IN
    SELECT * FROM public.branch_stock_return_items WHERE return_id = p_return_id
  LOOP
    PERFORM public.add_branch_stock_merged(
      v_to_branch, v_item.stock_id, v_item.barcode,
      v_item.product_id, v_item.size_id, v_item.color_id,
      v_item.brand_id, v_item.category_id, v_item.type_id,
      v_item.quantity, v_item.sale_price, v_item.purchase_price, v_item.discount
    );
  END LOOP;

  UPDATE public.branch_stock_returns
  SET status = 'accepted', accepted_at = now()
  WHERE id = p_return_id;
END;
$$;
