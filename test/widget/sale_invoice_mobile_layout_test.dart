import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safishoe_app/features/branch/sale_invoice/data/model/sale_invoice_model.dart';
import 'package:safishoe_app/features/branch/sale_invoice/presentation/provider/sale_invoice_provider.dart';
import 'package:safishoe_app/features/branch/sale_invoice/presentation/screens/sale_invoice_screen.dart';

class _FakeNotifier extends StateNotifier<SaleInvoiceState>
    implements SaleInvoiceNotifier {
  _FakeNotifier(SaleInvoiceState s) : super(s);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHeld extends StateNotifier<List<HeldInvoice>>
    implements HeldInvoicesNotifier {
  _FakeHeld() : super(const []);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

SaleCartItem _item(int i) => SaleCartItem(
  branchStockId: 's$i',
  barcode: '890000000$i',
  productId: 'p$i',
  productName: 'Runner Pro $i',
  sizeId: 'z',
  sizeName: '42',
  colorId: 'c',
  colorName: 'Black',
  brandId: 'b',
  brandName: 'Safi',
  categoryId: 'k',
  categoryName: 'Sports',
  typeId: 't',
  typeName: 'Gents',
  availableStock: 10,
  quantity: 2,
  salePrice: 4500,
  purchasePrice: 3000,
  discountPct: 5,
);

Widget _app(Size size, String paymentType) {
  return ProviderScope(
    overrides: [
      saleInvoiceProvider.overrideWith(
        (ref) => _FakeNotifier(
          SaleInvoiceState(
            invoiceNumber: 'Sal-000001',
            paymentType: paymentType,
            cartItems: [_item(1), _item(2), _item(3)],
          ),
        ),
      ),
      heldInvoicesProvider.overrideWith((ref) => _FakeHeld()),
      branchStockCacheProvider.overrideWith((ref) async => const []),
      branchManagerProvider.overrideWith((ref) async => null),
      customersForSaleProvider.overrideWith((ref) async => const []),
      salesmenProvider.overrideWith((ref) async => const []),
      printersForSaleProvider.overrideWith((ref) async => const []),
      bankEntriesForSaleProvider.overrideWith((ref) async => const []),
      currentBranchMaxInvoiceDiscountPctProvider.overrideWith(
        (ref) async => 5.0,
      ),
    ],
    child: MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        theme: ThemeData(fontFamily: 'Roboto'),
        home: const Scaffold(body: SaleInvoiceScreen()),
      ),
    ),
  );
}

/// Default test font (Ahem) makes every glyph a full em wide, which shows
/// overflows that real phones never hit — use the real Roboto instead.
Future<void> _loadRoboto() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return; // falls back to Ahem (wider glyphs)
  final dir = '$root/bin/cache/artifacts/material_fonts';
  final loader = FontLoader('Roboto');
  for (final f in ['Regular', 'Medium', 'Bold']) {
    loader.addFont(
      File(
        '$dir/Roboto-$f.ttf',
      ).readAsBytes().then((b) => ByteData.view(b.buffer)),
    );
  }
  await loader.load();
}

void main() {
  setUpAll(_loadRoboto);

  for (final size in const [
    Size(360, 740),
    Size(360, 2400),
    Size(320, 2400),
    Size(1280, 800),
  ]) {
    for (final type in const ['cash', 'cash_card']) {
      testWidgets('sale invoice lays out without overflow at $size ($type)', (
        t,
      ) async {
        await t.binding.setSurfaceSize(size);
        addTearDown(() => t.binding.setSurfaceSize(null));
        await t.pumpWidget(_app(size, type));
        await t.pump(const Duration(milliseconds: 200));
        expect(t.takeException(), isNull);
        expect(find.text('Invoice Number :'), findsWidgets);
      });
    }
  }
}
