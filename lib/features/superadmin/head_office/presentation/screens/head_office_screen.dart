import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/model/head_office_model.dart';
import '../providers/head_office_provider.dart';
import '../providers/head_office_state.dart';
import '../widgets/head_office_card.dart';
import '../widgets/head_office_form_dialog.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
class HeadOfficeScreen extends ConsumerStatefulWidget {
  const HeadOfficeScreen({super.key});

  @override
  ConsumerState<HeadOfficeScreen> createState() => _HeadOfficeScreenState();
}

class _HeadOfficeScreenState extends ConsumerState<HeadOfficeScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(headOfficeProvider.notifier).loadAllHeadOffices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final headOfficeState = ref.watch(headOfficeProvider);
    final canEdit = ref.watch(authProvider).user?.canManageHeadOffice ?? false;
    final isMobile = MediaQuery.of(context).size.width < 768;

    final filtered = headOfficeState.headOffices.where((h) {
      final q = _searchQuery.toLowerCase();
      return h.headOfficeName.toLowerCase().contains(q) ||
          h.city.toLowerCase().contains(q) ||
          h.address.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Head Offices',
                        style:
                            TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('${headOfficeState.headOffices.length} total head offices',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF8A8FA3))),
                  ],
                ),
                const Spacer(),
                // Sirf ek hi head office allowed hai — jab tak koi head office
                // maujood nahi tab hi "Add" button dikhao.
                if (canEdit && headOfficeState.headOffices.isEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _showForm(context),
                    icon: const AppIcon(AppIcons.add, size: 18),
                    label: const Text('Add Head Office'),
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

          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: _searchDecor('Search head offices...'),
            ),
          ),

          // Content
          Expanded(
            child: headOfficeState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : headOfficeState.status == HeadOfficeStatus.error
                    ? _ErrorView(
                        message: headOfficeState.errorMessage ?? 'Error',
                        onRetry: () => ref
                            .read(headOfficeProvider.notifier)
                            .loadAllHeadOffices(),
                      )
                    : filtered.isEmpty
                        ? const _EmptyView()
                        : isMobile
                            ? _MobileList(
                                headOffices: filtered,
                                canEdit: canEdit,
                                onEdit: (h) =>
                                    _showForm(context, headOffice: h),
                                onDelete: (h) => _confirmDelete(context, h),
                              )
                            : _DesktopTable(
                                headOffices: filtered,
                                canEdit: canEdit,
                                onEdit: (h) =>
                                    _showForm(context, headOffice: h),
                                onDelete: (h) => _confirmDelete(context, h),
                              ),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, {HeadOfficeModel? headOffice}) {
    showDialog(
      context: context,
      builder: (_) => HeadOfficeFormDialog(
        headOffice: headOffice,
        onSave: (h) => headOffice == null
            ? ref.read(headOfficeProvider.notifier).createHeadOffice(h)
            : ref.read(headOfficeProvider.notifier).updateHeadOffice(h),
      ),
    );
  }

  void _confirmDelete(BuildContext context, HeadOfficeModel headOffice) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Head Office'),
        content: Text('Delete "${headOffice.headOfficeName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              ref
                  .read(headOfficeProvider.notifier)
                  .deleteHeadOffice(headOffice.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Desktop Table ─────────────────────────────────────────────────────────────

class _DesktopTable extends StatelessWidget {
  final List<HeadOfficeModel> headOffices;
  final bool canEdit;
  final Function(HeadOfficeModel) onEdit;
  final Function(HeadOfficeModel) onDelete;

  const _DesktopTable({
    required this.headOffices,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

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
                  border: Border(bottom: BorderSide(color: Color(0xFFE7E9F0))),
                ),
                child: Row(children: [
                  _TH('Head Office Name', flex: 3),
                  _TH('City', flex: 2),
                  _TH('Address', flex: 4),
                  _TH('Phone', flex: 2),
                  _TH('Status', flex: 2),
                  if (canEdit) _TH('Actions', flex: 2),
                ]),
              ),
              // Rows
              Expanded(
                child: ListView.builder(
                  itemCount: headOffices.length,
                  itemBuilder: (_, i) {
                    final h = headOffices[i];
                    final isLast = i == headOffices.length - 1;
                    return Container(
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : const Border(
                                bottom:
                                    BorderSide(color: Color(0xFFE7E9F0))),
                      ),
                      child: Row(children: [
                        // Name with icon
                        Expanded(
                          flex: 3,
                          child: _TD(
                              child: Row(children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAEFFD),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const AppIcon(AppIcons.businessOutlined,
                                  color: Color(0xFF3E63DD), size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(h.headOfficeName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ])),
                        ),
                        // City
                        Expanded(
                          flex: 2,
                          child: _TD(
                              child: Text(
                            h.city.isEmpty ? '—' : h.city,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF8A8FA3)),
                            overflow: TextOverflow.ellipsis,
                          )),
                        ),
                        // Address
                        Expanded(
                          flex: 4,
                          child: _TD(
                              child: Text(
                            h.address.isEmpty ? '—' : h.address,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF8A8FA3)),
                            overflow: TextOverflow.ellipsis,
                          )),
                        ),
                        // Phone
                        Expanded(
                          flex: 2,
                          child: _TD(
                              child: Text(
                            h.phoneNumber.isEmpty ? '—' : h.phoneNumber,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF8A8FA3)),
                            overflow: TextOverflow.ellipsis,
                          )),
                        ),
                        // Status
                        Expanded(
                          flex: 2,
                          child: _TD(child: _StatusPill(isActive: h.isActive)),
                        ),
                        // Actions
                        if (canEdit)
                          Expanded(
                            flex: 2,
                            child: _TD(
                                child: Row(children: [
                              _IconBtn(
                                icon: AppIcons.editOutlined,
                                color: const Color(0xFF3E63DD),
                                tooltip: 'Edit',
                                onTap: () => onEdit(h),
                              ),
                              const SizedBox(width: 8),
                              _IconBtn(
                                icon: AppIcons.deleteOutline,
                                color: Colors.redAccent,
                                tooltip: 'Delete',
                                onTap: () => onDelete(h),
                              ),
                            ])),
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
}

// ── Mobile List ───────────────────────────────────────────────────────────────

class _MobileList extends StatelessWidget {
  final List<HeadOfficeModel> headOffices;
  final bool canEdit;
  final Function(HeadOfficeModel) onEdit;
  final Function(HeadOfficeModel) onDelete;

  const _MobileList({
    required this.headOffices,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: headOffices.length,
      itemBuilder: (_, i) => HeadOfficeCard(
        headOffice: headOffices[i],
        canEdit: canEdit,
        onEdit: () => onEdit(headOffices[i]),
        onDelete: () => onDelete(headOffices[i]),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _TH extends StatelessWidget {
  final String text;
  final int flex;
  const _TH(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
}

class _TD extends StatelessWidget {
  final Widget child;
  const _TD({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: child,
    );
  }
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
  Widget build(BuildContext context) {
    return Tooltip(
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
}

class _StatusPill extends StatelessWidget {
  final bool isActive;
  const _StatusPill({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFEAF5E6) : const Color(0xFFFEECEC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AppIcon(AppIcons.businessOutlined, size: 48, color: Colors.grey[300]),
        const SizedBox(height: 12),
        const Text('No head offices found',
            style: TextStyle(color: Color(0xFF8A8FA3))),
      ]),
    );
  }
}

InputDecoration _searchDecor(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
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
          borderSide: const BorderSide(color: Color(0xFF3E63DD), width: 1.5)),
    );
