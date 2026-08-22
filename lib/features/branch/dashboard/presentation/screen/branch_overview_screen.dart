import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/branch_overview_model.dart';
import '../provider/branch_overview_provider.dart';

class BranchOverviewScreen extends ConsumerWidget {
  const BranchOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(branchOverviewProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(branchOverviewProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dashboard',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text('Overview of your branch',
                            style: TextStyle(fontSize: 13, color: Color(0xFF8A8FA3))),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: 'Refresh',
                    child: InkWell(
                      onTap: () => ref.invalidate(branchOverviewProvider),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE7E9F0)),
                        ),
                        child: const Icon(Icons.refresh, color: Color(0xFF3E63DD), size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              overviewAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(children: [
                      const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
                      const SizedBox(height: 10),
                      Text('Error: $e', style: const TextStyle(color: Color(0xFF8A8FA3))),
                    ]),
                  ),
                ),
                data: (data) => _CardGrid(data: data),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Card grid — 3 per row on desktop, stacked on mobile ────────────────────

class _CardGrid extends StatelessWidget {
  final BranchOverviewData data;
  const _CardGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _CardSpec(
        label: 'Total Article',
        value: '${data.totalArticles}',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF3E63DD),
      ),
      _CardSpec(
        label: 'Total Invoice',
        value: '${data.totalInvoices}',
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF6C4DE0),
      ),
      _CardSpec(
        label: 'Today Sale',
        value: 'Rs. ${_fmtAmt(data.todaySale)}',
        icon: Icons.point_of_sale_outlined,
        color: const Color(0xFF22A06B),
      ),
      _CardSpec(
        label: 'Today Target',
        value: 'Coming Soon',
        icon: Icons.flag_outlined,
        color: const Color(0xFF8A8FA3),
        muted: true,
      ),
      _CardSpec(
        label: 'Total Salesman',
        value: '${data.totalSalesman}',
        icon: Icons.badge_outlined,
        color: const Color(0xFF1565C0),
      ),
      _CardSpec(
        label: 'Total Expense',
        value: 'Rs. ${_fmtAmt(data.todayExpense)}',
        icon: Icons.receipt_outlined,
        color: const Color(0xFFE56A00),
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 700;
      if (isMobile) {
        return Column(
          children: cards
              .map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OverviewCard(spec: c),
                  ))
              .toList(),
        );
      }
      final rows = <Widget>[];
      for (var i = 0; i < cards.length; i += 3) {
        final rowCards = cards.sublist(i, (i + 3).clamp(0, cards.length));
        rows.add(Row(
          children: [
            for (int j = 0; j < rowCards.length; j++) ...[
              Expanded(child: _OverviewCard(spec: rowCards[j])),
              if (j != rowCards.length - 1) const SizedBox(width: 14),
            ],
          ],
        ));
        rows.add(const SizedBox(height: 14));
      }
      return Column(children: rows);
    });
  }
}

class _CardSpec {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool muted;
  const _CardSpec({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.muted = false,
  });
}

class _OverviewCard extends StatelessWidget {
  final _CardSpec spec;
  const _OverviewCard({required this.spec});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E9F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: spec.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(spec.icon, color: spec.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(spec.label,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF8A8FA3), fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  spec.value,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    fontStyle: spec.muted ? FontStyle.italic : FontStyle.normal,
                    color: spec.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtAmt(double v) {
  if (v == v.truncate()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(2);
}
