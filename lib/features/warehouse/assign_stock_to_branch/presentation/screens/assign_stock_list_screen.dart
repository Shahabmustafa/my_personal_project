import 'package:safishoe_app/core/utils/date_format.dart' as dfmt;
import 'package:flutter/material.dart';
import 'package:safishoe_app/core/widget/min_width_scroll.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/assign_stock_model.dart';
import '../providers/assign_stock_provider.dart';
import '../../../../superadmin/report/presentation/widgets/report_pagination_bar.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/error_view.dart';
import 'package:safishoe_app/core/widget/assign_filter_dialog.dart';

class AssignStockListScreen extends ConsumerStatefulWidget {
  const AssignStockListScreen({super.key});

  @override
  ConsumerState<AssignStockListScreen> createState() =>
      _AssignStockListScreenState();
}

class _AssignStockListScreenState extends ConsumerState<AssignStockListScreen> {
  List<StatusFilterOption> _statusOptions = const [];
  String _filterStatus = 'all'; // all | pending | accepted | rejected
  String? _filterBranch; // receiving branch id
  DateTime? _fromDate; // assigned-on range (inclusive)
  DateTime? _toDate;
  static const _pageSize = 50;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    // Load on open
    Future.microtask(
      () => ref.read(assignListProvider.notifier).loadAssignments(),
    );
  }

  int get _activeFilterCount =>
      (_filterStatus != 'all' ? 1 : 0) +
      (_filterBranch != null ? 1 : 0) +
      (_fromDate != null ? 1 : 0) +
      (_toDate != null ? 1 : 0);

  Future<void> _openFilterDialog(Map<String, String> branches) async {
    final r = await showAssignFilterDialog(
      context,
      branchLabel: 'Assigned To Branch',
      allLabel: 'All branches',
      branches: branches,
      current: (
        branch: _filterBranch,
        branch2: null,
        from: _fromDate,
        to: _toDate,
      ),
      statusOptions: _statusOptions,
      status: _filterStatus,
      onStatus: (v) => _filterStatus = v,
    );
    if (r == null || !mounted) return;
    setState(() {
      _filterBranch = r.branch;
      _fromDate = r.from;
      _toDate = r.to;
      _page = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(assignListProvider);

    final branchOptions = <String, String>{
      for (final a in listState.assignments)
        a.branchId: a.branchName ?? a.branchId,
    };

    // Filter
    final filtered = listState.assignments.where((a) {
      if (_filterBranch != null && a.branchId != _filterBranch) return false;
      final d = a.assignedAt.toLocal();
      final day = DateTime(d.year, d.month, d.day);
      if (_fromDate != null && day.isBefore(_fromDate!)) return false;
      if (_toDate != null && day.isAfter(_toDate!)) return false;
      if (_filterStatus == 'all') return true;
      return a.status == _filterStatus;
    }).toList();

    final totalPages =
        filtered.isEmpty ? 1 : ((filtered.length - 1) ~/ _pageSize) + 1;
    final page = _page.clamp(1, totalPages);
    final pageRows =
        filtered.skip((page - 1) * _pageSize).take(_pageSize).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row ────────────────────────────────────────────────
          Row(
            children: [
              const AppIcon(
                AppIcons.history,
                color: Color(0xFF1565C0),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Assignment History',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Badge(
                isLabelVisible: _activeFilterCount > 0,
                label: Text('$_activeFilterCount'),
                child: OutlinedButton.icon(
                  onPressed: () => _openFilterDialog(branchOptions),
                  icon: const Icon(Icons.filter_list, size: 18),
                  label: const Text('Filter'),
                ),
              ),
              const SizedBox(width: 4),
              // Refresh button
              IconButton(
                onPressed: () =>
                    ref.read(assignListProvider.notifier).loadAssignments(),
                icon: const AppIcon(
                  AppIcons.refresh,
                  size: 18,
                  color: Color(0xFF1565C0),
                ),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Status filter chips ──────────────────────────────────────
          Builder(builder: (_) {
            _statusOptions = buildStatusOptions(listState.assignments, (x) => x.status);
            return const SizedBox.shrink();
          }),

          Expanded(
            child: MinWidthScroll(
              minWidth: 760,
              child: Column(
                children: [
                  // ── Table header ─────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        _th('#', flex: 1),
                        _th('Assignment No', flex: 3),
                        _th('Branch', flex: 4),
                        _th('Date', flex: 2),
                        _th('Items', flex: 1),
                        _th('Status', flex: 2),
                        _th('Actions', flex: 3),
                      ],
                    ),
                  ),

                  // ── Table body ───────────────────────────────────────────────
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: listState.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : listState.error != null
                          ? ErrorView(
                              error: listState.error,
                              onRetry: () => ref
                                  .read(assignListProvider.notifier)
                                  .loadAssignments(),
                            )
                          : filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppIcon(
                                    AppIcons.inboxOutlined,
                                    size: 64,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _filterStatus == 'all'
                                        ? 'No assignments yet'
                                        : 'No $_filterStatus assignments',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: pageRows.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: Colors.grey.shade100,
                              ),
                              itemBuilder: (_, i) =>
                                  _ListRow(assignment: pageRows[i], index: i),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (filtered.isNotEmpty) ...[
            const SizedBox(height: 12),
            ReportPaginationBar(
              page: page,
              totalPages: totalPages,
              totalCount: filtered.length,
              pageSize: _pageSize,
              onPageChange: (p) => setState(() => _page = p),
            ),
          ],
        ],
      ),
    );
  }

  

  Widget _th(String text, {int flex = 2}) => Expanded(
    flex: flex,
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  );
}

// ── List row ──────────────────────────────────────────────────────────────

class _ListRow extends ConsumerWidget {
  final AssignStockModel assignment;
  final int index;

  const _ListRow({required this.assignment, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(assignListProvider.notifier);
    final isEven = index.isEven;

    return Container(
      color: isEven ? Colors.grey.shade50 : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // #
          Expanded(
            flex: 1,
            child: Text(
              '${index + 1}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ),
          // Assignment number
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
          // Branch
          Expanded(
            flex: 4,
            child: Row(
              children: [
                const AppIcon(
                  AppIcons.storeOutlined,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    assignment.branchName ?? assignment.branchId,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Date
          Expanded(
            flex: 2,
            child: Text(
              _fmtDate(assignment.assignedAt),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          // Items count (blank for now — items not loaded in list)
          Expanded(
            flex: 1,
            child: Text(
              '—',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ),
          // Status chip
          Expanded(flex: 2, child: _StatusChip(assignment.status)),
          // Actions
          Expanded(
            flex: 3,
            child: assignment.status == 'pending'
                ? Row(
                    children: [
                      // Accept
                      SizedBox(
                        height: 32,
                        child: FilledButton(
                          onPressed: () => _onAccept(context, ref, notifier),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Accept',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Reject
                      SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: () => _onReject(context, ref, notifier),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Reject',
                            style: TextStyle(fontSize: 12),
                          ),
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
    AssignListNotifier notifier,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            AppIcon(AppIcons.checkCircleOutline, color: Colors.green, size: 22),
            SizedBox(width: 8),
            Text('Accept Assignment?'),
          ],
        ),
        content: const Text(
          'Stock will be deducted from warehouse and added to branch inventory.\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await notifier.acceptAssignment(assignment.id);
      ref.invalidate(assignWarehouseStockProvider);
    }
  }

  Future<void> _onReject(
    BuildContext context,
    WidgetRef ref,
    AssignListNotifier notifier,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            AppIcon(AppIcons.cancelOutlined, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Reject Assignment?'),
          ],
        ),
        content: const Text(
          'This assignment will be marked as rejected. Stock will NOT be moved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await notifier.rejectAssignment(assignment.id);
    }
  }

  String _fmtDate(DateTime dt) => dfmt.fmtDateTime(dt);
}

// ── Status chip ───────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    String icon;

    switch (status) {
      case 'accepted':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        label = 'Accepted';
        icon = AppIcons.checkCircleOutline;
        break;
      case 'rejected':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        label = 'Rejected';
        icon = AppIcons.cancelOutlined;
        break;
      default:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        label = 'Pending';
        icon = AppIcons.hourglassEmptyOutlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
