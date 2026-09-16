import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/bank_head_model.dart';
import '../providers/bank_providers.dart';
import '../widgets/bank_head_card.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';
class BankHeadsScreen extends ConsumerStatefulWidget {
  const BankHeadsScreen({super.key});

  @override
  ConsumerState<BankHeadsScreen> createState() => _BankHeadsScreenState();
}

class _BankHeadsScreenState extends ConsumerState<BankHeadsScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(bankHeadsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final banksAsync = ref.watch(bankHeadsProvider);
    final isMobile   = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: banksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(bankHeadsProvider),
        ),
        data: (banks) {
          final filtered = banks
              .where((b) => b.bankName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bank Heads',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                        Text('${banks.length} total banks',
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF8A8FA3))),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _showAddDialog(context),
                      icon: const AppIcon(AppIcons.add, size: 18, color: Colors.white),
                      label: const Text('Add Bank'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3E63DD),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Search ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: _searchDecor('Search banks...'),
                ),
              ),

              // ── Content ───────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? const _EmptyView()
                    : isMobile
                        ? _MobileList(
                            banks: filtered,
                            onDelete: (b) => _confirmDelete(context, b),
                          )
                        : _DesktopTable(
                            banks: filtered,
                            onDelete: (b) => _confirmDelete(context, b),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Add Dialog ────────────────────────────────────────────────────────────

  void _showAddDialog(BuildContext context) {
    final ctrl    = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Bank Head',
            style: TextStyle(fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: 360,
          child: Form(
            key: formKey,
            child: TextFormField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Bank Name *',
                prefixIcon: const TextFieldIcon(AppIcons.accountBalanceOutlined,
                    size: 24, color: Color(0xFF8A8FA3)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: Color(0xFF3E63DD), width: 1.5)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Bank name is required'
                  : null,
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3E63DD),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              try {
                await ref
                    .read(bankRepositoryProvider)
                    .addBankHead(ctrl.text.trim());
                ref.invalidate(bankHeadsProvider);
                if (context.mounted) {
                  _snack(context, 'Bank added successfully!', Colors.green);
                }
              } catch (e) {
                if (context.mounted) {
                  _snack(context, 'Error: $e', Colors.red);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── Confirm Delete ─────────────────────────────────────────────────────────

  void _confirmDelete(BuildContext context, BankHeadModel bank) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Bank?'),
        content: Text('Delete "${bank.bankName}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(bankRepositoryProvider)
                    .removeBankHead(bank.id);
                ref.invalidate(bankHeadsProvider);
                if (context.mounted) {
                  _snack(context, 'Bank deleted successfully!', Colors.orange);
                }
              } catch (e) {
                if (context.mounted) {
                  _snack(context, 'Error: $e', Colors.red);
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _snack(BuildContext ctx, String msg, Color color) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }
}

// ── Desktop Table ──────────────────────────────────────────────────────────────

class _DesktopTable extends StatelessWidget {
  final List<BankHeadModel> banks;
  final Function(BankHeadModel) onDelete;

  const _DesktopTable({required this.banks, required this.onDelete});

  @override
  Widget build(BuildContext context) {
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
                  border:
                      Border(bottom: BorderSide(color: Color(0xFFE7E9F0))),
                ),
                child: Row(children: [
                  _TH('#',           flex: 1),
                  _TH('Bank Name',   flex: 5),
                  _TH('Created At',  flex: 3),
                  _TH('Action',      flex: 2),
                ]),
              ),
              // Rows
              Expanded(
                child: ListView.builder(
                  itemCount: banks.length,
                  itemBuilder: (_, i) {
                    final b      = banks[i];
                    final isLast = i == banks.length - 1;
                    return Container(
                      decoration: BoxDecoration(
                        color: i.isEven
                            ? Colors.white
                            : const Color(0xFFF7F8FC),
                        border: isLast
                            ? null
                            : const Border(
                                bottom: BorderSide(
                                    color: Color(0xFFE7E9F0))),
                      ),
                      child: Row(children: [
                        // #
                        Expanded(
                          flex: 1,
                          child: _TD(
                              child: Text('${i + 1}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF8A8FA3)))),
                        ),
                        // Name
                        Expanded(
                          flex: 5,
                          child: _TD(
                            child: Row(children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAEFFD),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const AppIcon(
                                    AppIcons.accountBalanceOutlined,
                                    size: 16,
                                    color: Color(0xFF3E63DD)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(b.bankName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ]),
                          ),
                        ),
                        // Date
                        Expanded(
                          flex: 3,
                          child: _TD(
                            child: Text(
                              _fmt(b.createdAt),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8A8FA3)),
                            ),
                          ),
                        ),
                        // Delete
                        Expanded(
                          flex: 2,
                          child: _TD(
                            child: _IconBtn(
                              icon: AppIcons.deleteOutline,
                              color: Colors.redAccent,
                              tooltip: 'Delete',
                              onTap: () => onDelete(b),
                            ),
                          ),
                        ),
                      ]),
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

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}

// ── Mobile List ───────────────────────────────────────────────────────────────

class _MobileList extends StatelessWidget {
  final List<BankHeadModel> banks;
  final Function(BankHeadModel) onDelete;

  const _MobileList({required this.banks, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: banks.length,
      itemBuilder: (_, i) => BankHeadCard(
        bank: banks[i],
        onDelete: () => onDelete(banks[i]),
      ),
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────────────

class _TH extends StatelessWidget {
  final String text;
  final int flex;
  const _TH(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(text,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: child);
}

class _IconBtn extends StatelessWidget {
  final String icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon,
      required this.color,
      required this.tooltip,
      required this.onTap});

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

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const AppIcon(AppIcons.errorOutline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Color(0xFF8A8FA3))),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AppIcon(AppIcons.accountBalanceOutlined,
              size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text('No banks found',
              style: TextStyle(color: Color(0xFF8A8FA3))),
        ]),
      );
}

InputDecoration _searchDecor(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
      prefixIcon: const TextFieldIcon(AppIcons.search, size: 24, color: Color(0xFF8A8FA3)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF3E63DD), width: 1.5)),
    );
