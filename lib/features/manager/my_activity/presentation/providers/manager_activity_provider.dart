import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../branch/sale_exchange/data/model/sale_exchange_model.dart';
import '../../../../branch/sale_exchange/presentation/provider/sale_exchange_provider.dart';
import '../../../../branch/sale_invoice/data/model/sale_invoice_model.dart';
import '../../../../branch/sale_invoice/presentation/provider/sale_invoice_provider.dart';
import '../../../../branch/sale_return/data/model/sale_return_model.dart';
import '../../../../branch/sale_return/presentation/provider/sale_return_provider.dart';
import '../../../../branch/shared/current_branch_provider.dart';

/// Logged-in manager ka apna id.
final currentManagerIdProvider = Provider<String>((ref) {
  return ref.watch(authProvider).user?.id ?? '';
});

/// Sirf jin invoices par ye manager assign hai — sale_invoices mein manager_id
/// column hai isliye ye query precise hai.
final myManagerSalesProvider = FutureProvider<List<SaleInvoiceModel>>((ref) {
  final branchId = ref.watch(currentBranchIdProvider);
  final managerId = ref.watch(currentManagerIdProvider);
  if (branchId.isEmpty || managerId.isEmpty) return Future.value(const []);
  return ref
      .read(saleInvoiceRepositoryProvider)
      .getInvoicesByManager(branchId, managerId);
});

/// sale_returns/sale_exchanges tables mein manager_id column nahi hai (branch
/// ka ek hi manager hota hai, koi per-transaction selection nahi) — isliye
/// manager ke liye ye poori branch ki returns/exchanges history dikhate hain,
/// jiske wo hi akela accountable hai.
final branchSaleReturnsProvider = FutureProvider<List<SaleReturnModel>>((ref) {
  final branchId = ref.watch(currentBranchIdProvider);
  if (branchId.isEmpty) return Future.value(const []);
  return ref.read(saleReturnRepositoryProvider).getReturns(branchId);
});

final branchSaleExchangesProvider =
    FutureProvider<List<SaleExchangeModel>>((ref) {
  final branchId = ref.watch(currentBranchIdProvider);
  if (branchId.isEmpty) return Future.value(const []);
  return ref.read(saleExchangeRepositoryProvider).getExchanges(branchId);
});
