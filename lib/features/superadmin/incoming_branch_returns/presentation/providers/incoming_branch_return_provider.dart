import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../branch/return_stock_to_warehouse/data/model/branch_warehouse_return_model.dart';
import '../../../../branch/return_stock_to_warehouse/presentation/providers/branch_warehouse_return_provider.dart'
    show branchWarehouseReturnRepositoryProvider;
import '../../../shared/current_head_office_provider.dart';

/// Admin (Head Office) ko branches se jo returns aaye hain — same repository
/// jo branch side "Return Stock to Admin" feature save/list ke liye use
/// karta hai, bas yahan currentHeadOfficeIdProvider se filter hota hai.
final incomingBranchReturnsProvider =
    FutureProvider<List<BranchWarehouseReturnModel>>(
      (ref) => ref
          .watch(branchWarehouseReturnRepositoryProvider)
          .getIncomingReturns(ref.watch(currentHeadOfficeIdProvider)),
    );
