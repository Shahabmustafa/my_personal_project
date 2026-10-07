-- Supabase Realtime — in tables ke changes app ko live milte hain
-- (core/service/realtime/table_changes_provider.dart).
-- Sirf woh tables jahan ek user doosre ke kaam ka intezar karta hai.
ALTER PUBLICATION supabase_realtime ADD TABLE
  public.assign_stock_to_branch,
  public.sale_claims,
  public.branch_stock_returns,
  public.branch_return_to_warehouse,
  public.branch_payments;

-- Head office Stock Inventory screen — assign/purchase/return se quantity
-- badalte hi list live update (2026-10-05, applied to LIVE database).
ALTER PUBLICATION supabase_realtime ADD TABLE public.stock_inventory;

-- Assignment items alag insert hote hain (header ke baad), is liye branch
-- ko items ka event bhi chahiye warna list khaali items ke saath load hoti
-- (2026-10-06, applied to LIVE database).
ALTER PUBLICATION supabase_realtime ADD TABLE public.assign_stock_to_branch_items;

-- Branch sale/return/assign screens ka stock list — sale ke baad bina
-- refresh sahi quantity (2026-10-07, applied to LIVE database).
ALTER PUBLICATION supabase_realtime ADD TABLE public.branch_stock_inventory;

-- Warehouse stock screens + purchase/return/assign dropdowns — quantity live
-- update (2026-10-07, applied to LIVE database).
ALTER PUBLICATION supabase_realtime ADD TABLE public.warehouse_stock_inventory;
