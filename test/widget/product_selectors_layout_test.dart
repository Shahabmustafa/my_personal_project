import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safishoe_app/features/branch/assign_stock_to_other_branch/presentation/widgets/branch_transfer_product_selector.dart';
import 'package:safishoe_app/features/branch/return_stock_to_other_branch/presentation/widgets/branch_return_product_selector.dart';
import 'package:safishoe_app/features/branch/return_stock_to_warehouse/presentation/widgets/branch_warehouse_return_product_selector.dart';
import 'package:safishoe_app/features/branch/sale_invoice/presentation/provider/sale_invoice_provider.dart';
import 'package:safishoe_app/features/branch/sale_return/presentation/widgets/sale_return_product_selector.dart';
import 'package:safishoe_app/features/warehouse/assign_stock_to_branch/presentation/providers/assign_stock_provider.dart';
import 'package:safishoe_app/features/warehouse/assign_stock_to_branch/presentation/widgets/assign_product_selector.dart';
import 'package:safishoe_app/features/warehouse/purchase_invoice/presentation/providers/purchase_return_provider.dart';
import 'package:safishoe_app/features/warehouse/purchase_invoice/presentation/widgets/purchase_return_product_selector.dart';

/// Default test font (Ahem) makes every glyph a full em wide, which shows
/// overflows that real phones never hit — use the real Roboto instead.
Future<void> _loadRoboto() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
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

Widget _app(Size size, Widget child) => ProviderScope(
  overrides: [
    branchStockCacheProvider.overrideWith((ref) async => const []),
    returnWarehouseStockProvider.overrideWith((ref) async => const []),
    assignWarehouseStockProvider.overrideWith((ref) async => const []),
  ],
  child: MediaQuery(
    data: MediaQueryData(size: size),
    child: MaterialApp(
      theme: ThemeData(fontFamily: 'Roboto'),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  ),
);

void main() {
  setUpAll(_loadRoboto);

  final selectors = <String, Widget Function()>{
    'BranchTransfer': () => const BranchTransferProductSelector(),
    'BranchReturn': () => const BranchReturnProductSelector(),
    'BranchWarehouseReturn': () => const BranchWarehouseReturnProductSelector(),
    'SaleReturn': () => const SaleReturnProductSelector(),
    'WarehouseAssign': () => const AssignProductSelector(),
    'WarehousePurchaseReturn': () => const PurchaseReturnProductSelector(),
  };

  for (final size in const [Size(320, 640), Size(360, 740), Size(1280, 800)]) {
    selectors.forEach((name, build) {
      testWidgets('$name selector fits at $size', (t) async {
        await t.binding.setSurfaceSize(size);
        addTearDown(() => t.binding.setSurfaceSize(null));
        await t.pumpWidget(_app(size, build()));
        await t.pump(const Duration(milliseconds: 200));
        expect(t.takeException(), isNull);
        expect(find.text('Article'), findsWidgets);
      });
    });
  }
}
