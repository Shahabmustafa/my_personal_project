# Purchase Invoice Feature

## Folder structure
```
purchase_invoice/
├── data/
│   ├── datasources/
│   │   ├── stock_datasource.dart          ← UPDATED (sale_price, discount_pct)
│   │   └── purchase_invoice_datasource.dart
│   ├── models/
│   │   ├── warehouse_stock_model.dart     ← UPDATED (sale_price, discount_pct)
│   │   └── purchase_invoice_model.dart    ← NEW
│   └── repositories/
│       ├── stock_repository.dart          ← UPDATED
│       └── purchase_invoice_repository.dart ← NEW
├── presentation/
│   ├── providers/
│   │   ├── stock_provider.dart            ← UPDATED
│   │   └── purchase_invoice_provider.dart ← NEW
│   ├── screens/
│   │   ├── purchase_invoice_screen.dart   ← NEW (create invoice)
│   │   └── purchase_invoices_list_screen.dart ← NEW (list invoices)
│   └── widgets/
│       ├── purchase_product_selector.dart ← NEW
│       └── purchase_cart_table.dart       ← NEW
└── purchase_invoice_migration.sql         ← Run this in Supabase
```

## Step 1: Run the SQL migration
Run `purchase_invoice_migration.sql` in your Supabase SQL editor.

This will:
- Add `sale_price` and `discount_pct` columns to `warehouse_stock_inventory`
- Create `purchase_invoices` table
- Create `purchase_invoice_items` table
- Create a Supabase function `generate_purchase_invoice_number()` for auto invoice numbers

## Step 2: Replace/update files

**Updated files (replace your existing ones):**
- `data/models/warehouse_stock_model.dart`
- `data/datasources/stock_datasource.dart`
- `data/repositories/stock_repository.dart`
- `presentation/providers/stock_provider.dart`

**New files (add to your project):**
- All files in `data/` and `presentation/` for `purchase_invoice_*`

## Step 3: Add routes/navigation

In your `WarehouseDashboard` sidebar, add two routes:

```dart
// In your sidebar nav items:
NavItem(
  icon: Icons.receipt_long,
  label: 'Purchase Invoice',
  screen: const PurchaseInvoiceScreen(),
),
NavItem(
  icon: Icons.list_alt,
  label: 'Invoice History',
  screen: const PurchaseInvoicesListScreen(),
),
```

## How it works

### Purchase Invoice Screen (`purchase_invoice_screen.dart`)

**Header row:**
- Invoice Number (auto-generated: PI-010001, PI-010002...)
- Company dropdown
- Date (today)
- Summary badges: Items count, Total Qty, Net Amount

**Product Selector (`purchase_product_selector.dart`):**
- **Barcode field**: Scan/type → auto-fills product, size, color, price, discount
- **Product dropdown**: Shows all products in warehouse stock
- **Size dropdown**: Only sizes available for selected product
- **Color dropdown**: Only colors available for selected product+size
- **S.Price**: Read-only, from stock record
- **T.Quantity**: Read-only, total available qty in warehouse (green=has stock, red=0)
- **Quantity**: Editable, defaults to 1
- **Discount**: Read-only, shows discount% and amount from stock record
- **Net Price**: Read-only, calculated (S.Price - Discount)
- **Add Product**: Adds to cart

**Cart Table (`purchase_cart_table.dart`):**
- All items listed with barcode, article, size, color
- Inline editable: S.Price, Discount%, Quantity
- Net Price and Total auto-calculated
- Delete button per row
- Footer row with totals

**Footer:**
- Sub Total, Discount summary
- Net Amount (big)
- Clear Cart button
- Save Invoice button → saves to Supabase

### Invoice List Screen (`purchase_invoices_list_screen.dart`)
- Table showing all purchase invoices
- Columns: Invoice#, Company, Date, Sub Total, Discount, Net Amount
- Footer with grand totals

## Setting sale_price and discount_pct on stock

After running migration, you can update prices/discounts on stock entries.
The `stock_provider.dart` now has `updatePriceAndDiscount()` method.
You can call this from your `StockTable` by adding editable price/discount columns.
