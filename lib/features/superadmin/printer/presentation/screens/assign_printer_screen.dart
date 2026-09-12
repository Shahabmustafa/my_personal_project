import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/assign_printer_model.dart';
import '../providers/printer_providers.dart';
import '../widgets/assign_printer_card.dart';
import '../widgets/assign_printer_form_dialog.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
class AssignPrinterScreen extends ConsumerStatefulWidget {
  const AssignPrinterScreen({super.key});

  @override
  ConsumerState<AssignPrinterScreen> createState() =>
      _AssignPrinterScreenState();
}

class _AssignPrinterScreenState extends ConsumerState<AssignPrinterScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(assignedPrintersProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final assignAsync = ref.watch(assignedPrintersProvider);
    final isMobile    = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: assignAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(assignedPrintersProvider),
        ),
        data: (items) {
          final filtered = items.where((item) {
            final q = _searchQuery.toLowerCase();
            return item.printerName.toLowerCase().contains(q) ||
                item.branchName.toLowerCase().contains(q) ||
                item.branchCity.toLowerCase().contains(q) ||
                item.printerPhone.toLowerCase().contains(q);
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
                        const Text('Assign Printer',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        Text('${items.length} total assignments',
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF8A8FA3))),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _showAddDialog(context),
                      icon: const AppIcon(AppIcons.add, size: 18),
                      label: const Text('Assign Printer'),
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
                  decoration: _searchDecor(
                      'Search by printer, branch, phone...'),
                ),
              ),

              // ── Content ─────────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? const _EmptyView()
                    : isMobile
                        ? _MobileList(
                            items: filtered,
                            onDelete: (item) =>
                                _confirmDelete(context, item),
                          )
                        : _DesktopTable(
                            items: filtered,
                            onDelete: (item) =>
                                _confirmDelete(context, item),
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
      builder: (_) => AssignPrinterFormDialog(
        onSave: ({
          required branchId,
          required printerHeadId,
        }) async {
          try {
            await ref.read(printerRepositoryProvider).assignPrinter(
                  branchId:      branchId,
                  printerHeadId: printerHeadId,
                );
            ref.invalidate(assignedPrintersProvider);
            if (context.mounted) {
              _snack(context, 'Printer assigned successfully!', Colors.green);
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

  void _confirmDelete(BuildContext context, AssignPrinterModel item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Assignment?'),
        content: Text(
            'Remove the assignment of "${item.printerName}" – ${item.branchName}?'),
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
                    .read(printerRepositoryProvider)
                    .removeAssignPrinter(item.id);
                ref.invalidate(assignedPrintersProvider);
                if (context.mounted) {
                  _snack(
                      context, 'Assignment removed successfully!', Colors.orange);
                }
              } catch (e) {
                if (context.mounted) {
                  _snack(context, 'Error: $e', Colors.red);
                }
              }
            },
            child: const Text('Remove'),
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
  final List<AssignPrinterModel> items;
  final Function(AssignPrinterModel) onDelete;

  const _DesktopTable({required this.items, required this.onDelete});

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
                  border:
                      Border(bottom: BorderSide(color: Color(0xFFE7E9F0))),
                ),
                child: Row(children: [
                  _TH('#',             flex: 1),
                  _TH('Printer',       flex: 3),
                  _TH('Branch',        flex: 3),
                  _TH('Location',      flex: 4),
                  _TH('Phone',         flex: 3),
                  _TH('Date',          flex: 2),
                  _TH('Action',        flex: 2),
                ]),
              ),
              // Data rows
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item   = items[i];
                    final isLast = i == items.length - 1;
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
                        // Printer
                        Expanded(
                          flex: 3,
                          child: _TD(
                            child: Row(children: [
                              _printerAvatar(item.printerImageUrl),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.printerName.isEmpty
                                      ? '—'
                                      : item.printerName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ]),
                          ),
                        ),
                        // Branch
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
                                child: const AppIcon(
                                    AppIcons.storeOutlined,
                                    size: 15,
                                    color: Color(0xFF2E7D32)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.branchName.isEmpty
                                      ? '—'
                                      : item.branchName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ]),
                          ),
                        ),
                        // Location
                        Expanded(
                          flex: 4,
                          child: _TD(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (item.branchAddress.isNotEmpty)
                                  _MiniRow(
                                      icon: AppIcons.locationOnOutlined,
                                      text: item.branchAddress),
                                if (item.branchCity.isNotEmpty)
                                  _MiniRow(
                                      icon: AppIcons.locationCityOutlined,
                                      text: item.branchCity),
                                if (item.branchAddress.isEmpty &&
                                    item.branchCity.isEmpty)
                                  const Text('—',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF8A8FA3))),
                              ],
                            ),
                          ),
                        ),
                        // Phone
                        Expanded(
                          flex: 3,
                          child: _TD(
                            child: Text(
                              item.printerPhone.isEmpty
                                  ? '—'
                                  : item.printerPhone,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2D2D3A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        // Date
                        Expanded(
                          flex: 2,
                          child: _TD(
                            child: Text(
                              _fmt(item.createdAt),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8A8FA3)),
                            ),
                          ),
                        ),
                        // Action
                        Expanded(
                          flex: 2,
                          child: _TD(
                            child: _IconBtn(
                              icon: AppIcons.deleteOutline,
                              color: Colors.redAccent,
                              tooltip: 'Remove',
                              onTap: () => onDelete(item),
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

  Widget _printerAvatar(String imageUrl) {
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          imageUrl,
          width: 28,
          height: 28,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultPrinterIcon(),
        ),
      );
    }
    return _defaultPrinterIcon();
  }

  Widget _defaultPrinterIcon() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFEAEFFD),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const AppIcon(AppIcons.printOutlined,
          size: 15, color: Color(0xFF3E63DD)),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}

// ── Mobile List ───────────────────────────────────────────────────────────────

class _MobileList extends StatelessWidget {
  final List<AssignPrinterModel> items;
  final Function(AssignPrinterModel) onDelete;

  const _MobileList({required this.items, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: items.length,
      itemBuilder: (_, i) => AssignPrinterCard(
        item: items[i],
        onDelete: () => onDelete(items[i]),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: child);
}

class _MiniRow extends StatelessWidget {
  final String icon;
  final String text;
  const _MiniRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(children: [
        AppIcon(icon, size: 11, color: const Color(0xFF8A8FA3)),
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
        child:
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const AppIcon(AppIcons.errorOutline,
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
          AppIcon(AppIcons.printDisabledOutlined,
              size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text('No assignments found',
              style: TextStyle(color: Color(0xFF8A8FA3))),
        ]),
      );
}

InputDecoration _searchDecor(String hint) => InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
      prefixIcon: const Center(child: AppIcon(AppIcons.search, size: 16, color: Color(0xFF8A8FA3))),
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
