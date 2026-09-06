import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../superadmin/shared/current_head_office_provider.dart';
import '../../data/model/company_model.dart';
import '../providers/company_provider.dart';
import '../providers/company_state.dart';
import '../widgets/company_form_dialog.dart';

class CompaniesScreen extends ConsumerStatefulWidget {
  const CompaniesScreen({super.key});

  @override
  ConsumerState<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends ConsumerState<CompaniesScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user == null) return;
      ref.read(companyProvider.notifier).loadAllCompanies();
    });
  }

  String get _currentHeadOfficeId => ref.read(currentHeadOfficeIdProvider);

  @override
  Widget build(BuildContext context) {
    final companyState = ref.watch(companyProvider);
    // Keep the singleton head-office id resolving while this screen is open so
    // the Add/Edit dialog always has it ready.
    ref.watch(headOfficeIdProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;

    // Show snackbar on error
    ref.listen<CompanyState>(companyProvider, (_, next) {
      if (next.status == CompanyStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final filtered = companyState.companies.where((c) {
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.phoneNumber.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q) ||
          c.address.toLowerCase().contains(q);
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
                    const Text('Companies',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('${companyState.companies.length} total companies',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF8A8FA3))),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showForm(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Company'),
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
              decoration: _searchDecor(
                  'Search by name, phone, email or address...'),
            ),
          ),

          // Content
          Expanded(
            child: companyState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : companyState.status == CompanyStatus.error
                    ? _ErrorView(
                        message:
                            companyState.errorMessage ?? 'Error',
                        onRetry: () => ref
                            .read(companyProvider.notifier)
                            .loadAllCompanies(),
                      )
                    : filtered.isEmpty
                        ? const _EmptyView()
                        : isMobile
                            ? _MobileList(
                                companies: filtered,
                                onEdit: (c) =>
                                    _showForm(context, company: c),
                                onDelete: (c) =>
                                    _confirmDelete(context, c),
                              )
                            : _DesktopTable(
                                companies: filtered,
                                onEdit: (c) =>
                                    _showForm(context, company: c),
                                onDelete: (c) =>
                                    _confirmDelete(context, c),
                              ),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, {CompanyModel? company}) {
    showDialog(
      context: context,
      builder: (_) => CompanyFormDialog(
        company: company,
        headOfficeId: company?.headOfficeId ?? _currentHeadOfficeId,
        onSave: (c) => company == null
            ? ref.read(companyProvider.notifier).createCompany(c)
            : ref.read(companyProvider.notifier).updateCompany(c),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CompanyModel company) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Company'),
        content: Text('Delete "${company.name}"?'),
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
            onPressed: () {
              ref
                  .read(companyProvider.notifier)
                  .deleteCompany(company.id);
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
  final List<CompanyModel> companies;
  final Function(CompanyModel) onEdit;
  final Function(CompanyModel) onDelete;

  const _DesktopTable({
    required this.companies,
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
                  border: Border(
                      bottom: BorderSide(color: Color(0xFFE7E9F0))),
                ),
                child: const Row(children: [
                  _TH('Company Name', flex: 3),
                  _TH('Phone', flex: 2),
                  _TH('Email', flex: 3),
                  _TH('Address', flex: 3),
                  _TH('Opening Balance', flex: 2),
                  _TH('Actions', flex: 2),
                ]),
              ),
              // Rows
              Expanded(
                child: ListView.builder(
                  itemCount: companies.length,
                  itemBuilder: (_, i) {
                    final c = companies[i];
                    final isLast = i == companies.length - 1;
                    return Container(
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : const Border(
                                bottom: BorderSide(
                                    color: Color(0xFFE7E9F0))),
                      ),
                      child: Row(children: [
                        // Name + avatar
                        Expanded(
                          flex: 3,
                          child: _TD(
                              child: Row(children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: const Color(0xFFEAEFFD),
                              child: Text(
                                c.name.isNotEmpty
                                    ? c.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: Color(0xFF3E63DD),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(c.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ])),
                        ),
                        // Phone
                        Expanded(
                          flex: 2,
                          child: _TD(
                              child: Text(
                                  c.phoneNumber.isEmpty
                                      ? '—'
                                      : c.phoneNumber,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF8A8FA3)),
                                  overflow: TextOverflow.ellipsis)),
                        ),
                        // Email
                        Expanded(
                          flex: 3,
                          child: _TD(
                              child: Text(
                                  c.email.isEmpty ? '—' : c.email,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF8A8FA3)),
                                  overflow: TextOverflow.ellipsis)),
                        ),
                        // Address
                        Expanded(
                          flex: 3,
                          child: _TD(
                              child: Text(
                                  c.address.isEmpty ? '—' : c.address,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF8A8FA3)),
                                  overflow: TextOverflow.ellipsis)),
                        ),
                        // Opening balance
                        Expanded(
                          flex: 2,
                          child: _TD(
                              child: Text(
                                  'Rs. ${c.openingBalance.toStringAsFixed(0)}',
                                  style:
                                      const TextStyle(fontSize: 13))),
                        ),
                        // Actions
                        Expanded(
                          flex: 2,
                          child: _TD(
                              child: Row(children: [
                            _IconBtn(
                              icon: Icons.edit_outlined,
                              color: const Color(0xFF3E63DD),
                              tooltip: 'Edit',
                              onTap: () => onEdit(c),
                            ),
                            const SizedBox(width: 6),
                            _IconBtn(
                              icon: Icons.delete_outline,
                              color: Colors.redAccent,
                              tooltip: 'Delete',
                              onTap: () => onDelete(c),
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
  final List<CompanyModel> companies;
  final Function(CompanyModel) onEdit;
  final Function(CompanyModel) onDelete;

  const _MobileList({
    required this.companies,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: companies.length,
      itemBuilder: (_, i) {
        final c = companies[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE7E9F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFEAEFFD),
                    child: Text(
                        c.name.isNotEmpty
                            ? c.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Color(0xFF3E63DD),
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                        if (c.phoneNumber.isNotEmpty)
                          Text(c.phoneNumber,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8A8FA3))),
                        if (c.email.isNotEmpty)
                          Text(c.email,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8A8FA3))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      size: 14, color: Color(0xFF8A8FA3)),
                  const SizedBox(width: 4),
                  Text(
                      'Rs. ${c.openingBalance.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 13)),
                  if (c.address.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: Color(0xFF8A8FA3)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(c.address,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8A8FA3)),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _IconBtn(
                      icon: Icons.edit_outlined,
                      color: const Color(0xFF3E63DD),
                      tooltip: 'Edit',
                      onTap: () => onEdit(c)),
                  const SizedBox(width: 8),
                  _IconBtn(
                      icon: Icons.delete_outline,
                      color: Colors.redAccent,
                      tooltip: 'Delete',
                      onTap: () => onDelete(c)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

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
          child: Icon(icon, size: 16, color: color),
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
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined,
                size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text('No companies found',
                style: TextStyle(color: Color(0xFF8A8FA3))),
          ]),
    );
  }
}

InputDecoration _searchDecor(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
      prefixIcon: const Icon(Icons.search, color: Color(0xFF8A8FA3)),
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
