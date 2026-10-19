import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safishoe_app/features/auth/data/model/user_model.dart';
import 'package:safishoe_app/features/auth/data/repository/auth_repository.dart';
import 'package:safishoe_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:safishoe_app/features/branch/branch_stock_inventory/data/model/branch_stock_model.dart';
import 'package:safishoe_app/features/branch/customer/data/model/customer_model.dart';
import 'package:safishoe_app/features/branch/sale_invoice/data/model/sale_invoice_model.dart';
import 'package:safishoe_app/features/branch/sale_invoice/data/repository/sale_invoice_repository.dart';
import 'package:safishoe_app/features/branch/sale_invoice/presentation/provider/sale_invoice_provider.dart';
import 'package:safishoe_app/features/branch/shared/current_branch_provider.dart';
import 'package:safishoe_app/features/superadmin/discount/data/model/b1g1_offer_model.dart';
import 'package:safishoe_app/features/superadmin/discount/data/model/sale_discount_tier_model.dart';
import 'package:safishoe_app/features/superadmin/discount/presentation/providers/b1g1_offer_provider.dart';
import 'package:safishoe_app/features/superadmin/discount/presentation/providers/sale_discount_tier_provider.dart';

class MockRepo extends Mock implements SaleInvoiceRepository {}

class MockAuthRepo extends Mock implements AuthRepository {}

BranchStockModel stock(String id,
        {int qty = 10, double price = 1000, String product = 'p1'}) =>
    BranchStockModel(
      id: id,
      branchId: 'b1',
      stockId: 's$id',
      barcode: 'bc$id',
      productId: product,
      sizeId: 'sz',
      colorId: 'col',
      brandId: 'br',
      categoryId: 'cat',
      typeId: 'ty',
      quantity: qty,
      salePrice: price,
      purchasePrice: price / 2,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      productName: 'Shoe $id',
    );

const manager = EmployeeLookupItem(
    id: 'm1', name: 'Mgr', role: 'manager', commissionPercent: 2);
const salesman = EmployeeLookupItem(
    id: 's1', name: 'Sales', role: 'salesman', commissionPercent: 1);
const printer = PrinterLookupItem(id: 'pr1', label: 'Main');

void main() {
  late MockRepo repo;
  late MockAuthRepo authRepo;

  ProviderContainer make({
    List<SaleDiscountTierModel> tiers = const [],
    List<B1g1OfferModel> offers = const [],
    EmployeeLookupItem? mgr = manager,
    List<BranchStockModel> stocks = const [],
    double branchPct = 0,
  }) {
    final c = ProviderContainer(overrides: [
      saleInvoiceRepositoryProvider.overrideWithValue(repo),
      authRepositoryProvider.overrideWithValue(authRepo),
      currentBranchIdProvider.overrideWithValue('b1'),
      customersForSaleProvider.overrideWith((ref) async => <CustomerModel>[]),
      branchManagerProvider.overrideWith((ref) async => mgr),
      saleDiscountTiersProvider.overrideWith((ref) async => tiers),
      runningB1g1OffersProvider.overrideWith((ref) async => offers),
      branchStockCacheProvider.overrideWith((ref) async => stocks),
      currentBranchMaxInvoiceDiscountPctProvider.overrideWith((ref) async => branchPct),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  Future<SaleInvoiceNotifier> notifier(ProviderContainer c) async {
    c.listen(saleInvoiceProvider, (_, __) {});
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return c.read(saleInvoiceProvider.notifier);
  }

  setUp(() {
    repo = MockRepo();
    authRepo = MockAuthRepo();
    when(() => authRepo.getCurrentUser()).thenAnswer((_) async => const UserModel(
        id: 'u1', username: 'cash', email: 'c@x.com', role: 'cashier', branchIds: ['b1']));
    when(() => repo.generateInvoiceNumber()).thenAnswer((_) async => 'SAL-000001');
  });

  group('cart & stock limits', () {
    test('qty is capped to available stock', () async {
      final c = make();
      final n = await notifier(c);
      final added = n.addCartItem(stock('1', qty: 3), quantity: 10);
      expect(added, 3);
      expect(c.read(saleInvoiceProvider).totalQuantity, 3);
    });

    test('zero-stock item cannot be added', () async {
      final c = make();
      final n = await notifier(c);
      expect(n.addCartItem(stock('1', qty: 0)), 0);
      expect(c.read(saleInvoiceProvider).cartItems, isEmpty);
    });

    test('negative-stock item cannot be added', () async {
      final c = make();
      final n = await notifier(c);
      expect(n.addCartItem(stock('1', qty: -5)), 0);
      expect(c.read(saleInvoiceProvider).cartItems, isEmpty);
    });

    test('adding same item again cannot exceed stock', () async {
      final c = make();
      final n = await notifier(c);
      n.addCartItem(stock('1', qty: 2));
      n.addCartItem(stock('1', qty: 2));
      final added = n.addCartItem(stock('1', qty: 2));
      expect(added, 0);
      expect(c.read(saleInvoiceProvider).totalQuantity, 2);
    });

    test('updateItemQuantity above stock is clamped', () async {
      final c = make();
      final n = await notifier(c);
      n.addCartItem(stock('1', qty: 4));
      n.updateItemQuantity('1', 99);
      expect(c.read(saleInvoiceProvider).totalQuantity, 4);
    });

    test('quantity 0 or negative removes line', () async {
      final c = make();
      final n = await notifier(c);
      n.addCartItem(stock('1'));
      n.updateItemQuantity('1', -3);
      expect(c.read(saleInvoiceProvider).cartItems, isEmpty);
    });
  });

  group('totals', () {
    test('subtotal / total for 3 pairs', () async {
      final c = make();
      final n = await notifier(c);
      n.addCartItem(stock('1', price: 1500), quantity: 3);
      final s = c.read(saleInvoiceProvider);
      expect(s.subtotal, 4500);
      expect(s.totalAmount, 4500);
    });

    test('admin branch % auto-applied on the invoice', () async {
      final c = make();
      final n = await notifier(c);
      n.addCartItem(stock('1', price: 1000), quantity: 2);
      n.setBranchDiscountPct(10);
      expect(c.read(saleInvoiceProvider).totalAmount, 1800);
    });

    test('branch % is capped at 100', () async {
      final c = make();
      final n = await notifier(c);
      n.addCartItem(stock('1', price: 1000), quantity: 2);
      n.setBranchDiscountPct(150);
      expect(c.read(saleInvoiceProvider).invoiceDiscountPct, 100);
    });

    test('no discount when admin set 0%', () async {
      final c = make();
      final n = await notifier(c);
      n.addCartItem(stock('1', price: 1000));
      n.setBranchDiscountPct(10);
      expect(c.read(saleInvoiceProvider).totalAmount, 900);
      n.setBranchDiscountPct(0);
      expect(c.read(saleInvoiceProvider).invoiceDiscountPct, 0);
      expect(c.read(saleInvoiceProvider).totalAmount, 1000);
    });

    test('admin % from the branch provider applies by itself and survives clear/new invoice', () async {
      final c = make(branchPct: 10);
      final n = await notifier(c);
      n.addCartItem(stock('1', price: 1000));
      expect(c.read(saleInvoiceProvider).totalAmount, 900);
      n.clearCart();
      n.addCartItem(stock('1', price: 1000), quantity: 2);
      expect(c.read(saleInvoiceProvider).totalAmount, 1800);
      await n.resetInvoice();
      n.addCartItem(stock('2', price: 500));
      expect(c.read(saleInvoiceProvider).totalAmount, 450);
    });

    test('negative branch % clamps to 0', () async {
      final c = make();
      final n = await notifier(c);
      n.setBranchDiscountPct(-10);
      expect(c.read(saleInvoiceProvider).invoiceDiscountPct, 0);
    });

    test('auto tier discount applied once min amount reached', () async {
      final c = make(tiers: [
        const SaleDiscountTierModel(
            id: 't1',
            minSaleAmount: 3000,
            discountType: DiscountTierType.flat,
            discountValue: 300),
      ]);
      final n = await notifier(c);
      n.addCartItem(stock('1', price: 1000), quantity: 2);
      expect(c.read(saleInvoiceProvider).autoDiscount, 0);
      n.addCartItem(stock('1', price: 1000), quantity: 1);
      expect(c.read(saleInvoiceProvider).autoDiscount, 300);
      expect(c.read(saleInvoiceProvider).totalAmount, 2700);
    });

    test('highest qualifying tier wins (no stacking)', () async {
      final c = make(tiers: [
        const SaleDiscountTierModel(
            id: 'a',
            minSaleAmount: 1000,
            discountType: DiscountTierType.flat,
            discountValue: 50),
        const SaleDiscountTierModel(
            id: 'b',
            minSaleAmount: 2000,
            discountType: DiscountTierType.flat,
            discountValue: 200),
      ]);
      final n = await notifier(c);
      n.addCartItem(stock('1', price: 1000), quantity: 3);
      expect(c.read(saleInvoiceProvider).autoDiscount, 200);
    });

    test('manual % + auto tier together never push total below 0', () async {
      final c = make(tiers: [
        const SaleDiscountTierModel(
            id: 't',
            minSaleAmount: 100,
            discountType: DiscountTierType.percent,
            discountValue: 100),
      ]);
      final n = await notifier(c);
      n.addCartItem(stock('1', price: 1000));
      n.setBranchDiscountPct(100);
      expect(c.read(saleInvoiceProvider).totalAmount, 0);
    });

    test('B1G1: 2 pairs of same offer article -> pay for 1', () async {
      final c = make(offers: const [
        B1g1OfferModel(id: 'o', name: 'o', productIds: ['p1'])
      ]);
      final n = await notifier(c);
      n.addCartItem(stock('1', price: 1000));
      final s = c.read(saleInvoiceProvider);
      // second (free) unit is auto added
      expect(s.totalQuantity, 2);
      expect(s.totalAmount, 1000);
      expect(s.b1g1Discount, 1000);
    });

    test('B1G1 disables manual and tier discounts', () async {
      final c = make(offers: const [
        B1g1OfferModel(id: 'o', name: 'o', productIds: ['p1'])
      ]);
      final n = await notifier(c);
      n.addCartItem(stock('1', price: 1000));
      n.setBranchDiscountPct(10);
      expect(c.read(saleInvoiceProvider).invoiceDiscount, 0);
    });

    test('cash_card: card portion = total - cash, never negative', () async {
      final c = make();
      final n = await notifier(c);
      n.addCartItem(stock('1', price: 1000));
      n.selectPaymentType('cash_card');
      n.setCashAmount(400);
      expect(c.read(saleInvoiceProvider).cardAmount, 600);
      n.setCashAmount(5000);
      expect(c.read(saleInvoiceProvider).cardAmount, 0);
    });
  });

  group('saveInvoice validation', () {
    test('empty cart', () async {
      final n = await notifier(make());
      expect(await n.saveInvoice(), 'Cart is empty');
    });

    test('no customer selected (walk-in missing)', () async {
      final c = make();
      final n = await notifier(c);
      n.addCartItem(stock('1'));
      expect(await n.saveInvoice(), 'Select a customer');
    });

    test('missing manager blocks the sale', () async {
      final c = make(mgr: null);
      final n = await notifier(c);
      n.addCartItem(stock('1'));
      n.selectCustomer(_customer());
      n.selectSalesman(salesman);
      n.selectPrinter(printer);
      expect(await n.saveInvoice(), startsWith('Select a manager'));
    });

    test('card sale needs bank account', () async {
      final c = make();
      final n = await notifier(c);
      n.addCartItem(stock('1'));
      n.selectCustomer(_customer());
      n.selectSalesman(salesman);
      n.selectPrinter(printer);
      n.selectPaymentType('card');
      expect(await n.saveInvoice(), contains('bank account'));
    });

    test('cash_card with cash >= total rejected', () async {
      final c = make();
      final n = await notifier(c);
      n.addCartItem(stock('1', price: 1000));
      n.selectCustomer(_customer());
      n.selectSalesman(salesman);
      n.selectPrinter(printer);
      n.selectBankEntry(const BankEntryLookupItem(id: 'bk', label: 'HBL'));
      n.selectPaymentType('cash_card');
      n.setCashAmount(1000);
      expect(await n.saveInvoice(), contains('cash amount'));
    });
  });

  group('tier discount locks manual discount', () {
    const tier = SaleDiscountTierModel(
        id: 't',
        minSaleAmount: 100,
        discountType: DiscountTierType.percent,
        discountValue: 10);

    test('branch % is ignored while a tier applies (no stacking)', () async {
      final c = make(tiers: [tier]);
      final n = await notifier(c);
      n.addCartItem(stock('1', price: 1000));
      n.setBranchDiscountPct(60);
      final s = c.read(saleInvoiceProvider);
      expect(s.manualDiscountLocked, isTrue);
      expect(s.invoiceDiscountPct, 0);
      expect(s.invoiceDiscount, 0);
      expect(s.autoDiscount, 100); // 10% of 1000
      expect(s.totalAmount, 900);
    });

    test('branch % is dropped when a tier qualifies, and returns when it stops', () async {
      final c = make(tiers: [
        const SaleDiscountTierModel(
            id: 't',
            minSaleAmount: 2000,
            discountType: DiscountTierType.percent,
            discountValue: 10),
      ]);
      final n = await notifier(c);
      n.addCartItem(stock('1', price: 1000));
      n.setBranchDiscountPct(5);
      expect(c.read(saleInvoiceProvider).invoiceDiscountPct, 5);
      n.addCartItem(stock('1', price: 1000)); // 2000 -> tier qualifies
      final s = c.read(saleInvoiceProvider);
      expect(s.manualDiscountLocked, isTrue);
      expect(s.invoiceDiscountPct, 0);
      expect(s.totalAmount, 1800);
      // tier hatne par manual chupke se wapas nahi aata
      n.updateItemQuantity('1', 1);
      expect(c.read(saleInvoiceProvider).manualDiscountLocked, isFalse);
      expect(c.read(saleInvoiceProvider).invoiceDiscountPct, 5);
    });

    test('tiers pushed later (realtime) lock the manual field', () async {
      final c = make();
      final n = await notifier(c);
      n.addCartItem(stock('1', price: 1000));
      n.setBranchDiscountPct(5);
      expect(c.read(saleInvoiceProvider).invoiceDiscount, 50);
      n.setDiscountTiers([tier]);
      final s = c.read(saleInvoiceProvider);
      expect(s.manualDiscountLocked, isTrue);
      expect(s.invoiceDiscount, 0);
      expect(s.totalAmount, 900);
    });

    test('tier removed by admin unlocks the manual field', () async {
      final c = make(tiers: [tier]);
      final n = await notifier(c);
      n.addCartItem(stock('1', price: 1000));
      expect(c.read(saleInvoiceProvider).manualDiscountLocked, isTrue);
      n.setDiscountTiers(const []);
      expect(c.read(saleInvoiceProvider).manualDiscountLocked, isFalse);
      n.setBranchDiscountPct(5);
      expect(c.read(saleInvoiceProvider).totalAmount, 950);
    });
  });

  group('hold / resume invoice', () {
    test('hold on empty cart does nothing', () async {
      final c = make();
      final n = await notifier(c);
      expect(await n.holdInvoice(), isFalse);
      expect(c.read(heldInvoicesProvider), isEmpty);
    });

    test('hold keeps the cart aside and starts a fresh invoice', () async {
      final c = make();
      final n = await notifier(c);
      n.addCartItem(stock('1', price: 1000), quantity: 2);
      n.selectSalesman(salesman);
      expect(await n.holdInvoice(), isTrue);

      final held = c.read(heldInvoicesProvider);
      expect(held, hasLength(1));
      expect(held.single.totalQuantity, 2);
      expect(held.single.totalAmount, 2000);

      final fresh = c.read(saleInvoiceProvider);
      expect(fresh.cartItems, isEmpty);
      expect(fresh.salesman, isNull);
      expect(fresh.invoiceNumber, isNotEmpty);
    });

    test('second customer can be served and saved while first is held', () async {
      final c = make();
      final n = await notifier(c);
      n.addCartItem(stock('1', price: 1000));
      await n.holdInvoice();
      n.addCartItem(stock('2', price: 500), quantity: 3);
      expect(c.read(saleInvoiceProvider).totalAmount, 1500);
      expect(c.read(heldInvoicesProvider), hasLength(1));
    });

    test('resume restores items, salesman and discount', () async {
      final c = make();
      final n = await notifier(c);
      n.addCartItem(stock('1', price: 1000), quantity: 2);
      n.selectSalesman(salesman);
      n.setBranchDiscountPct(10);
      await n.holdInvoice();
      final id = c.read(heldInvoicesProvider).single.id;

      final note = await n.resumeHeld(id);
      expect(note, isNull);
      final s = c.read(saleInvoiceProvider);
      expect(s.totalQuantity, 2);
      expect(s.salesman?.id, 's1');
      expect(s.invoiceDiscountPct, 10);
      expect(s.totalAmount, 1800);
      expect(c.read(heldInvoicesProvider), isEmpty);
    });

    test('resume while current cart has items swaps (current gets held)', () async {
      final c = make();
      final n = await notifier(c);
      n.addCartItem(stock('1', price: 1000));
      await n.holdInvoice();
      n.addCartItem(stock('2', price: 500), quantity: 2);
      final id = c.read(heldInvoicesProvider).single.id;

      await n.resumeHeld(id);
      expect(c.read(saleInvoiceProvider).cartItems.single.branchStockId, '1');
      final held = c.read(heldInvoicesProvider);
      expect(held, hasLength(1));
      expect(held.single.totalAmount, 1000); // customer 2 (2 x 500)
    });

    test('resume re-checks stock: quantity reduced, sold-out removed', () async {
      final live = <BranchStockModel>[
        stock('1', qty: 10, price: 1000),
        stock('2', qty: 10, price: 500),
      ];
      final c = make(stocks: live);
      final n = await notifier(c);
      await c.read(branchStockCacheProvider.future);
      n.addCartItem(live[0], quantity: 5);
      n.addCartItem(live[1], quantity: 2);
      await n.holdInvoice();
      final id = c.read(heldInvoicesProvider).single.id;

      // Dusre counter ne stock bech diya.
      live
        ..clear()
        ..addAll([
          stock('1', qty: 3, price: 1000),
          stock('2', qty: 0, price: 500),
        ]);
      c.invalidate(branchStockCacheProvider);
      await c.read(branchStockCacheProvider.future);

      final note = await n.resumeHeld(id);
      expect(note, contains('Shoe 2'));
      expect(note, contains('only 3 left'));
      final s = c.read(saleInvoiceProvider);
      expect(s.cartItems, hasLength(1));
      expect(s.totalQuantity, 3);
      expect(s.cartItems.single.availableStock, 3);
    });

    test('discard removes a held invoice', () async {
      final c = make();
      final n = await notifier(c);
      n.addCartItem(stock('1'));
      await n.holdInvoice();
      n.discardHeld(c.read(heldInvoicesProvider).single.id);
      expect(c.read(heldInvoicesProvider), isEmpty);
    });

    test('resume of unknown id reports an error and changes nothing', () async {
      final c = make();
      final n = await notifier(c);
      n.addCartItem(stock('1'));
      expect(await n.resumeHeld('nope'), isNotNull);
      expect(c.read(saleInvoiceProvider).totalQuantity, 1);
    });
  });

  group('saveInvoice success / failure', () {
    Future<(ProviderContainer, SaleInvoiceNotifier)> ready() async {
      final c = make();
      final n = await notifier(c);
      n.addCartItem(stock('1', price: 1000), quantity: 2);
      n.selectCustomer(_customer());
      n.selectSalesman(salesman);
      n.selectPrinter(printer);
      return (c, n);
    }

    void stubSave({Object? error}) {
      final answer = error == null
          ? (Invocation _) async => _saved()
          : (Invocation _) async => throw error;
      when(() => repo.saveSaleInvoice(
            invoiceNumber: any(named: 'invoiceNumber'),
            branchId: any(named: 'branchId'),
            printerId: any(named: 'printerId'),
            cashierId: any(named: 'cashierId'),
            customerId: any(named: 'customerId'),
            salesmanId: any(named: 'salesmanId'),
            managerId: any(named: 'managerId'),
            subtotal: any(named: 'subtotal'),
            totalDiscount: any(named: 'totalDiscount'),
            invoiceDiscount: any(named: 'invoiceDiscount'),
            totalAmount: any(named: 'totalAmount'),
            salesmanCommissionPercent: any(named: 'salesmanCommissionPercent'),
            salesmanCommissionAmount: any(named: 'salesmanCommissionAmount'),
            managerCommissionPercent: any(named: 'managerCommissionPercent'),
            managerCommissionAmount: any(named: 'managerCommissionAmount'),
            note: any(named: 'note'),
            cartItems: any(named: 'cartItems'),
            payments: any(named: 'payments'),
          )).thenAnswer(answer);
    }

    test('success returns null and sets lastSavedInvoice', () async {
      stubSave();
      final (c, n) = await ready();
      expect(await n.saveInvoice(), isNull);
      expect(c.read(saleInvoiceProvider).lastSavedInvoice, isNotNull);
      expect(c.read(saleInvoiceProvider).isSaving, isFalse);
    });

    test('commission is computed on net total', () async {
      stubSave();
      final (_, n) = await ready();
      await n.saveInvoice();
      final v = verify(() => repo.saveSaleInvoice(
            invoiceNumber: any(named: 'invoiceNumber'),
            branchId: any(named: 'branchId'),
            printerId: any(named: 'printerId'),
            cashierId: any(named: 'cashierId'),
            customerId: any(named: 'customerId'),
            salesmanId: any(named: 'salesmanId'),
            managerId: any(named: 'managerId'),
            subtotal: any(named: 'subtotal'),
            totalDiscount: any(named: 'totalDiscount'),
            invoiceDiscount: any(named: 'invoiceDiscount'),
            totalAmount: captureAny(named: 'totalAmount'),
            salesmanCommissionPercent: any(named: 'salesmanCommissionPercent'),
            salesmanCommissionAmount: captureAny(named: 'salesmanCommissionAmount'),
            managerCommissionPercent: any(named: 'managerCommissionPercent'),
            managerCommissionAmount: captureAny(named: 'managerCommissionAmount'),
            note: any(named: 'note'),
            cartItems: any(named: 'cartItems'),
            payments: any(named: 'payments'),
          ));
      expect(v.captured, [2000.0, 20.0, 40.0]);
    });

    test('server error (offline) -> error string, cart kept, not saving', () async {
      stubSave(error: Exception('SocketException: Failed host lookup'));
      final (c, n) = await ready();
      final err = await n.saveInvoice();
      expect(err, contains('SocketException'));
      final s = c.read(saleInvoiceProvider);
      expect(s.isSaving, isFalse);
      expect(s.cartItems, isNotEmpty);
      expect(s.lastSavedInvoice, isNull);
    });

    test('duplicate invoice number retried once with fresh number', () async {
      var calls = 0;
      when(() => repo.generateInvoiceNumber()).thenAnswer((_) async => 'SAL-00000${++calls}');
      when(() => repo.saveSaleInvoice(
            invoiceNumber: 'SAL-000001',
            branchId: any(named: 'branchId'),
            printerId: any(named: 'printerId'),
            cashierId: any(named: 'cashierId'),
            customerId: any(named: 'customerId'),
            salesmanId: any(named: 'salesmanId'),
            managerId: any(named: 'managerId'),
            subtotal: any(named: 'subtotal'),
            totalDiscount: any(named: 'totalDiscount'),
            invoiceDiscount: any(named: 'invoiceDiscount'),
            totalAmount: any(named: 'totalAmount'),
            salesmanCommissionPercent: any(named: 'salesmanCommissionPercent'),
            salesmanCommissionAmount: any(named: 'salesmanCommissionAmount'),
            managerCommissionPercent: any(named: 'managerCommissionPercent'),
            managerCommissionAmount: any(named: 'managerCommissionAmount'),
            note: any(named: 'note'),
            cartItems: any(named: 'cartItems'),
            payments: any(named: 'payments'),
          )).thenThrow(Exception('23505 duplicate key'));
      when(() => repo.saveSaleInvoice(
            invoiceNumber: 'SAL-000002',
            branchId: any(named: 'branchId'),
            printerId: any(named: 'printerId'),
            cashierId: any(named: 'cashierId'),
            customerId: any(named: 'customerId'),
            salesmanId: any(named: 'salesmanId'),
            managerId: any(named: 'managerId'),
            subtotal: any(named: 'subtotal'),
            totalDiscount: any(named: 'totalDiscount'),
            invoiceDiscount: any(named: 'invoiceDiscount'),
            totalAmount: any(named: 'totalAmount'),
            salesmanCommissionPercent: any(named: 'salesmanCommissionPercent'),
            salesmanCommissionAmount: any(named: 'salesmanCommissionAmount'),
            managerCommissionPercent: any(named: 'managerCommissionPercent'),
            managerCommissionAmount: any(named: 'managerCommissionAmount'),
            note: any(named: 'note'),
            cartItems: any(named: 'cartItems'),
            payments: any(named: 'payments'),
          )).thenAnswer((_) async => _saved());
      final (c, n) = await ready();
      expect(await n.saveInvoice(), isNull);
      expect(c.read(saleInvoiceProvider).invoiceNumber, 'SAL-000002');
    });
  });
}

CustomerModel _customer() => CustomerModel.fromJson(
    {'id': 'c1', 'name': 'Walk-in Customer', 'is_walkin': true});

SaleInvoiceModel _saved() => SaleInvoiceModel(
      id: 'inv1',
      invoiceNumber: 'SAL-000001',
      branchId: 'b1',
      customerId: 'c1',
      subtotal: 2000,
      totalDiscount: 0,
      totalAmount: 2000,
      salesmanCommissionPercent: 1,
      salesmanCommissionAmount: 20,
      managerCommissionPercent: 2,
      managerCommissionAmount: 40,
      createdAt: DateTime(2026, 10, 17),
    );
