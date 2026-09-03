import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ho_assign_stock_model.dart';
import '../providers/ho_assign_stock_provider.dart';

class HoAssignStockListScreen extends ConsumerStatefulWidget {
  const HoAssignStockListScreen({super.key});

  @override
  ConsumerState<HoAssignStockListScreen> createState() =>
      _HoAssignStockListScreenState();
}

class _HoAssignStockListScreenState
    extends ConsumerState<HoAssignStockListScreen> {
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(hoAssignListProvider.notifier).loadAssignments());
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(hoAssignListProvider);

    final filtered = listState.assignments.where((a) {
      if (_filterStatus == 'all') return true;
      return a.status == _filterStatus;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: Color(0xFF1565C0), size: 24),
              const SizedBox(width: 8),
              const Text(
                'Assignment History',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () =>
                    ref.read(hoAssignListProvider.notifier).loadAssignments(),
                icon: const Icon(Icons.refresh, color: Color(0xFF1565C0)),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SummaryCards(assignments: listState.assignments),
          const SizedBox(height: 14),
          Row(
            children: [
              _filterChip('All', 'all', listState.assignments.length),
              const SizedBox(width: 8),
              _filterChip(
                'Pending',
                'pending',
                listState.assignments
                    .where((a) => a.status == 'pending')
                    .length,
              ),
              const SizedBox(width: 8),
              _filterChip(
                'Accepted',
                'accepted',
                listState.assignments
                    .where((a) => a.status == 'accepted')
                    .length,
              ),
              const SizedBox(width: 8),
              _filterChip(
                'Rejected',
                'rejected',
                listState.assignments
                    .where((a) => a.status == 'rejected')
                    .length,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1565C0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                _th('#', flex: 1),
                _th('Assignment No', flex: 3),
                _th('Branch', flex: 4),
                _th('Pairs', flex: 2),
                _th('Date', flex: 2),
                _th('Status', flex: 2),
                _th('Actions', flex: 3),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12)),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: listState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : listState.error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 40),
                              const SizedBox(height: 8),
                              Text('Error: ${listState.error}',
                                  style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () => ref
                                    .read(hoAssignListProvider.notifier)
                                    .loadAssignments(),
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.inbox_outlined,
                                      size: 64,
                                      color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text(
                                    _filterStatus == 'all'
                                        ? 'No assignments yet'
                                        : 'No $_filterStatus assignments',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => Divider(
                                  height: 1, color: Colors.grey.shade100),
                              itemBuilder: (_, i) => _ListRow(
                                assignment: filtered[i],
                                index: i,
                              ),
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, int count) {
    final isSelected = _filterStatus == value;
    Color chipColor;
    switch (value) {
      case 'pending':
        chipColor = Colors.orange;
        break;
      case 'accepted':
        chipColor = Colors.green;
        break;
      case 'rejected':
        chipColor = Colors.red;
        break;
      default:
        chipColor = const Color(0xFF1565C0);
    }

    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? chipColor : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.25)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _th(String text, {int flex = 2}) => Expanded(
        flex: flex,
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      );
}

/// History list ke upar summary — total assignments, total pairs assigned,
/// aur status wise counts.
class _SummaryCards extends StatelessWidget {
  final List<HoAssignStockModel> assignments;
  const _SummaryCards({required this.assignments});

  @override
  Widget build(BuildContext context) {
    final totalPairs =
        assignments.fold<int>(0, (s, a) => s + a.totalPairs);
    final pending =
        assignments.where((a) => a.status == 'pending').length;
    final accepted =
        assignments.where((a) => a.status == 'accepted').length;

    final cards = <Widget>[
      _SummaryCard(
        label: 'Total Assignments',
        value: '${assignments.length}',
        icon: Icons.assignment_outlined,
        color: const Color(0xFF1565C0),
      ),
      _SummaryCard(
        label: 'Total Pairs Assigned',
        value: '$totalPairs',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF6A1B9A),
      ),
      _SummaryCard(
        label: 'Pending',
        value: '$pending',
        icon: Icons.hourglass_empty_outlined,
        color: const Color(0xFFEF6C00),
      ),
      _SummaryCard(
        label: 'Accepted',
        value: '$accepted',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF2E7D32),
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 820 ? 4 : (c.maxWidth > 460 ? 2 : 1);
        const gap = 12.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards) SizedBox(width: w, child: card),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B1F3B))),
                const SizedBox(height: 2),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11.5, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListRow extends ConsumerWidget {
  final HoAssignStockModel assignment;
  final int index;

  const _ListRow({required this.assignment, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(hoAssignListProvider.notifier);
    final isEven = index.isEven;

    return Container(
      color: isEven ? Colors.grey.shade50 : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text('${index + 1}',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade400)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              assignment.assignmentNumber,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF1565C0),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                const Icon(Icons.store_outlined,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    assignment.branchName ?? assignment.branchId,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined,
                    size: 13, color: Color(0xFF6A1B9A)),
                const SizedBox(width: 4),
                Text(
                  '${assignment.totalPairs}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6A1B9A)),
                ),
                if (assignment.lineCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '(${assignment.lineCount})',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade400),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _fmtDate(assignment.assignedAt),
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            flex: 2,
            child: _StatusChip(assignment.status),
          ),
          Expanded(
            flex: 3,
            child: assignment.status == 'pending'
                ? Row(
                    children: [
                      SizedBox(
                        height: 32,
                        child: FilledButton(
                          onPressed: () =>
                              _onAccept(context, ref, notifier),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                            minimumSize: Size.zero,
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Accept',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: () =>
                              _onReject(context, ref, notifier),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                            minimumSize: Size.zero,
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Reject',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  )
                : Text(
                    assignment.status == 'accepted'
                        ? 'Accepted ${_fmtDate(assignment.acceptedAt ?? assignment.assignedAt)}'
                        : 'Rejected',
                    style: TextStyle(
                      fontSize: 11,
                      color: assignment.status == 'accepted'
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _onAccept(
    BuildContext context,
    WidgetRef ref,
    HoAssignListNotifier notifier,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline,
                color: Colors.green, size: 22),
            SizedBox(width: 8),
            Text('Accept Assignment?'),
          ],
        ),
        content: const Text(
          'Stock branch inventory mein add ho jayega.\n\nYe action undo nahi ho sakta.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await notifier.acceptAssignment(assignment.id);
      ref.invalidate(hoAssignStockListProvider);
    }
  }

  Future<void> _onReject(
    BuildContext context,
    WidgetRef ref,
    HoAssignListNotifier notifier,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Reject Assignment?'),
          ],
        ),
        content: const Text(
          'Assignment rejected ho jayegi aur stock wapas head office mein aa jayega.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await notifier.rejectAssignment(assignment.id);
      ref.invalidate(hoAssignStockListProvider);
    }
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case 'accepted':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        label = 'Accepted';
        icon = Icons.check_circle_outline;
        break;
      case 'rejected':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        label = 'Rejected';
        icon = Icons.cancel_outlined;
        break;
      default:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        label = 'Pending';
        icon = Icons.hourglass_empty_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: fg)),
        ],
      ),
    );
  }
}
