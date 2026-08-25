import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/branch_model.dart';
import '../providers/branch_provider.dart';
import '../providers/branch_state.dart';

/// Superadmin yahan se decide karta hai ke kis branch ko sale invoice par
/// extra (invoice-wise) discount lagane ki access hai. Jis branch ke liye
/// yeh off hai, us branch ki Sale Invoice screen par discount field
/// dikhta hi nahi.
class BranchDiscountAccessScreen extends ConsumerStatefulWidget {
  const BranchDiscountAccessScreen({super.key});

  @override
  ConsumerState<BranchDiscountAccessScreen> createState() =>
      _BranchDiscountAccessScreenState();
}

class _BranchDiscountAccessScreenState extends ConsumerState<BranchDiscountAccessScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(branchProvider.notifier).loadAllBranches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final branchState = ref.watch(branchProvider);

    final filtered = branchState.branches
        .where((b) => b.branchName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Invoice Discount Access',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                  'Jis branch ke liye ON hai, wahan sale invoice par cashier extra discount laga sakega.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search branches...',
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
              ),
            ),
          ),
          Expanded(
            child: branchState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : branchState.status == BranchStatus.error
                    ? Center(
                        child: Text(branchState.errorMessage ?? 'Error',
                            style: const TextStyle(color: Colors.red)))
                    : filtered.isEmpty
                        ? const Center(
                            child: Text('No branches found',
                                style: TextStyle(color: Color(0xFF8A8FA3))))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) => _BranchAccessRow(branch: filtered[i]),
                          ),
          ),
        ],
      ),
    );
  }
}

class _BranchAccessRow extends ConsumerWidget {
  final BranchModel branch;
  const _BranchAccessRow({required this.branch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEAEFFD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.apartment_outlined, color: Color(0xFF3E63DD), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(branch.branchName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                if (branch.city.isNotEmpty)
                  Text(branch.city, style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3))),
              ],
            ),
          ),
          Text(
            branch.canApplyInvoiceDiscount ? 'Allowed' : 'Not allowed',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: branch.canApplyInvoiceDiscount ? const Color(0xFF2E7D32) : const Color(0xFF8A8FA3),
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: branch.canApplyInvoiceDiscount,
            onChanged: (v) => ref
                .read(branchProvider.notifier)
                .updateBranch(branch.copyWith(canApplyInvoiceDiscount: v)),
          ),
        ],
      ),
    );
  }
}
