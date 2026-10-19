import 'package:flutter_test/flutter_test.dart';
import 'package:safishoe_app/features/superadmin/discount/data/model/b1g1_offer_model.dart';

typedef _Line = ({
  double price,
  int quantity,
  String productId,
  String variantKey,
  String brandId,
  String categoryId
});

_Line line(String p, double price, int qty) => (
      price: price,
      quantity: qty,
      productId: p,
      variantKey: 'k$p',
      brandId: 'b',
      categoryId: 'c',
    );

void main() {
  const offer = B1g1OfferModel(id: 'o1', name: 'B1G1', productIds: ['p1', 'p2']);

  group('computeB1g1', () {
    test('no offers -> no free units', () {
      final r = computeB1g1([line('p1', 100, 2)], const []);
      expect(r.single.offerId, isNull);
      expect(r.single.freeQty, 0);
    });

    test('1 unit only -> offer not applied', () {
      final r = computeB1g1([line('p1', 100, 1)], [offer]);
      expect(r.single.offerId, isNull);
      expect(r.single.freeQty, 0);
    });

    test('2 same units -> 1 free', () {
      final r = computeB1g1([line('p1', 100, 2)], [offer]);
      expect(r.single.offerId, 'o1');
      expect(r.single.freeQty, 1);
    });

    test('cheaper article becomes the free one', () {
      final r = computeB1g1([line('p1', 500, 1), line('p2', 300, 1)], [offer]);
      expect(r[0].freeQty, 0);
      expect(r[1].freeQty, 1);
    });

    test('odd count (3) -> 1 free, middle stays paid', () {
      final r = computeB1g1([line('p1', 100, 3)], [offer]);
      expect(r.single.freeQty, 1);
    });

    test('4 units -> 2 free', () {
      final r = computeB1g1([line('p1', 100, 4)], [offer]);
      expect(r.single.freeQty, 2);
    });

    test('item outside offer unaffected', () {
      final r = computeB1g1([line('p9', 100, 2)], [offer]);
      expect(r.single.offerId, isNull);
    });

    test('zero quantity line does not crash', () {
      final r = computeB1g1([line('p1', 100, 0)], [offer]);
      expect(r.single.freeQty, 0);
    });
  });

  group('B1g1OfferModel.isRunningOn', () {
    final now = DateTime(2026, 10, 17, 15);
    test('inactive -> false', () {
      expect(
        const B1g1OfferModel(id: 'x', name: 'x', isActive: false).isRunningOn(now),
        isFalse,
      );
    });
    test('end date is inclusive', () {
      final o = B1g1OfferModel(id: 'x', name: 'x', endDate: DateTime(2026, 10, 17));
      expect(o.isRunningOn(now), isTrue);
    });
    test('expired yesterday -> false', () {
      final o = B1g1OfferModel(id: 'x', name: 'x', endDate: DateTime(2026, 10, 16));
      expect(o.isRunningOn(now), isFalse);
    });
    test('starts tomorrow -> false', () {
      final o = B1g1OfferModel(id: 'x', name: 'x', startDate: DateTime(2026, 10, 18));
      expect(o.isRunningOn(now), isFalse);
    });
  });
}
