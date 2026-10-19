import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safishoe_app/features/branch/assign_stock_to_other_branch/presentation/providers/branch_transfer_provider.dart';
import 'package:safishoe_app/features/branch/assign_stock_to_other_branch/presentation/screens/branch_transfer_screen.dart';
import 'package:safishoe_app/features/warehouse/assign_stock_to_branch/data/models/assign_stock_model.dart';

AssignStockModel _transfer(int i, String status) => AssignStockModel(
  id: 't$i',
  assignmentNumber: 'Trf-00000$i',
  branchId: 'b$i',
  branchName: 'Johar Town Branch',
  status: status,
  assignedAt: DateTime(2026, 10, 18),
  createdAt: DateTime(2026, 10, 18),
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

  for (final size in const [Size(320, 640), Size(360, 740), Size(1280, 800)]) {
    testWidgets('transfer list fits at $size', (t) async {
      await t.binding.setSurfaceSize(size);
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            sentTransfersProvider.overrideWith(
              (ref) async => [
                _transfer(1, 'pending'),
                _transfer(2, 'accepted'),
                _transfer(3, 'rejected'),
              ],
            ),
          ],
          child: MediaQuery(
            data: MediaQueryData(size: size),
            child: MaterialApp(
              theme: ThemeData(fontFamily: 'Roboto'),
              home: const Scaffold(body: BranchTransferScreen()),
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 300));
      expect(t.takeException(), isNull);
      expect(find.text('Trf-000001'), findsWidgets);
      expect(find.text('Total Transfers'), findsOneWidget);
    });
  }
}
