import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widget/app_dropdown.dart';
import '../../data/model/expense_entry_model.dart';
import '../../data/model/expense_head_model.dart';
import '../provider/expense_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
const _primary = Color(0xFFE56A00);

class ExpenseScreen extends ConsumerStatefulWidget {
  const ExpenseScreen({super.key});

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Expense',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(
                          '${state.entries.length} entr${state.entries.length == 1 ? 'y' : 'ies'} · Total Rs. ${_fmtAmt(state.totalExpense)}',
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF8A8FA3))),
                    ],
                  ),
                ),
                Tooltip(
                  message: 'Refresh',
                  child: InkWell(
                    onTap: () => ref.read(expenseProvider.notifier).load(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE7E9F0)),
                      ),
                      child: const AppIcon(AppIcons.refresh,
                          color: _primary, size: 20),
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _openAddExpenseDialog(context),
                  icon: const AppIcon(AppIcons.addRounded, size: 18, color: Colors.white),
                  label: const Text('Add Expense'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // ── Content ───────────────────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? _ErrorView(
                        message: state.error!,
                        onRetry: () =>
                            ref.read(expenseProvider.notifier).load(),
                      )
                    : state.entries.isEmpty
                        ? const _EmptyView()
                        : isMobile
                            ? _MobileList(entries: state.entries)
                            : _DesktopTable(entries: state.entries),
          ),
        ],
      ),
    );
  }

  void _openAddExpenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _AddExpenseDialog(),
    );
  }
}

// ── Add Expense Dialog ──────────────────────────────────────────────────────

class _AddExpenseDialog extends ConsumerStatefulWidget {
  const _AddExpenseDialog();

  @override
  ConsumerState<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends ConsumerState<_AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  ExpenseHeadModel? _selectedHead;
  String? _headError;
  bool _submitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heads = ref.watch(expenseProvider).heads;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        AppIcon(AppIcons.receiptLongOutlined, color: _primary, size: 22),
        SizedBox(width: 8),
        Text('Add Expense',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ]),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppSearchDropdown<ExpenseHeadModel>(
                      label: 'Expense Head',
                      items: heads,
                      selectedItem: _selectedHead,
                      itemLabel: (h) => h.name,
                      errorText: _headError,
                      isRequired: true,
                      onChanged: (h) => setState(() {
                        _selectedHead = h;
                        _headError = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'New expense head',
                    child: IconButton(
                      onPressed: () => _openAddHeadDialog(context),
                      icon: const AppIcon(AppIcons.addCircleOutline,
                          color: _primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                decoration: _decor('Amount').copyWith(prefixText: 'Rs. '),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                decoration: _decor('Note (optional)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const AppIcon(AppIcons.checkRounded, size: 16),
          label: const Text('Save'),
          style: FilledButton.styleFrom(
            backgroundColor: _primary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    setState(() => _headError = _selectedHead == null ? 'Select an expense head' : null);
    if (!formValid || _selectedHead == null) return;
    setState(() => _submitting = true);
    final error = await ref.read(expenseProvider.notifier).addExpense(
          expenseHeadId: _selectedHead!.id,
          amount: double.parse(_amountCtrl.text),
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error == null) {
      Navigator.pop(context);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error == null ? 'Expense added.' : 'Error: $error'),
      backgroundColor: error == null ? Colors.green.shade700 : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  void _openAddHeadDialog(BuildContext context) {
    showDialog<ExpenseHeadModel?>(
      context: context,
      builder: (_) => const _AddHeadDialog(),
    ).then((head) {
      if (head != null && mounted) {
        setState(() {
          _selectedHead = head;
          _headError = null;
        });
      }
    });
  }

  InputDecoration _decor(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _primary, width: 1.5)),
      );
}

// ── Add Expense Head Dialog ─────────────────────────────────────────────────

class _AddHeadDialog extends ConsumerStatefulWidget {
  const _AddHeadDialog();

  @override
  ConsumerState<_AddHeadDialog> createState() => _AddHeadDialogState();
}

class _AddHeadDialogState extends ConsumerState<_AddHeadDialog> {
  final _nameCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('New Expense Head',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 320,
        child: TextField(
          controller: _nameCtrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Name',
            errorText: _error,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: _primary),
          child: _submitting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final error =
        await ref.read(expenseProvider.notifier).addHead(name: name);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _submitting = false;
        _error = error;
      });
      return;
    }
    final head = ref
        .read(expenseProvider)
        .heads
        .firstWhere((h) => h.name == name, orElse: () => ExpenseHeadModel(id: '', name: name));
    Navigator.pop(context, head);
  }
}

// ── Desktop Table ────────────────────────────────────────────────────────────

class _DesktopTable extends ConsumerWidget {
  final List<ExpenseEntryModel> entries;
  const _DesktopTable({required this.entries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7E9F0)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              // Header
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F8FC),
                  border: Border(bottom: BorderSide(color: Color(0xFFE7E9F0))),
                ),
                child: const Row(children: [
                  _TH('#', flex: 1),
                  _TH('Date', flex: 2),
                  _TH('Expense Head', flex: 3),
                  _TH('Note', flex: 4),
                  _TH('Amount', flex: 2, alignEnd: true),
                  _TH('', flex: 1),
                ]),
              ),
              // Rows
              Expanded(
                child: ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFE7E9F0)),
                  itemBuilder: (_, i) {
                    final e = entries[i];
                    return Container(
                      color: i.isEven ? Colors.white : const Color(0xFFFAFAFC),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 1,
                            child: _TD(
                              child: Text('${i + 1}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF8A8FA3))),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: _TD(
                              child: Text(_fmtDate(e.createdAt),
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF8A8FA3))),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: _TD(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF1E0),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const AppIcon(
                                        AppIcons.receiptLongOutlined,
                                        size: 14,
                                        color: _primary),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(e.expenseHeadName,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: _TD(
                              child: Text(
                                (e.note == null || e.note!.isEmpty)
                                    ? '—'
                                    : e.note!,
                                style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF5A5F73)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: _TD(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text('Rs. ${_fmtAmt(e.amount)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: _primary)),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: _TD(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: _IconBtn(
                                  icon: AppIcons.deleteOutline,
                                  color: Colors.red.shade400,
                                  tooltip: 'Delete',
                                  onTap: () =>
                                      _confirmDelete(context, ref, e.id),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Table helpers ──────────────────────────────────────────────────────────

class _TH extends StatelessWidget {
  final String text;
  final int flex;
  final bool alignEnd;
  const _TH(this.text, {this.flex = 1, this.alignEnd = false});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(text,
              textAlign: alignEnd ? TextAlign.right : TextAlign.left,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8A8FA3),
                  letterSpacing: 0.3)),
        ),
      );
}

class _TD extends StatelessWidget {
  final Widget child;
  const _TD({required this.child});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: child,
      );
}

class _IconBtn extends StatelessWidget {
  final String icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _IconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6)),
            child: AppIcon(icon, size: 16, color: color),
          ),
        ),
      );
}

// ── Mobile List ───────────────────────────────────────────────────────────────

class _MobileList extends ConsumerWidget {
  final List<ExpenseEntryModel> entries;
  const _MobileList({required this.entries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final e = entries[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE7E9F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.expenseHeadName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(_fmtDate(e.createdAt),
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF8A8FA3))),
                    if (e.note != null && e.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(e.note!,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF5A5F73))),
                    ],
                  ],
                ),
              ),
              Text('Rs. ${_fmtAmt(e.amount)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _primary)),
              IconButton(
                icon: AppIcon(AppIcons.deleteOutline,
                    size: 18, color: Colors.red.shade400),
                onPressed: () => _confirmDelete(context, ref, e.id),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

Future<void> _confirmDelete(
    BuildContext context, WidgetRef ref, String id) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Expense?'),
      content: const Text(
          'This will remove the expense and reverse it from the cash counter.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirm != true || !context.mounted) return;
  final error = await ref.read(expenseProvider.notifier).deleteExpense(id);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(error == null ? 'Expense deleted.' : 'Error: $error'),
    backgroundColor: error == null ? Colors.green.shade700 : Colors.red.shade700,
    behavior: SnackBarBehavior.floating,
  ));
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _fmtAmt(double v) {
  if (v == v.truncate()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(2);
}

// ── Error / Empty views ─────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppIcon(AppIcons.errorOutline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: Color(0xFF8A8FA3))),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ]),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(AppIcons.receiptLongOutlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text('No expenses recorded yet',
                style: TextStyle(color: Color(0xFF8A8FA3))),
          ]),
    );
  }
}
