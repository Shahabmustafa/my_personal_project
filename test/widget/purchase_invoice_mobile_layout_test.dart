import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safishoe_app/features/warehouse/purchase_invoice/data/models/purchase_invoice_model.dart';
import 'package:safishoe_app/features/warehouse/purchase_invoice/data/models/warehouse_stock_model.dart';
import 'package:safishoe_app/features/warehouse/purchase_invoice/presentation/providers/purchase_invoice_provider.dart';
import 'package:safishoe_app/features/warehouse/purchase_invoice/presentation/screens/purchase_invoice_screen.dart';

class _FakeNotifier extends StateNotifier<PurchaseInvoiceState>
    implements PurchaseInvoiceNotifier {
  _FakeNotifier(PurchaseInvoiceState s) : super(s);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

PurchaseCartItem _item(int i) => PurchaseCartItem(
  stockId: 's$i',
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
  totalStock: 10,
  quantity: 2,
  salePrice: 4500,
  purchasePrice: 3000,
  discountPct: 5,
);

Widget _app(Size size) {
  return ProviderScope(
    overrides: [
      purchaseInvoiceProvider.overrideWith(
        (ref) => _FakeNotifier(
          PurchaseInvoiceState(
            invoiceNumber: 'Pur-000001',
            selectedCompany: const StockLookupItem(id: 'c1', label: 'Nike'),
            cartItems: [_item(1), _item(2), _item(3)],
          ),
        ),
      ),
      purchaseCompaniesProvider.overrideWith((ref) async => const []),
      warehouseStockCacheProvider.overrideWith((ref) async => const []),
    ],
    child: MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        theme: ThemeData(fontFamily: 'Roboto'),
        home: const Scaffold(body: PurchaseInvoiceScreen()),
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
    testWidgets('purchase invoice lays out without overflow at $size', (
      t,
    ) async {
      await t.binding.setSurfaceSize(size);
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(_app(size));
      await t.pump(const Duration(milliseconds: 200));
      expect(tester(t), isNull);
      expect(find.text('Invoice Number :'), findsWidgets);
    });
  }
}

Object? tester(WidgetTester t) => t.takeException();
