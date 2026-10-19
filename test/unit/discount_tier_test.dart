import 'package:flutter_test/flutter_test.dart';
import 'package:safishoe_app/features/superadmin/discount/data/model/sale_discount_tier_model.dart';

SaleDiscountTierModel tier(DiscountTierType t, double v, {double min = 1000}) =>
    SaleDiscountTierModel(
      id: 't',
      minSaleAmount: min,
      discountType: t,
      discountValue: v,
    );

void main() {
  group('SaleDiscountTierModel.discountFor', () {
    test('flat discount', () {
      expect(tier(DiscountTierType.flat, 200).discountFor(5000), 200);
    });
    test('percent discount', () {
      expect(tier(DiscountTierType.percent, 10).discountFor(5000), 500);
    });
    test('flat larger than amount is capped at amount', () {
      expect(tier(DiscountTierType.flat, 9000).discountFor(5000), 5000);
    });
    test('percent over 100 is capped at amount', () {
      expect(tier(DiscountTierType.percent, 150).discountFor(5000), 5000);
    });
    test('negative discount value clamps to 0', () {
      expect(tier(DiscountTierType.flat, -50).discountFor(5000), 0);
    });
    test('zero amount -> zero discount', () {
      expect(tier(DiscountTierType.percent, 10).discountFor(0), 0);
    });
  });

  group('fromJson / toJson', () {
    test('parses numbers given as int/String-safe', () {
      final m = SaleDiscountTierModel.fromJson({
        'id': 1,
        'min_sale_amount': 1000,
        'discount_type': 'flat',
        'discount_value': 50.5,
      });
      expect(m.id, '1');
      expect(m.minSaleAmount, 1000);
      expect(m.discountType, DiscountTierType.flat);
      expect(m.discountValue, 50.5);
    });
    test('empty json does not crash (defaults)', () {
      final m = SaleDiscountTierModel.fromJson({});
      expect(m.minSaleAmount, 0);
      expect(m.discountType, DiscountTierType.percent);
    });
    test('round trip', () {
      final j = tier(DiscountTierType.flat, 25).toJson();
      expect(j['discount_type'], 'flat');
      expect(j['discount_value'], 25);
    });
  });
}
