import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safishoe_app/core/service/realtime/insert_notification_stream.dart';
import 'package:safishoe_app/core/service/realtime/table_changes_provider.dart';
import '../../../../branch/return_stock_to_warehouse/data/model/branch_warehouse_return_model.dart';
import '../../../../branch/return_stock_to_warehouse/presentation/providers/branch_warehouse_return_provider.dart'
    show branchWarehouseReturnRepositoryProvider;
import '../../../shared/current_head_office_provider.dart';

/// Admin (Head Office) ko branches se jo returns aaye hain — same repository
/// jo branch side "Return Stock to Admin" feature save/list ke liye use
/// karta hai, bas yahan currentHeadOfficeIdProvider se filter hota hai.
/// Branch se naya return aate hi return number emit karta hai — dashboard
/// isay notification ki tarah dikhata hai.
final incomingBranchReturnNotifyProvider = StreamProvider<String>((ref) {
  final headOfficeId = ref.watch(currentHeadOfficeIdProvider);
  return insertNotificationStream(
    ref,
    channelName: 'incoming-return-to-admin:$headOfficeId',
    table: 'branch_return_to_warehouse',
    column: 'head_office_id',
    value: headOfficeId,
    numberField: 'return_number',
  );
});

final incomingBranchReturnsProvider =
    FutureProvider<List<BranchWarehouseReturnModel>>((ref) {
      // Realtime — branch ka naya return aate hi reload.
      ref.watch(tableChangesProvider('branch_return_to_warehouse'));
      return ref
          .watch(branchWarehouseReturnRepositoryProvider)
          .getIncomingReturns(ref.watch(currentHeadOfficeIdProvider));
    });

/// One return with items resolved to product/size/color names — for the
/// detail panel (the list query only carries raw item ids).
final incomingBranchReturnDetailProvider =
    FutureProvider.family<BranchWarehouseReturnModel, String>(
      (ref, id) => ref
          .read(branchWarehouseReturnRepositoryProvider)
          .getReturnDetail(id),
    );
