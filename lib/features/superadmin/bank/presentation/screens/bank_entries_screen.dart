import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/bank_entry_model.dart';
import '../providers/bank_providers.dart';
import '../widgets/bank_entry_card.dart';
import '../widgets/bank_entry_form_dialog.dart';

class BankEntriesScreen extends ConsumerStatefulWidget {
  const BankEntriesScreen({super.key});

  @override
  ConsumerState<BankEntriesScreen> createState() => _BankEntriesScreenState();
}

class _BankEntriesScreenState extends ConsumerState<BankEntriesScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(bankEntriesProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(bankEntriesProvider);
    final isMobile     = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(bankEntriesProvider),
        ),
        data: (entries) {
          final filtered = entries.where((e) {
            final q = _searchQuery.toLowerCase();
            return e.bankName.toLowerCase().contains(q)      ||
                   e.branchName.toLowerCase().contains(q)    ||
                   e.branchAddress.toLowerCase().contains(q) ||
                   e.accountNumber.toLowerCase().contains(q);
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bank Entries',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                        Text('${entries.length} total entries',
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF8A8FA3))),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _showAddDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Entry'),
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

              // ── Search ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration:
                      _searchDecor('Search by bank, branch, account...'),
                ),
              ),

              // ── Content ─────────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? const _EmptyView()
                    : isMobile
                        ? _MobileList(
                            entries: filtered,
                            onDelete: (e) => _confirmDelete(context, e),
                          )
                        : _DesktopTable(
                            entries: filtered,
                            onDelete: (e) => _confirmDelete(context, e),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Add Dialog ─────────────────────────────────────────────────────────────

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BankEntryFormDialog(
        onSave: ({
          required bankId,
          required branchId,
          required accountNumber,
          required openingBalance,
        }) async {
          try {
            await ref.read(bankRepositoryProvider).addBankEntry(
                  bankId:         bankId,
                  branchId:       branchId,
                  accountNumber:  accountNumber,
                  openingBalance: openingBalance,
                );
            ref.invalidate(bankEntriesProvider);
            if (context.mounted) {
              _snack(context, 'Bank entry added successfully!', Colors.green);
            }
          } catch (e) {
            if (context.mounted) {
              _snack(context, 'Error: $e', Colors.red);
            }
          }
        },
      ),
    );
  }

  // ── Confirm Delete ─────────────────────────────────────────────────────────

  void _confirmDelete(BuildContext context, BankEntryModel entry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Entry?'),
        content: Text(
            'Delete the entry for "${entry.bankName}" – ${entry.branchName}?'),
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
                    .removeBankEntry(entry.id);
                ref.invalidate(bankEntriesProvider);
                if (context.mounted) {
                  _snack(context, 'Entry deleted successfully!', Colors.orange);
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

// ── Desktop Table ─────────────────────────────────────────────────────────────

class _DesktopTable extends StatelessWidget {
  final List<BankEntryModel> entries;
  final Function(BankEntryModel) onDelete;

  const _DesktopTable({required this.entries, required this.onDelete});

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
              // Header row
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F8FC),
                  border: Border(
                      bottom: BorderSide(color: Color(0xFFE7E9F0))),
                ),
                child: Row(children: [
                  _TH('#',               flex: 1),
                  _TH('Bank',            flex: 3),
                  _TH('Branch',          flex: 3),
                  _TH('Address',         flex: 4),
                  _TH('Account No.',     flex: 3),
                  _TH('Opening Balance', flex: 3),
                  _TH('Date',            flex: 2),
                  _TH('Action',          flex: 2),
                ]),
              ),
              // Data rows
              Expanded(
                child: ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (_, i) {
                    final e      = entries[i];
                    final isLast = i == entries.length - 1;
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
                                    color: Color(0xFF8A8FA3))),
                          ),
                        ),
                        // Bank
                        Expanded(
                          flex: 3,
                          child: _TD(
                            child: Row(children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAEFFD),
                                  borderRadius:
                                      BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                    Icons.account_balance_outlined,
                                    size: 15,
                                    color: Color(0xFF3E63DD)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e.bankName.isEmpty ? '—' : e.bankName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ]),
                          ),
                        ),
                        // Branch name
                        Expanded(
                          flex: 3,
                          child: _TD(
                            child: Row(children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF5E6),
                                  borderRadius:
                                      BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                    Icons.store_outlined,
                                    size: 15,
                                    color: Color(0xFF2E7D32)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e.branchName.isEmpty
                                      ? '—'
                                      : e.branchName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ]),
                          ),
                        ),
                        // Address + city
                        Expanded(
                          flex: 4,
                          child: _TD(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (e.branchAddress.isNotEmpty)
                                  _MiniRow(
                                      icon: Icons.location_on_outlined,
                                      text: e.branchAddress),
                                if (e.branchCity.isNotEmpty)
                                  _MiniRow(
                                      icon: Icons.location_city_outlined,
                                      text: e.branchCity),
                                if (e.branchAddress.isEmpty &&
                                    e.branchCity.isEmpty)
                                  const Text('—',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF8A8FA3))),
                              ],
                            ),
                          ),
                        ),
                        // Account number
                        Expanded(
                          flex: 3,
                          child: _TD(
                            child: Text(
                              e.accountNumber.isEmpty
                                  ? '—'
                                  : e.accountNumber,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2D2D3A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        // Opening balance
                        Expanded(
                          flex: 3,
                          child: _TD(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAEFFD),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Rs. ${e.openingBalance.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Color(0xFF3E63DD),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Date
                        Expanded(
                          flex: 2,
                          child: _TD(
                            child: Text(
                              _fmt(e.createdAt),
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
                              icon: Icons.delete_outline,
                              color: Colors.redAccent,
                              tooltip: 'Delete',
                              onTap: () => onDelete(e),
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
  final List<BankEntryModel> entries;
  final Function(BankEntryModel) onDelete;

  const _MobileList({required this.entries, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: entries.length,
      itemBuilder: (_, i) => BankEntryCard(
        entry: entries[i],
        onDelete: () => onDelete(entries[i]),
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _TH extends StatelessWidget {
  final String text;
  final int flex;
  const _TH(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: child);
}

class _MiniRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MiniRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 11, color: const Color(0xFF8A8FA3)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF8A8FA3)),
              overflow: TextOverflow.ellipsis),
        ),
      ]);
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
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
            child: Icon(icon, size: 16, color: color),
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
        child:
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline,
              size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: Color(0xFF8A8FA3))),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: onRetry, child: const Text('Retry')),
        ]),
      );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => Center(
        child:
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.account_balance_outlined,
              size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text('No entries found',
              style: TextStyle(color: Color(0xFF8A8FA3))),
        ]),
      );
}

InputDecoration _searchDecor(String hint) => InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
      prefixIcon:
          const Icon(Icons.search, color: Color(0xFF8A8FA3)),
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
