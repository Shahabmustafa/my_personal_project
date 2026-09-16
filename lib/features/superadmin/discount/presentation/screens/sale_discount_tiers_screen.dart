import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/sale_discount_tier_model.dart';
import '../providers/sale_discount_tier_provider.dart';
import '../../../report/presentation/widgets/report_table_shell.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';

/// Head office yahan global "sale amount" discount tiers set karta hai —
/// jab kisi branch ki sale invoice ka items total kisi tier ke minimum tak
/// pohanch jaye, us tier ka discount (flat Rs. ya %) us invoice par
/// automatically lag jata hai. Koi branch alag se set nahi karta — jaise hi
/// head office yahan tier add kare, sab branches ko turant milta hai.
class SaleDiscountTiersScreen extends ConsumerWidget {
  const SaleDiscountTiersScreen({super.key});

  static const _accent = Color(0xFF3E63DD);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saleDiscountTierNotifierProvider);
    final notifier = ref.read(saleDiscountTierNotifierProvider.notifier);
    final isMobile = MediaQuery.of(context).size.width < 768;

    final titleBlock = const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sale Discount Tiers',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text(
          'Jab kisi invoice ka amount yahan diye gaye minimum tak pohanche, discount automatically lag jata hai — sab branches ke liye ek sath.',
          style: TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
        ),
      ],
    );

    final addBtn = ElevatedButton.icon(
      onPressed: () => _showTierDialog(context, ref),
      icon: const AppIcon(AppIcons.add, size: 18, color: Colors.white),
      label: const Text('Add Tier'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: addBtn),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: titleBlock),
                    addBtn,
                  ],
                ),
          const SizedBox(height: 16),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Error: ${state.error}', style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: state.isLoading && state.tiers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.tiers.isEmpty
                    ? const Center(
                        child: Text('No discount tiers set',
                            style: TextStyle(color: Color(0xFF8A8FA3))))
                    : isMobile
                        ? _MobileTierList(
                            tiers: state.tiers,
                            onEdit: (t) => _showTierDialog(context, ref, tier: t),
                            onDelete: (t) => _confirmDelete(context, notifier, t),
                          )
                        : SingleChildScrollView(
                            child: ReportTableShell(
                              columns: const [
                                DataColumn(label: Text('Min Sale Amount'), numeric: true),
                                DataColumn(label: Text('Discount Type')),
                                DataColumn(label: Text('Discount Value')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: state.tiers
                                  .map((t) => DataRow(cells: [
                                        DataCell(Text('Rs. ${t.minSaleAmount.toStringAsFixed(0)}',
                                            style: const TextStyle(fontWeight: FontWeight.w600))),
                                        DataCell(Text(t.typeLabel)),
                                        DataCell(Text(t.discountType == DiscountTierType.flat
                                            ? 'Rs. ${t.discountValue.toStringAsFixed(0)}'
                                            : '${t.discountValue.toStringAsFixed(1)}%')),
                                        DataCell(Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const AppIcon(AppIcons.editOutlined, size: 18),
                                              tooltip: 'Edit',
                                              onPressed: () => _showTierDialog(context, ref, tier: t),
                                            ),
                                            IconButton(
                                              icon: const AppIcon(AppIcons.deleteOutline,
                                                  size: 18, color: Colors.redAccent),
                                              tooltip: 'Delete',
                                              onPressed: () => _confirmDelete(context, notifier, t),
                                            ),
                                          ],
                                        )),
                                      ]))
                                  .toList(),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, SaleDiscountTierNotifier notifier, SaleDiscountTierModel t) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Tier?'),
        content: Text('Rs. ${t.minSaleAmount.toStringAsFixed(0)}+ tier delete kar dein?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              notifier.deleteTier(t.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showTierDialog(BuildContext context, WidgetRef ref, {SaleDiscountTierModel? tier}) {
    showDialog(
      context: context,
      builder: (_) => _TierFormDialog(tier: tier),
    );
  }
}

// ── Mobile List ───────────────────────────────────────────────────────────────

class _MobileTierList extends StatelessWidget {
  final List<SaleDiscountTierModel> tiers;
  final Function(SaleDiscountTierModel) onEdit;
  final Function(SaleDiscountTierModel) onDelete;

  const _MobileTierList({
    required this.tiers,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: tiers.length,
      itemBuilder: (_, i) => _TierCard(
        tier: tiers[i],
        onEdit: () => onEdit(tiers[i]),
        onDelete: () => onDelete(tiers[i]),
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  final SaleDiscountTierModel tier;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const _accent = Color(0xFF3E63DD);

  const _TierCard({required this.tier, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final valueText = tier.discountType == DiscountTierType.flat
        ? 'Rs. ${tier.discountValue.toStringAsFixed(0)}'
        : '${tier.discountValue.toStringAsFixed(1)}%';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAEFFD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const AppIcon(AppIcons.percentOutlined,
                color: Color(0xFF3E63DD), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rs. ${tier.minSaleAmount.toStringAsFixed(0)}+',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text('${tier.typeLabel} · $valueText',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const AppIcon(AppIcons.editOutlined, size: 18, color: _accent),
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const AppIcon(AppIcons.deleteOutline, size: 18, color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TierFormDialog extends ConsumerStatefulWidget {
  final SaleDiscountTierModel? tier;
  const _TierFormDialog({this.tier});

  @override
  ConsumerState<_TierFormDialog> createState() => _TierFormDialogState();
}

class _TierFormDialogState extends ConsumerState<_TierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _minCtrl;
  late final TextEditingController _valueCtrl;
  late DiscountTierType _type;
  bool _saving = false;

  bool get _isEdit => widget.tier != null;

  @override
  void initState() {
    super.initState();
    _minCtrl = TextEditingController(text: widget.tier != null ? widget.tier!.minSaleAmount.toStringAsFixed(0) : '');
    _valueCtrl = TextEditingController(text: widget.tier != null ? widget.tier!.discountValue.toStringAsFixed(0) : '');
    _type = widget.tier?.discountType ?? DiscountTierType.percent;
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final model = SaleDiscountTierModel(
      id: widget.tier?.id ?? '',
      minSaleAmount: double.parse(_minCtrl.text.trim()),
      discountType: _type,
      discountValue: double.parse(_valueCtrl.text.trim()),
    );
    try {
      final notifier = ref.read(saleDiscountTierNotifierProvider.notifier);
      if (_isEdit) {
        await notifier.updateTier(model);
      } else {
        await notifier.addTier(model);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(_isEdit ? 'Edit Discount Tier' : 'Add Discount Tier'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _minCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
              ],
              decoration: const InputDecoration(
                labelText: 'Minimum Sale Amount (Rs.)',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final n = double.tryParse((v ?? '').trim());
                if (n == null || n < 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<DiscountTierType>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Flat (Rs.)'),
                    value: DiscountTierType.flat,
                    groupValue: _type,
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<DiscountTierType>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Percent (%)'),
                    value: DiscountTierType.percent,
                    groupValue: _type,
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _valueCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
              ],
              decoration: InputDecoration(
                labelText: _type == DiscountTierType.flat ? 'Discount Amount (Rs.)' : 'Discount (%)',
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                final n = double.tryParse((v ?? '').trim());
                if (n == null || n < 0) return 'Enter a valid value';
                if (_type == DiscountTierType.percent && n > 100) return 'Max 100%';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
