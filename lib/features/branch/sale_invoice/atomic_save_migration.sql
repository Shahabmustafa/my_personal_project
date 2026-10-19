-- Sale invoice + items + payments ek hi transaction mein (H2).
-- Kuch bhi fail ho to poora rollback — bina items wala invoice nahi rehta.
-- SECURITY INVOKER: RLS caller (authenticated user) par hi lagti hai.
CREATE OR REPLACE FUNCTION public.save_sale_invoice(
  p_invoice  jsonb,
  p_items    jsonb,
  p_payments jsonb
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_inv public.sale_invoices;
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

  RETURN to_jsonb(v_inv);
END;
$$;

REVOKE ALL ON FUNCTION public.save_sale_invoice(jsonb, jsonb, jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.save_sale_invoice(jsonb, jsonb, jsonb) TO authenticated;
