import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safishoe_app/features/branch/branch_stock_inventory/data/model/branch_stock_model.dart';
import 'package:safishoe_app/features/branch/customer/data/model/customer_model.dart';
import 'package:safishoe_app/features/branch/sale_invoice/data/model/sale_invoice_model.dart';
import 'package:safishoe_app/features/branch/sale_invoice/data/repository/sale_invoice_repository.dart';
import 'package:safishoe_app/features/branch/sale_invoice/presentation/provider/sale_invoice_provider.dart';
import 'package:safishoe_app/features/branch/sale_return/data/repository/sale_return_repository.dart';
import 'package:safishoe_app/features/branch/sale_return/presentation/provider/sale_return_provider.dart';
import 'package:safishoe_app/features/branch/shared/current_branch_provider.dart';

class MockReturnRepo extends Mock implements SaleReturnRepository {}

class MockSaleRepo extends Mock implements SaleInvoiceRepository {}

BranchStockModel shoe({double price = 4000, int qty = 5}) => BranchStockModel(
      id: 's1',
      branchId: 'b1',
      stockId: 'st1',
      barcode: '3976076800059',
      productId: 'p1',
      sizeId: 'sz',
      colorId: 'c',
      brandId: 'b',
      categoryId: 'cat',
      typeId: 't',
      quantity: qty,
      salePrice: price,
      purchasePrice: 2000,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      productName: 'ch-28',
    );

/// 4000 ka ek shoe, 10% branch discount ke baad 3600 mein bika.
SaleInvoiceModel invoice({double invoiceDiscount = 400, double total = 3600}) =>
    SaleInvoiceModel(
      id: 'inv1',
      invoiceNumber: 'SAL-000001',
      branchId: 'b1',
      subtotal: 4000,
      totalDiscount: 0,
      invoiceDiscount: invoiceDiscount,
      totalAmount: total,
      salesmanCommissionPercent: 0,
      salesmanCommissionAmount: 0,
      managerCommissionPercent: 0,
      managerCommissionAmount: 0,
      createdAt: DateTime(2026, 10, 17),
      items: [
        SaleInvoiceItemModel(
          id: 'it1',
          saleInvoiceId: 'inv1',
          branchStockId: 's1',
          productId: 'p1',
          quantity: 1,
          salePrice: 4000,
          purchasePrice: 2000,
          discountPct: 0,
          discount: 0,
          totalPrice: 4000,
          productName: 'ch-28',
        ),
      ],
    );

void main() {
  late MockReturnRepo returnRepo;
  late MockSaleRepo saleRepo;

  ProviderContainer make({double branchPct = 10, SaleInvoiceModel? inv}) {
    when(() => returnRepo.generateReturnNumber())
        .thenAnswer((_) async => 'RET-000001');
    if (inv != null) {
      when(() => saleRepo.getInvoiceDetail(any())).thenAnswer((_) async => inv);
      when(() => saleRepo.getReturnedQuantities(any()))
          .thenAnswer((_) async => <String, int>{});
    }
    final c = ProviderContainer(overrides: [
      saleReturnRepositoryProvider.overrideWithValue(returnRepo),
      saleInvoiceRepositoryProvider.overrideWithValue(saleRepo),
      currentBranchIdProvider.overrideWithValue('b1'),
      customersForSaleProvider.overrideWith((ref) async => <CustomerModel>[]),
      currentBranchMaxInvoiceDiscountPctProvider
          .overrideWith((ref) async => branchPct),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  Future<SaleReturnNotifier> ready(ProviderContainer c) async {
    c.listen(saleReturnProvider, (_, __) {});
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return c.read(saleReturnProvider.notifier);
  }

  setUpAll(() => registerFallbackValue(invoice()));

  setUp(() {
    returnRepo = MockReturnRepo();
    saleRepo = MockSaleRepo();
  });

  group('return WITHOUT the old invoice', () {
    test('refund uses the branch discount (4000 shoe -> 3600)', () async {
      final c = make(branchPct: 10);
      final n = await ready(c);
      n.addCartItem(shoe(price: 4000));
      final s = c.read(saleReturnProvider);
      expect(s.cartItems.single.discountPct, 10);
      expect(s.subtotal, 4000);
      expect(s.totalDiscount, 400);
      expect(s.totalAmount, 3600);
    });

    test('no branch discount -> full price refund (unchanged behaviour)', () async {
      final c = make(branchPct: 0);
      final n = await ready(c);
      n.addCartItem(shoe(price: 4000));
      expect(c.read(saleReturnProvider).totalAmount, 4000);
    });

    test('admin changes the branch % -> lines already in the cart follow', () async {
      final c = make(branchPct: 10);
      final n = await ready(c);
      n.addCartItem(shoe(price: 4000));
      n.setBranchDiscountPct(5);
      expect(c.read(saleReturnProvider).totalAmount, 3800);
    });

    test('quantity 2 of the same shoe', () async {
      final c = make(branchPct: 10);
      final n = await ready(c);
      n.addCartItem(shoe(price: 4000), quantity: 2);
      expect(c.read(saleReturnProvider).totalAmount, 7200);
    });
  });

  group('return WITH the old invoice', () {
    test('refunds what the customer actually paid (3600, not 4000)', () async {
      final c = make(inv: invoice());
      final n = await ready(c);
      await n.selectOriginalInvoice(invoice());
      n.setReturnQuantity('it1', 1);
      final s = c.read(saleReturnProvider);
      expect(s.invoiceReturnItems.single.discountPct, 10);
      expect(s.totalDiscount, 400);
      expect(s.totalAmount, 3600);
    });

    test('invoice without discount refunds full price', () async {
      final inv = invoice(invoiceDiscount: 0, total: 4000);
      final c = make(inv: inv);
      final n = await ready(c);
      await n.selectOriginalInvoice(inv);
      n.setReturnQuantity('it1', 1);
      expect(c.read(saleReturnProvider).totalAmount, 4000);
    });

    test('flat bulk-tier discount is shared pro-rata (3000 invoice, Rs 300 off)', () async {
      final inv = invoice(invoiceDiscount: 300, total: 2700);
      final c = make(inv: inv);
      final n = await ready(c);
      await n.selectOriginalInvoice(inv);
      n.setReturnQuantity('it1', 1);
      // 4000 * (2700 / 3000) = 3600
      expect(c.read(saleReturnProvider).totalAmount, 3600);
    });
  });

  group('SaleInvoiceModel.effectiveDiscountPct', () {
    test('combines item % and invoice-wise discount', () {
      final inv = invoice(); // 10% invoice-wise
      expect(inv.invoiceDiscountRate, closeTo(0.1, 1e-9));
      expect(inv.effectiveDiscountPct(0), 10);
      expect(inv.effectiveDiscountPct(10), 19); // 100 - 90 * 0.9 = 19
    });
    test('no invoice discount leaves the item % untouched', () {
      final inv = invoice(invoiceDiscount: 0, total: 4000);
      expect(inv.effectiveDiscountPct(7.5), 7.5);
    });
  });
}
