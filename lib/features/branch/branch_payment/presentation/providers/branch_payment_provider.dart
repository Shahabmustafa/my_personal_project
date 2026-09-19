import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/branch_payment_datasource.dart';
import '../../data/model/branch_payment_model.dart';
import '../../data/repository/branch_payment_repository.dart';

final branchPaymentRepositoryProvider = Provider<BranchPaymentRepository>(
  (_) => BranchPaymentRepository(BranchPaymentDatasource()),
);

/// Payments one branch has made to Head Office (shown under its cash counter).
final branchOwnPaymentsProvider =
    FutureProvider.family<List<BranchPaymentModel>, String>(
      (ref, branchId) =>
          ref.watch(branchPaymentRepositoryProvider).getBranchPayments(branchId),
    );
