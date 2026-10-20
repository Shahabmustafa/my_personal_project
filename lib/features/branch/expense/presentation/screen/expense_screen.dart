import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widget/app_dropdown.dart';
import '../../data/model/expense_entry_model.dart';
import '../../data/model/expense_head_model.dart';
import '../provider/expense_provider.dart';
import '../../../../superadmin/report/presentation/widgets/report_date_filter_dialog.dart';
import '../../../../superadmin/report/presentation/widgets/report_summary_card.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
const _primary = Color(0xFFE56A00);

/// Superadmin ke Add Expense dialog mein branch choose karne ke liye.
class ExpenseBranchOption {
  final String id;
  final String name;
  const ExpenseBranchOption(this.id, this.name);
}

class ExpenseScreen extends ConsumerStatefulWidget {
  /// Null ho to logged-in branch ka expense. Superadmin yahan head office
  /// ya koi bhi branch deta hai.
  final ExpenseScope? scope;

  /// Header ke neeche dikhne wala widget (superadmin ka branch picker).
  final Widget? scopePicker;

  final String title;

  /// Di jaye to Add Expense dialog mein Branch dropdown dikhta hai.
  final List<ExpenseBranchOption>? branchOptions;

  /// Dialog se kisi branch mein expense save ho to us branch ka id.
  final ValueChanged<String>? onBranchSaved;

  const ExpenseScreen({
    super.key,
    this.scope,
    this.scopePicker,
    this.title = 'Expense',
    this.branchOptions,
    this.onBranchSaved,
  });

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  /// Null = All Heads.
  String? _headId;

  bool get _hasDateFilter => _startDate != null || _endDate != null;

  bool _inRange(ExpenseEntryModel e) {
    final d = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
    if (_startDate != null &&
        d.isBefore(
            DateTime(_startDate!.year, _startDate!.month, _startDate!.day))) {
      return false;
    }
    if (_endDate != null &&
        d.isAfter(DateTime(_endDate!.year, _endDate!.month, _endDate!.day))) {
      return false;
    }
    return true;
  }

  String _rangeLabel() {
    final s = _startDate == null ? '…' : _fmtDate(_startDate!);
    final e = _endDate == null ? '…' : _fmtDate(_endDate!);
    return '$s – $e';
  }

  Future<void> _pickDates() async {
    final result = await showDialog<(DateTime?, DateTime?)?>(
      context: context,
      builder: (_) => ReportDateFilterDialog(
          initialStart: _startDate, initialEnd: _endDate),
    );
    if (result != null) {
      setState(() {
        _startDate = result.$1;
        _endDate = result.$2;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ExpenseScope scope =
        widget.scope ?? ref.watch(currentBranchExpenseScopeProvider);
    final provider = expenseProvider(scope);
    final fullState = ref.watch(provider);
    final entries = fullState.entries
        .where((e) => _inRange(e) && (_headId == null || e.expenseHeadId == _headId))
        .toList();
    final state = fullState.copyWith(entries: entries);
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
                      Text(widget.title,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(
                          '${state.entries.length} entr${state.entries.length == 1 ? 'y' : 'ies'} · Total Rs. ${_fmtAmt(state.totalExpense)}',
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF8A8FA3))),
                    ],
                  ),
                ),
                if (_hasDateFilter)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: TextButton.icon(
                      onPressed: () => setState(() {
                        _startDate = null;
                        _endDate = null;
                      }),
                      icon: const AppIcon(AppIcons.clear, size: 16),
                      label: Text(_rangeLabel()),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: OutlinedButton.icon(
                    onPressed: _pickDates,
                    icon: const AppIcon(AppIcons.filterAltOutlined, size: 18),
                    label: const Text('Filter'),
                  ),
                ),
                Tooltip(
                  message: 'Refresh',
                  child: InkWell(
                    onTap: () => ref.read(provider.notifier).load(),
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
                  onPressed: scope.id.isEmpty && !scope.isAllBranches
                      ? null
                      : () => _openAddExpenseDialog(context, scope),
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

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (widget.scopePicker != null) widget.scopePicker!,
                SizedBox(
                  width: 320,
                  child: AppSearchDropdown<ExpenseHeadModel>(
                    label: 'Expense Head',
                    items: [
                      const ExpenseHeadModel(id: '', name: 'All Heads'),
                      ...fullState.heads,
                    ],
                    selectedItem: fullState.heads
                            .where((h) => h.id == _headId)
                            .firstOrNull ??
                        const ExpenseHeadModel(id: '', name: 'All Heads'),
                    itemLabel: (h) => h.name,
                    onChanged: (h) => setState(
                        () => _headId = (h == null || h.id.isEmpty) ? null : h.id),
                  ),
                ),
                if (_headId != null)
                  TextButton.icon(
                    onPressed: () => setState(() => _headId = null),
                    icon: const AppIcon(AppIcons.clear, size: 16),
                    label: const Text('Clear'),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: ReportSummaryCards(
              children: [
                ReportSummaryCard(
                  label: 'Total Expense',
                  value: 'Rs. ${_fmtAmt(state.totalExpense)}',
                  icon: AppIcons.receiptLongOutlined,
                  color: _primary,
                ),
                ReportSummaryCard(
                  label: 'Total Entries',
                  value: '${state.entries.length}',
                  icon: AppIcons.listOutlined,
                  color: const Color(0xFF3E63DD),
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
                            ref.read(provider.notifier).load(),
                      )
                    : state.entries.isEmpty
                        ? const _EmptyView()
                        : isMobile
                            ? _MobileList(scope: scope, entries: state.entries)
                            : _DesktopTable(
                                scope: scope, entries: state.entries),
          ),
        ],
      ),
    );
  }

  void _openAddExpenseDialog(BuildContext context, ExpenseScope scope) {
    showDialog(
      context: context,
      builder: (_) => _AddExpenseDialog(
        scope: scope,
        branchOptions: widget.branchOptions,
      ),
    ).then((savedBranchId) {
      if (savedBranchId is String) widget.onBranchSaved?.call(savedBranchId);
    });
  }
}

// ── Add / Edit Expense Dialog ───────────────────────────────────────────────

class _AddExpenseDialog extends ConsumerStatefulWidget {
  /// Null ho to naya expense, warna isi entry ko edit karta hai.
  final ExpenseScope scope;
  final ExpenseEntryModel? entry;
  final List<ExpenseBranchOption>? branchOptions;
  const _AddExpenseDialog({
    required this.scope,
    this.entry,
    this.branchOptions,
  });

  @override
  ConsumerState<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends ConsumerState<_AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  ExpenseHeadModel? _selectedHead;
  ExpenseBranchOption? _selectedBranch;
  String? _branchError;
  String? _headError;
  bool _submitting = false;

  bool get _isEdit => widget.entry != null;

  /// Branch dropdown sirf naye expense pe; edit wali entry ki branch fixed.
  bool get _showBranch => !_isEdit && widget.branchOptions != null;

  @override
  void initState() {
    super.initState();
    for (final b in widget.branchOptions ?? const <ExpenseBranchOption>[]) {
      if (b.id == widget.scope.id) _selectedBranch = b;
    }
    final e = widget.entry;
    if (e != null) {
      _amountCtrl.text = _fmtAmt(e.amount);
      _noteCtrl.text = e.note ?? '';
      _selectedHead = ExpenseHeadModel(id: e.expenseHeadId, name: e.expenseHeadName);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heads = ref.watch(expenseProvider(widget.scope)).heads;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        const AppIcon(AppIcons.receiptLongOutlined, color: _primary, size: 22),
        const SizedBox(width: 8),
        Text(_isEdit ? 'Edit Expense' : 'Add Expense',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ]),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showBranch) ...[
                AppSearchDropdown<ExpenseBranchOption>(
                  label: 'Branch',
                  items: widget.branchOptions!,
                  selectedItem: _selectedBranch,
                  itemLabel: (b) => b.name,
                  errorText: _branchError,
                  isRequired: true,
                  onChanged: (b) => setState(() {
                    _selectedBranch = b;
                    _branchError = null;
                  }),
                ),
                const SizedBox(height: 12),
              ],
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
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                ],
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
    setState(() {
      _headError = _selectedHead == null ? 'Select an expense head' : null;
      _branchError =
          _showBranch && _selectedBranch == null ? 'Select a branch' : null;
    });
    if (!formValid || _selectedHead == null || _branchError != null) return;
    setState(() => _submitting = true);
    final target = _showBranch
        ? ExpenseScope.branch(_selectedBranch!.id)
        : widget.scope;
    final notifier = ref.read(expenseProvider(target).notifier);
    final amount = double.parse(_amountCtrl.text);
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
    final error = _isEdit
        ? await notifier.updateExpense(
            entry: widget.entry!,
            expenseHeadId: _selectedHead!.id,
            amount: amount,
            note: note,
          )
        : await notifier.addExpense(
            expenseHeadId: _selectedHead!.id,
            amount: amount,
            note: note,
          );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error == null) {
      Navigator.pop(context, _showBranch ? target.id : null);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error == null
          ? (_isEdit ? 'Expense updated.' : 'Expense added.')
          : 'Error: $error'),
      backgroundColor: error == null ? Colors.green.shade700 : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  void _openAddHeadDialog(BuildContext context) {
    showDialog<ExpenseHeadModel?>(
      context: context,
      builder: (_) => _AddHeadDialog(scope: widget.scope),
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
  final ExpenseScope scope;
  const _AddHeadDialog({required this.scope});

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
        await ref.read(expenseProvider(widget.scope).notifier).addHead(name: name);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _submitting = false;
        _error = error;
      });
      return;
    }
    final head = ref
        .read(expenseProvider(widget.scope))
        .heads
        .firstWhere((h) => h.name == name, orElse: () => ExpenseHeadModel(id: '', name: name));
    Navigator.pop(context, head);
  }
}

// ── Desktop Table ────────────────────────────────────────────────────────────

class _DesktopTable extends ConsumerWidget {
  final ExpenseScope scope;
  final List<ExpenseEntryModel> entries;
  const _DesktopTable({required this.scope, required this.entries});

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
                child: Row(children: [
                  const _TH('#', flex: 1),
                  const _TH('Date', flex: 2),
                  if (scope.isAllBranches) const _TH('Branch', flex: 3),
                  const _TH('Expense Head', flex: 3),
                  const _TH('Note', flex: 4),
                  const _TH('Amount', flex: 2, alignEnd: true),
                  const _TH('', flex: 2),
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
                          if (scope.isAllBranches)
                            Expanded(
                              flex: 3,
                              child: _TD(
                                child: Text(e.branchName ?? '—',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis),
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
                            flex: 2,
                            child: _TD(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  _IconBtn(
                                    icon: AppIcons.editOutlined,
                                    color: _primary,
                                    tooltip: 'Edit',
                                    onTap: () => _openEditDialog(context, scope, e),
                                  ),
                                  const SizedBox(width: 6),
                                  _IconBtn(
                                    icon: AppIcons.deleteOutline,
                                    color: Colors.red.shade400,
                                    tooltip: 'Delete',
                                    onTap: () =>
                                        _confirmDelete(context, ref, scope, e),
                                  ),
                                ],
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
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6)),
            child: AppIcon(icon, size: 16, color: color),
          ),
        ),
      );
}

// ── Mobile List ───────────────────────────────────────────────────────────────

class _MobileList extends ConsumerWidget {
  final ExpenseScope scope;
  final List<ExpenseEntryModel> entries;
  const _MobileList({required this.scope, required this.entries});

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
                    Text(
                        scope.isAllBranches && e.branchName != null
                            ? '${e.branchName} · ${_fmtDate(e.createdAt)}'
                            : _fmtDate(e.createdAt),
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
                icon: const AppIcon(AppIcons.editOutlined,
                    size: 18, color: _primary),
                onPressed: () => _openEditDialog(context, scope, e),
              ),
              IconButton(
                icon: AppIcon(AppIcons.deleteOutline,
                    size: 18, color: Colors.red.shade400),
                onPressed: () => _confirmDelete(context, ref, scope, e),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

void _openEditDialog(
    BuildContext context, ExpenseScope scope, ExpenseEntryModel entry) {
  showDialog(
    context: context,
    builder: (_) => _AddExpenseDialog(scope: scope, entry: entry),
  );
}

Future<void> _confirmDelete(BuildContext context, WidgetRef ref,
    ExpenseScope scope, ExpenseEntryModel entry) async {
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
  final error =
      await ref.read(expenseProvider(scope).notifier).deleteExpense(entry);
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
