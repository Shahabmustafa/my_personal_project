import 'package:flutter_test/flutter_test.dart';
import 'package:safishoe_app/core/utils/money.dart';
import 'package:safishoe_app/features/branch/sale_invoice/data/model/sale_invoice_model.dart';
import 'package:safishoe_app/features/superadmin/discount/data/model/sale_discount_tier_model.dart';

SaleCartItem item({required double price, required int qty, double pct = 0}) =>
    SaleCartItem(
      branchStockId: 's', barcode: 'b', productId: 'p', productName: 'n',
      sizeId: 'z', sizeName: '', colorId: 'c', colorName: '', brandId: 'br',
      brandName: '', categoryId: 'ca', categoryName: '', typeId: 't',
      typeName: '', availableStock: 100, quantity: qty, salePrice: price,
      purchasePrice: 0, discountPct: pct,
    );

void main() {
  group('roundMoney', () {
    test('half-up at paisa (float edge 149.925)', () {
      expect(roundMoney(1999 * 7.5 / 100), 149.93);
    });
    test('classic float sum 0.1 + 0.2', () {
      expect(roundMoney(0.1 + 0.2), 0.3);
    });
    test('negative values round symmetrically', () {
      expect(roundMoney(-149.925), -149.93);
    });
    test('zero and whole numbers unchanged', () {
      expect(roundMoney(0), 0);
      expect(roundMoney(1500), 1500);
    });
    test('very large amount keeps paisa', () {
      expect(roundMoney(999999999.999), 1000000000.0);
    });
  });

  group('SaleCartItem rounding', () {
    test('7.5% off Rs 1999 x 3 has no fractional paisa', () {
      final i = item(price: 1999, qty: 3, pct: 7.5);
      expect(i.discountAmount, 149.93);
      expect(i.lineTotal, roundMoney(i.lineTotal));
      expect(i.lineTotal, 5547.21); // (1999 - 149.93) * 3
    });
    test('no discount', () {
      expect(item(price: 1250, qty: 2).lineTotal, 2500);
    });
  });

  test('tier percent discount rounded to paisa', () {
    const t = SaleDiscountTierModel(
        id: 't', minSaleAmount: 0,
        discountType: DiscountTierType.percent, discountValue: 7.5);
    expect(t.discountFor(1999), 149.93);
  });
}
