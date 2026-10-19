-- H1 Stage 2 TEST — migration + simulated cashier checks, aakhir mein ROLLBACK.
-- Supabase SQL Editor mein chalayein. "ROLLBACK_REPORT" wala error normal hai;
-- us ke neeche ka text parhein. Pehle rls_stage2_migration.sql ka poora text
-- is file ke upar paste karein (ya yeh file us ke baad chalayein), phir DO block.
-- Cashier ki id apni DB ke cashier se badal sakte hain.

DO $t$
DECLARE
  cashier uuid := '431ef597-2c92-40ec-9547-71b244157955';
  out text := '';
  n int; st record; b uuid; ob uuid; es uuid; before_s numeric; after_s numeric; res jsonb;
BEGIN
  SELECT branch_id INTO b FROM public.user_branches WHERE user_id=cashier LIMIT 1;
  SELECT id INTO ob FROM public.branches WHERE id <> b LIMIT 1;
  SELECT id, total_sales INTO es, before_s FROM public.employee_salary WHERE branch_id IS DISTINCT FROM b LIMIT 1;
  EXECUTE 'set local role authenticated';
  PERFORM set_config('request.jwt.claims', json_build_object('sub',cashier,'role','authenticated')::text, true);

  UPDATE public.branch_stock_inventory SET quantity = quantity WHERE branch_id = ob;
  GET DIAGNOSTICS n = ROW_COUNT; out := out || 'cashier tamper other-branch stock rows=' || n || E' (want 0)\n';
  UPDATE public.sale_invoices SET note = note WHERE branch_id = ob;
  GET DIAGNOSTICS n = ROW_COUNT; out := out || 'cashier tamper other-branch invoices rows=' || n || E' (want 0)\n';
  UPDATE public.branch_cash_counter SET total_amount = total_amount WHERE branch_id = ob;
  GET DIAGNOSTICS n = ROW_COUNT; out := out || 'cashier tamper other-branch cash counter rows=' || n || E' (want 0)\n';
  UPDATE public.employee_salary SET total_sales = total_sales;
  GET DIAGNOSTICS n = ROW_COUNT; out := out || 'cashier tamper salary rows=' || n || E' (want 0)\n';
  UPDATE public.branch_stock_inventory SET quantity = quantity WHERE branch_id = b;
  GET DIAGNOSTICS n = ROW_COUNT; out := out || 'cashier own-branch stock rows=' || n || E' (want >0)\n';
  SELECT count(*) INTO n FROM public.sale_invoices; out := out || 'cashier can read all invoices=' || n || E'\n';

  SELECT * INTO st FROM public.branch_stock_inventory WHERE branch_id=b AND quantity>2 LIMIT 1;
  BEGIN
    res := public.save_sale_invoice(
      jsonb_build_object('invoice_number','TEST-RLS2-ROLLBACK','branch_id',b,'cashier_id',cashier,'salesman_id',es,'subtotal',100,'total_discount',0,'invoice_discount',0,'total_amount',100,'salesman_commission_percent',0,'salesman_commission_amount',0,'manager_commission_percent',0,'manager_commission_amount',0),
      jsonb_build_array(jsonb_build_object('branch_id',b,'branch_stock_id',st.id,'product_id',st.product_id,'quantity',2,'sale_price',50,'purchase_price',20,'discount_pct',0,'discount',0,'total_price',100)),
      jsonb_build_array(jsonb_build_object('branch_id',b,'payment_type','cash','amount',100)));
    out := out || 'cashier sale OK' || E'\n';
  EXCEPTION WHEN OTHERS THEN out := out || 'cashier sale FAILED: ' || SQLERRM || E'\n'; END;

  EXECUTE 'reset role';
  SELECT total_sales INTO after_s FROM public.employee_salary WHERE id = es;
  out := out || 'other-branch salesman total_sales ' || before_s || ' -> ' || after_s || E' (want +100 via trigger)\n';
  RAISE EXCEPTION E'ROLLBACK_REPORT\n%', out;
END $t$;
