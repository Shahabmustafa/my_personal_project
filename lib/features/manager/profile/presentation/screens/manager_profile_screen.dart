import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../superadmin/employee_salary/data/models/employee_salary_history_model.dart';
import '../../../../superadmin/employee_salary/data/models/employee_salary_model.dart';
import '../providers/manager_profile_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';

class ManagerProfileScreen extends ConsumerWidget {
  const ManagerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final profileAsync = ref.watch(managerProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(managerProfileProvider);
          await ref.read(managerProfileProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('My Profile',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              const Text('Aapki salary, commission aur sale ka khulasa',
                  style: TextStyle(fontSize: 13, color: Color(0xFF8A8FA3))),
              const SizedBox(height: 20),
              _ProfileHeaderCard(
                username: user?.username ?? '',
                email: user?.email ?? '',
                phone: user?.phoneNumber ?? '',
                roleLabel: user?.roleDisplayName ?? '',
                branchName: profileAsync.asData?.value?.branchName ?? '',
              ),
              const SizedBox(height: 20),
              profileAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(children: [
                      const AppIcon(AppIcons.errorOutline,
                          size: 40, color: Colors.redAccent),
                      const SizedBox(height: 10),
                      Text('Error: $e',
                          style: const TextStyle(color: Color(0xFF8A8FA3))),
                    ]),
                  ),
                ),
                data: (salary) {
                  if (salary == null) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'Abhi tak koi salary/commission record set nahi hua.\n'
                          'Apne admin se rabta karein.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF8A8FA3)),
                        ),
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatGrid(salary: salary),
                      const SizedBox(height: 20),
                      _SalaryHistoryCard(employeeSalaryId: salary.id),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header card ──────────────────────────────────────────────────────────

class _ProfileHeaderCard extends StatelessWidget {
  final String username;
  final String email;
  final String phone;
  final String roleLabel;
  final String branchName;

  const _ProfileHeaderCard({
    required this.username,
    required this.email,
    required this.phone,
    required this.roleLabel,
    required this.branchName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E9F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 480;
        final avatar = Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3E63DD), Color(0xFF5B7FEF)],
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            username.isNotEmpty ? username[0].toUpperCase() : '?',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          ),
        );

        final info = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(username.isEmpty ? '—' : username,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEAEFFD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(roleLabel,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3E63DD))),
            ),
            const SizedBox(height: 10),
            _InfoRow(icon: AppIcons.storefrontOutlined, text: branchName),
            const SizedBox(height: 4),
            _InfoRow(icon: AppIcons.emailOutlined, text: email),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              _InfoRow(icon: AppIcons.badgeOutlined, text: phone),
            ],
          ],
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [avatar, const SizedBox(height: 14), info],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [avatar, const SizedBox(width: 16), Expanded(child: info)],
        );
      }),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(icon, size: 14, color: const Color(0xFF8A8FA3)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3))),
        ),
      ],
    );
  }
}

// ── Stat grid: salary, commission, sales, returns, net sale, net salary ────

class _StatGrid extends StatelessWidget {
  final EmployeeSalaryModel salary;
  const _StatGrid({required this.salary});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatSpec('Salary', 'Rs. ${salary.salary.toStringAsFixed(0)}',
          AppIcons.savingsOutlined, const Color(0xFF1565C0)),
      _StatSpec('Commission', '${salary.commissionPercent.toStringAsFixed(1)}%',
          AppIcons.percentOutlined, const Color(0xFF6C4DE0)),
      _StatSpec('Total Sales', 'Rs. ${salary.totalSales.toStringAsFixed(0)}',
          AppIcons.pointOfSaleOutlined, const Color(0xFF22A06B)),
      _StatSpec('Total Returns',
          'Rs. ${salary.totalSalesReturn.toStringAsFixed(0)}',
          AppIcons.assignmentReturnOutlined, const Color(0xFFE56A00)),
      _StatSpec('Net Sale', 'Rs. ${salary.netSale.toStringAsFixed(0)}',
          AppIcons.trendingUpOutlined, const Color(0xFF3E63DD)),
      _StatSpec('Net Salary', 'Rs. ${salary.netSalary.toStringAsFixed(0)}',
          AppIcons.monetizationOnOutlined, const Color(0xFF2E7D32)),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final perRow = constraints.maxWidth < 480
          ? 1
          : constraints.maxWidth < 800
              ? 2
              : 3;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: cards.map((c) {
          final width = (constraints.maxWidth - (perRow - 1) * 14) / perRow;
          return SizedBox(width: width, child: _StatCard(spec: c));
        }).toList(),
      );
    });
  }
}

class _StatSpec {
  final String label;
  final String value;
  final String icon;
  final Color color;
  const _StatSpec(this.label, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatSpec spec;
  const _StatCard({required this.spec});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E9F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: spec.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: AppIcon(spec.icon, color: spec.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(spec.label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8A8FA3),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(spec.value,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: spec.color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Salary history (month-wise archive) ─────────────────────────────────

class _SalaryHistoryCard extends ConsumerWidget {
  final String employeeSalaryId;
  const _SalaryHistoryCard({required this.employeeSalaryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(managerSalaryHistoryProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E9F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Salary History',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          const Text('Pichle mahinon ka record',
              style: TextStyle(fontSize: 12, color: Color(0xFF8A8FA3))),
          const SizedBox(height: 14),
          historyAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Error: $e',
                style: const TextStyle(color: Color(0xFF8A8FA3))),
            data: (history) {
              if (history.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Koi past record nahi hai',
                      style: TextStyle(color: Color(0xFF8A8FA3))),
                );
              }
              return Column(
                children: history.map((h) => _HistoryRow(entry: h)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final EmployeeSalaryHistoryModel entry;
  const _HistoryRow({required this.entry});

  static const _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final label = '${_months[entry.periodMonth.month]} ${entry.periodMonth.year}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(
            child: Text('Sale: ${entry.totalSales.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3))),
          ),
          Expanded(
            child: Text('${entry.commissionPercent.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3))),
          ),
          Expanded(
            child: Text('Rs. ${entry.netSalary.toStringAsFixed(0)}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32))),
          ),
        ],
      ),
    );
  }
}
