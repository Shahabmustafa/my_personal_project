-- Loyalty points sale par milte hain aur sale return par wapas kat'te hain.
-- Net khareedari (invoices - returns) Rs 10,000 tak pohnchne par activate,
-- phir Rs 100 = 1 point. Net 10,000 se neeche girne par points hat jate hain.
-- Walk-in customer ko points nahi. Sab kuch usi transaction mein hota hai.
-- Ye migration loyalty_on_sale_migration.sql ko replace karti hai (net based).
-- Loyalty rule ek jagah: net khareedari >= Rs 10,000 par floor(net / 100) points.
-- Rate/threshold badalna ho to sirf yahi function badlein.
CREATE OR REPLACE FUNCTION public.loyalty_points_for(p_net numeric)
RETURNS int LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE WHEN COALESCE(p_net, 0) >= 10000
              THEN floor(p_net / 100)::int ELSE 0 END;
$$;

-- Customer ki net khareedari = sab sale invoices - sab sale returns.
CREATE OR REPLACE FUNCTION public.customer_net_purchases(p_customer uuid)
RETURNS numeric LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp AS $$
  SELECT COALESCE((SELECT SUM(total_amount) FROM public.sale_invoices
                    WHERE customer_id = p_customer), 0)
       - COALESCE((SELECT SUM(total_amount) FROM public.sale_returns
                    WHERE customer_id = p_customer), 0);
$$;

-- Sale return save hone par points wapas (net kam hone par). SECURITY DEFINER
-- taake doosri branch ke customer ka return bhi RLS se na ruke.
CREATE OR REPLACE FUNCTION public.reverse_loyalty_on_return()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp AS $$
DECLARE
  v_after numeric;
  v_delta int;
BEGIN
  IF NEW.customer_id IS NULL THEN RETURN NEW; END IF;
  v_after := public.customer_net_purchases(NEW.customer_id);
  v_delta := public.loyalty_points_for(v_after)
           - public.loyalty_points_for(v_after + COALESCE(NEW.total_amount, 0));
  IF v_delta < 0 THEN
    UPDATE public.customers
       SET loyalty_points = GREATEST(0, COALESCE(loyalty_points, 0) + v_delta)
     WHERE id = NEW.customer_id AND COALESCE(is_walkin, false) = false;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_reverse_loyalty_on_return ON public.sale_returns;
CREATE TRIGGER trg_reverse_loyalty_on_return
AFTER INSERT ON public.sale_returns
FOR EACH ROW EXECUTE FUNCTION public.reverse_loyalty_on_return();

CREATE OR REPLACE FUNCTION public.save_sale_invoice(
  p_invoice  jsonb,
  p_items    jsonb,
  p_payments jsonb
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_inv public.sale_invoices;
  v_after numeric;
  v_before numeric;
  v_points int;
BEGIN
  INSERT INTO public.sale_invoices (
    invoice_number, branch_id, printer_id, cashier_id, customer_id,
    salesman_id, manager_id, subtotal, total_discount, invoice_discount,
    total_amount, salesman_commission_percent, salesman_commission_amount,
    manager_commission_percent, manager_commission_amount, note
  )
  SELECT r.invoice_number, r.branch_id, r.printer_id, r.cashier_id,
         r.customer_id, r.salesman_id, r.manager_id, r.subtotal,
         r.total_discount, COALESCE(r.invoice_discount, 0), r.total_amount,
         r.salesman_commission_percent, r.salesman_commission_amount,
         r.manager_commission_percent, r.manager_commission_amount, r.note
  FROM jsonb_to_record(p_invoice) AS r(
    invoice_number text, branch_id uuid, printer_id uuid, cashier_id uuid,
    customer_id uuid, salesman_id uuid, manager_id uuid, subtotal numeric,
    total_discount numeric, invoice_discount numeric, total_amount numeric,
    salesman_commission_percent numeric, salesman_commission_amount numeric,
    manager_commission_percent numeric, manager_commission_amount numeric,
    note text
  )
  RETURNING * INTO v_inv;

  INSERT INTO public.sale_invoice_items (
    sale_invoice_id, branch_id, branch_stock_id, product_id, size_id,
    color_id, brand_id, category_id, type_id, barcode, quantity, sale_price,
    purchase_price, discount_pct, discount, total_price, is_b1g1,
    b1g1_free_qty, b1g1_offer_id
  )
  SELECT v_inv.id, i.branch_id, i.branch_stock_id, i.product_id, i.size_id,
         i.color_id, i.brand_id, i.category_id, i.type_id, i.barcode,
         i.quantity, i.sale_price, i.purchase_price, i.discount_pct,
         i.discount, i.total_price, COALESCE(i.is_b1g1, false),
         COALESCE(i.b1g1_free_qty, 0), i.b1g1_offer_id
  FROM jsonb_to_recordset(p_items) AS i(
    branch_id uuid, branch_stock_id uuid, product_id uuid, size_id uuid,
    color_id uuid, brand_id uuid, category_id uuid, type_id uuid,
    barcode text, quantity int, sale_price numeric, purchase_price numeric,
    discount_pct numeric, discount numeric, total_price numeric,
    is_b1g1 boolean, b1g1_free_qty int, b1g1_offer_id uuid
  );

  INSERT INTO public.sale_invoice_payments (
    sale_invoice_id, branch_id, bank_entry_id, payment_type, amount
  )
  SELECT v_inv.id, p.branch_id, p.bank_entry_id, p.payment_type, p.amount
  FROM jsonb_to_recordset(p_payments) AS p(
    branch_id uuid, bank_entry_id uuid, payment_type text, amount numeric
  );

  IF v_inv.customer_id IS NOT NULL THEN
    v_before := public.customer_net_purchases(v_inv.customer_id)
                - COALESCE(v_inv.total_amount, 0);
    v_after  := v_before + COALESCE(v_inv.total_amount, 0);
    v_points := public.loyalty_points_for(v_after)
              - public.loyalty_points_for(v_before);
    IF v_points > 0 THEN
      UPDATE public.customers
         SET loyalty_points = COALESCE(loyalty_points, 0) + v_points
       WHERE id = v_inv.customer_id
         AND COALESCE(is_walkin, false) = false;
    END IF;
  END IF;

  RETURN to_jsonb(v_inv);
END;
$$;

REVOKE ALL ON FUNCTION public.save_sale_invoice(jsonb, jsonb, jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.save_sale_invoice(jsonb, jsonb, jsonb) TO authenticated;
