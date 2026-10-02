import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safishoe_app/core/service/realtime/table_changes_provider.dart';
import '../../data/datasource/branch_payment_datasource.dart';
import '../../data/model/branch_payment_model.dart';
import '../../data/repository/branch_payment_repository.dart';

final branchPaymentRepositoryProvider = Provider<BranchPaymentRepository>(
  (_) => BranchPaymentRepository(BranchPaymentDatasource()),
);

/// Payments one branch has made to Head Office (shown under its cash counter).
final branchOwnPaymentsProvider =
    FutureProvider.family<List<BranchPaymentModel>, String>(
      (ref, branchId) {
        // Realtime — Head Office accept/reject kare to reload.
        ref.watch(tableChangesProvider('branch_payments'));
        return ref
            .watch(branchPaymentRepositoryProvider)
            .getBranchPayments(branchId);
      },
    );
