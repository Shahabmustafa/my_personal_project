import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../branch/return_stock_to_warehouse/data/model/branch_warehouse_return_model.dart';
import '../../../../branch/return_stock_to_warehouse/presentation/providers/branch_warehouse_return_provider.dart'
    show branchWarehouseReturnRepositoryProvider;
import '../../../shared/current_warehouse_provider.dart';

/// Is warehouse ko branches se jo returns aaye hain — same repository jo
/// branch side "Return Stock to Warehouse" feature save/list ke liye use
/// karta hai, bas yahan currentWarehouseIdProvider se filter hota hai.
final incomingBranchReturnsProvider = FutureProvider<List<BranchWarehouseReturnModel>>(
  (ref) => ref
      .watch(branchWarehouseReturnRepositoryProvider)
      .getIncomingReturns(ref.watch(currentWarehouseIdProvider)),
);
