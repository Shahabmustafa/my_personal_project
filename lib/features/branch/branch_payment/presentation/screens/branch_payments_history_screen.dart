import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/current_branch_provider.dart';
import '../providers/branch_payment_provider.dart';
import '../widgets/branch_payments_panel.dart';

/// History of the payments this branch has sent to Head Office, with the
/// status Admin gave each one (pending / accepted / rejected).
class BranchPaymentsHistoryScreen extends ConsumerStatefulWidget {
  const BranchPaymentsHistoryScreen({super.key});

  @override
  ConsumerState<BranchPaymentsHistoryScreen> createState() =>
      _BranchPaymentsHistoryScreenState();
}

class _BranchPaymentsHistoryScreenState
    extends ConsumerState<BranchPaymentsHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Provider is cached — reload so payments sent / accepted since the last
    // visit show up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(branchOwnPaymentsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final branchId = ref.watch(currentBranchIdProvider);
    final payments = ref.watch(branchOwnPaymentsProvider(branchId));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Branch Payments',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text('Payments sent to Head Office',
                    style: TextStyle(fontSize: 13, color: Color(0xFF8A8FA3))),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: BranchPaymentsPanel(
                payments: payments,
                onRetry: () =>
                    ref.invalidate(branchOwnPaymentsProvider(branchId)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
