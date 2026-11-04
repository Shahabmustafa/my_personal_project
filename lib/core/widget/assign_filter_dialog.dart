import 'package:flutter/material.dart';
import 'package:safishoe_app/core/widget/branch_filter_dropdown.dart';

/// Filter dialog ka natija: branch/source id (null = All) + date range.
typedef AssignFilterResult =
    ({String? branch, String? branch2, DateTime? from, DateTime? to});

/// Status filter option (All / Pending / Accepted / Rejected ...) + count.
typedef StatusFilterOption = ({String value, String label, int count});

/// [items] ki status ke hisaab se All/Pending/Accepted/Rejected options
/// (counts samet) banata hai. [second] default 'accepted' hai; sale claims
/// mein 'approved' pass karein.
List<StatusFilterOption> buildStatusOptions<T>(
  Iterable<T> items,
  String Function(T) statusOf, {
  String second = 'accepted',
}) {
  int c(String s) => items.where((e) => statusOf(e) == s).length;
  String cap(String s) => s[0].toUpperCase() + s.substring(1);
  return [
    (value: 'all', label: 'All', count: items.length),
    (value: 'pending', label: 'Pending', count: c('pending')),
    (value: second, label: cap(second), count: c(second)),
    (value: 'rejected', label: 'Rejected', count: c('rejected')),
  ];
}

Color _statusColor(String v) => switch (v) {
      'pending' => Colors.orange,
      'accepted' || 'approved' => Colors.green,
      'rejected' => Colors.red,
      _ => const Color(0xFF3E63DD),
    };

/// Tap-to-pick date textfield (read-only) with a clear button.
class DateFilterField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const DateFilterField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? ''
        : '${value!.day.toString().padLeft(2, '0')}/'
            '${value!.month.toString().padLeft(2, '0')}/${value!.year}';
    return TextField(cursorHeight: 16, 
      key: ValueKey('$label-$text'),
      controller: TextEditingController(text: text),
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'dd/mm/yyyy',
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: value == null
            ? const Icon(Icons.calendar_today_outlined, size: 16)
            : IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: onClear,
              ),
      ),
    );
  }
}

/// Branch dropdown + start/end date wala filter AlertDialog. Apply par
/// [AssignFilterResult] return karta hai, Cancel par null.
Future<AssignFilterResult?> showAssignFilterDialog(
  BuildContext context, {
  required String branchLabel,
  required String allLabel,
  required Map<String, String> branches,
  required AssignFilterResult current,
  // Optional doosra dropdown (jaise "Assigned By" + "Assigned To").
  String? branch2Label,
  String? branch2AllLabel,
  Map<String, String>? branches2,
  // false ho to sirf date range dikhta hai (branch dropdown nahi).
  bool showBranch = true,
  // Status chips (All/Pending/...) — [statusOptions] diye hon to dialog mein
  // dikhte hain; Apply par [onStatus] naya status deta hai.
  List<StatusFilterOption>? statusOptions,
  String status = 'all',
  ValueChanged<String>? onStatus,
}) {
  String statusValue = status;
  String? branch = current.branch;
  String? branch2 = current.branch2;
  DateTime? from = current.from;
  DateTime? to = current.to;

  Future<DateTime?> pick(DateTime? initial) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
  }

  return showDialog<AssignFilterResult>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: const Text('Filter'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (statusOptions != null) ...[
                const Text('Status',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final o in statusOptions)
                      ChoiceChip(
                        label: Text('${o.label} (${o.count})'),
                        selected: statusValue == o.value,
                        selectedColor: _statusColor(o.value),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusValue == o.value
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                        showCheckmark: false,
                        onSelected: (_) =>
                            setLocal(() => statusValue = o.value),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              if (showBranch)
                BranchFilterDropdown(
                  label: branchLabel,
                  allLabel: allLabel,
                  options: branches,
                  value: branch,
                  onChanged: (v) => setLocal(() => branch = v),
                ),
              if (branches2 != null) ...[
                const SizedBox(height: 16),
                BranchFilterDropdown(
                  label: branch2Label ?? 'Branch',
                  allLabel: branch2AllLabel ?? 'All branches',
                  options: branches2,
                  value: branch2,
                  onChanged: (v) => setLocal(() => branch2 = v),
                ),
              ],
              if (showBranch || branches2 != null) const SizedBox(height: 16),
              DateFilterField(
                label: 'Start date',
                value: from,
                onTap: () async {
                  final d = await pick(from);
                  if (d == null) return;
                  setLocal(() {
                    from = d;
                    if (to != null && to!.isBefore(d)) to = d;
                  });
                },
                onClear: () => setLocal(() => from = null),
              ),
              const SizedBox(height: 16),
              DateFilterField(
                label: 'End date',
                value: to,
                onTap: () async {
                  final d = await pick(to);
                  if (d == null) return;
                  setLocal(() {
                    to = d;
                    if (from != null && from!.isAfter(d)) from = d;
                  });
                },
                onClear: () => setLocal(() => to = null),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => setLocal(() {
              branch = null;
              branch2 = null;
              from = null;
              to = null;
              statusValue = 'all';
            }),
            child: const Text('Clear all'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              onStatus?.call(statusValue);
              Navigator.pop(
                  ctx, (branch: branch, branch2: branch2, from: from, to: to));
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    ),
  );
}
