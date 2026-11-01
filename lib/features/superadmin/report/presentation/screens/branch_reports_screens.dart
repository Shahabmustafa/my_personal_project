import 'package:flutter/material.dart';
import '../../data/branch_reports.dart';
import '../widgets/simple_report.dart';

/// Admin + branch ki Reports — sab [SimpleReportScreen] par. Branch user
/// ke liye `restrictToOwnBranch: true` (sirf apni branch ka data).

class CashCounterReportScreen extends StatelessWidget {
  final bool restrictToOwnBranch;
  const CashCounterReportScreen({super.key, this.restrictToOwnBranch = false});
  @override
  Widget build(BuildContext context) => SimpleReportScreen(
        title: 'Cash Counter Report',
        fetch: cashCounterReport,
        restrictToOwnBranch: restrictToOwnBranch,
        searchHint: 'Search date, branch…',
      );
}

class ExpenseReportScreen extends StatelessWidget {
  final bool restrictToOwnBranch;
  const ExpenseReportScreen({super.key, this.restrictToOwnBranch = false});
  @override
  Widget build(BuildContext context) => SimpleReportScreen(
        title: 'Expense Report',
        fetch: expenseReport,
        restrictToOwnBranch: restrictToOwnBranch,
        searchHint: 'Search head, note…',
      );
}

class CustomerReportScreen extends StatelessWidget {
  final bool restrictToOwnBranch;
  const CustomerReportScreen({super.key, this.restrictToOwnBranch = false});
  @override
  Widget build(BuildContext context) => SimpleReportScreen(
        title: 'Customer Report',
        fetch: customerReport,
        restrictToOwnBranch: restrictToOwnBranch,
        searchHint: 'Search name, phone…',
      );
}

class SaleClaimReportScreen extends StatelessWidget {
  final bool restrictToOwnBranch;
  const SaleClaimReportScreen({super.key, this.restrictToOwnBranch = false});
  @override
  Widget build(BuildContext context) => SimpleReportScreen(
        title: 'Sale Claim Report',
        fetch: saleClaimReport,
        restrictToOwnBranch: restrictToOwnBranch,
        searchHint: 'Search claim, article, status…',
      );
}

class StockAssignReportScreen extends StatelessWidget {
  final bool restrictToOwnBranch;
  const StockAssignReportScreen({super.key, this.restrictToOwnBranch = false});
  @override
  Widget build(BuildContext context) => SimpleReportScreen(
        title: 'Stock Assign Report',
        fetch: stockAssignReport,
        restrictToOwnBranch: restrictToOwnBranch,
        searchHint: 'Search number, branch, status…',
      );
}

class StockReturnReportScreen extends StatelessWidget {
  final bool restrictToOwnBranch;
  const StockReturnReportScreen({super.key, this.restrictToOwnBranch = false});
  @override
  Widget build(BuildContext context) => SimpleReportScreen(
        title: 'Stock Return Report',
        fetch: stockReturnReport,
        restrictToOwnBranch: restrictToOwnBranch,
        searchHint: 'Search number, branch, status…',
      );
}

class StockReportScreen extends StatelessWidget {
  final bool restrictToOwnBranch;
  const StockReportScreen({super.key, this.restrictToOwnBranch = false});
  @override
  Widget build(BuildContext context) => SimpleReportScreen(
        title: 'Stock Report',
        fetch: stockReport,
        restrictToOwnBranch: restrictToOwnBranch,
        showDates: false,
        searchHint: 'Search brand, category, branch…',
      );
}

class BranchPaymentReportScreen extends StatelessWidget {
  final bool restrictToOwnBranch;
  const BranchPaymentReportScreen({super.key, this.restrictToOwnBranch = false});
  @override
  Widget build(BuildContext context) => SimpleReportScreen(
        title: 'Branch Payments Report',
        fetch: branchPaymentReport,
        restrictToOwnBranch: restrictToOwnBranch,
        searchHint: 'Search number, status…',
      );
}
