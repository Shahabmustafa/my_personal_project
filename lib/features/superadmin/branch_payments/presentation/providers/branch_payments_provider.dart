import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safishoe_app/core/service/realtime/table_changes_provider.dart';
import '../../../../branch/branch_payment/data/model/branch_payment_model.dart';
import '../../../../branch/branch_payment/presentation/providers/branch_payment_provider.dart';
import '../../../shared/current_head_office_provider.dart';

/// Payments branches have made to Admin (Head Office) — the transaction
/// report. Pending ones are accepted/rejected from the same screen.
final incomingBranchPaymentsProvider =
    FutureProvider<List<BranchPaymentModel>>((ref) {
      // Realtime — branch ki nayi payment aate hi reload.
      ref.watch(tableChangesProvider('branch_payments'));
      return ref
          .watch(branchPaymentRepositoryProvider)
          .getIncomingPayments(ref.watch(currentHeadOfficeIdProvider));
    });
