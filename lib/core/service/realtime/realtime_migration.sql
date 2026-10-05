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
