import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../branch/sale_exchange/data/model/sale_exchange_model.dart';
import '../../../../branch/sale_exchange/presentation/provider/sale_exchange_provider.dart';
import '../../../../branch/sale_invoice/data/model/sale_invoice_model.dart';
import '../../../../branch/sale_invoice/presentation/provider/sale_invoice_provider.dart';
import '../../../../branch/sale_return/data/model/sale_return_model.dart';
import '../../../../branch/sale_return/presentation/provider/sale_return_provider.dart';
import '../../../../branch/shared/current_branch_provider.dart';

/// Logged-in salesman ka apna id — branch ke andar jo bhi sale/return/exchange
/// isi ke naam par hui ho, sirf wahi "My Activity" screens mein dikhti hai.
final currentSalesmanIdProvider = Provider<String>((ref) {
  return ref.watch(authProvider).user?.id ?? '';
});

final mySalesProvider = FutureProvider<List<SaleInvoiceModel>>((ref) {
  final branchId = ref.watch(currentBranchIdProvider);
  final salesmanId = ref.watch(currentSalesmanIdProvider);
  if (branchId.isEmpty || salesmanId.isEmpty) return Future.value(const []);
  return ref
      .read(saleInvoiceRepositoryProvider)
      .getInvoicesBySalesman(branchId, salesmanId);
});

final myReturnsProvider = FutureProvider<List<SaleReturnModel>>((ref) {
  final branchId = ref.watch(currentBranchIdProvider);
  final salesmanId = ref.watch(currentSalesmanIdProvider);
  if (branchId.isEmpty || salesmanId.isEmpty) return Future.value(const []);
  return ref
      .read(saleReturnRepositoryProvider)
      .getReturnsBySalesman(branchId, salesmanId);
});

final myExchangesProvider = FutureProvider<List<SaleExchangeModel>>((ref) {
  final branchId = ref.watch(currentBranchIdProvider);
  final salesmanId = ref.watch(currentSalesmanIdProvider);
  if (branchId.isEmpty || salesmanId.isEmpty) return Future.value(const []);
  return ref
      .read(saleExchangeRepositoryProvider)
      .getExchangesBySalesman(branchId, salesmanId);
});
