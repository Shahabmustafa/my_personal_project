import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safishoe_app/features/warehouse/assign_stock_to_branch/data/models/assign_stock_model.dart';
import 'package:safishoe_app/features/warehouse/assign_stock_to_branch/presentation/providers/assign_stock_provider.dart';
import 'package:safishoe_app/features/warehouse/assign_stock_to_branch/presentation/screens/assign_stock_screen.dart';

class _FakeNotifier extends StateNotifier<AssignStockState>
    implements AssignStockNotifier {
  _FakeNotifier(AssignStockState s) : super(s);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

AssignCartItem _item(int i) => AssignCartItem(
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
  warehouseStock: 10,
  quantity: 2,
  salePrice: 4500,
  purchasePrice: 3000,
  discount: 5,
);

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

void main() {
  setUpAll(_loadRoboto);

  for (final size in const [Size(320, 2400), Size(360, 740), Size(1280, 800)]) {
    testWidgets('assign stock screen fits at $size', (t) async {
      await t.binding.setSurfaceSize(size);
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            assignStockProvider.overrideWith(
              (ref) => _FakeNotifier(
                AssignStockState(
                  assignmentNumber: 'Asg-000001',
                  selectedBranch: const BranchModel(
                    id: 'b1',
                    branchName: 'Main Branch',
                    city: 'Lahore',
                    status: 'active',
                  ),
                  cartItems: [_item(1), _item(2), _item(3)],
                ),
              ),
            ),
            branchesProvider.overrideWith((ref) async => const []),
            assignWarehouseStockProvider.overrideWith((ref) async => const []),
          ],
          child: MediaQuery(
            data: MediaQueryData(size: size),
            child: MaterialApp(
              theme: ThemeData(fontFamily: 'Roboto'),
              home: const Scaffold(body: AssignStockScreen()),
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 200));
      expect(t.takeException(), isNull);
      expect(find.text('Assignment No :'), findsOneWidget);
    });
  }
}
