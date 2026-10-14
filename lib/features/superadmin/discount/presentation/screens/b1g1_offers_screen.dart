import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widget/app_dropdown.dart';
import '../../data/datasource/b1g1_offer_datasource.dart';
import '../../data/model/b1g1_offer_model.dart';
import '../providers/b1g1_offer_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';

/// Admin yahan "Buy 1 Get 1 Free" offers banata hai — kin Articles / Brands /
/// Categories par lagega. Sab branches ki Sale Invoice mein har 2 pairs mein
/// se sasta wala khud free ho jata hai. Offer wali invoice par koi aur
/// discount nahi lagta aur offer wale items return/exchange nahi hote.
class B1g1OffersScreen extends ConsumerWidget {
  const B1g1OffersScreen({super.key});

  static const _accent = Color(0xFF3E63DD);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(b1g1OffersProvider);
    final products = ref.watch(b1g1ProductsProvider).value ?? const [];
    final brands = ref.watch(b1g1BrandsProvider).value ?? const [];
    final categories = ref.watch(b1g1CategoriesProvider).value ?? const [];

    String names(List<String> ids, List<B1g1Lookup> all) {
      final byId = {for (final l in all) l.id: l.name};
      return ids.map((id) => byId[id] ?? '…').join(', ');
    }

    final titleBlock = const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Buy 1 Get 1 Free',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text(
          'Chune hue Articles / Brands / Categories par har 2 pairs mein se sasta wala free — sab branches ke liye. Is offer wale items return nahi hote.',
          style: TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
        ),
      ],
    );

    final addBtn = ElevatedButton.icon(
      onPressed: () => _openForm(context),
      icon: const AppIcon(AppIcons.add, size: 18, color: Colors.white),
      label: const Text('Add Offer'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    final isMobile = MediaQuery.of(context).size.width < 768;

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
              : Row(children: [Expanded(child: titleBlock), addBtn]),
          const SizedBox(height: 16),
          Expanded(
            child: offersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: Colors.red)),
              ),
              data: (offers) => offers.isEmpty
                  ? const Center(
                      child: Text('Koi offer nahi bana',
                          style: TextStyle(color: Color(0xFF8A8FA3))))
                  : ListView.builder(
                      itemCount: offers.length,
                      itemBuilder: (_, i) {
                        final o = offers[i];
                        return _OfferCard(
                          offer: o,
                          targets: [
                            if (o.productIds.isNotEmpty)
                              'Articles: ${names(o.productIds, products)}',
                            if (o.brandIds.isNotEmpty)
                              'Brands: ${names(o.brandIds, brands)}',
                            if (o.categoryIds.isNotEmpty)
                              'Categories: ${names(o.categoryIds, categories)}',
                          ],
                          onEdit: () => _openForm(context, offer: o),
                          onDelete: () => _confirmDelete(context, ref, o),
                          onToggle: (v) async {
                            await ref
                                .read(b1g1OfferDatasourceProvider)
                                .setActive(o.id, v);
                            ref.invalidate(b1g1OffersProvider);
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, {B1g1OfferModel? offer}) {
    showDialog(
      context: context,
      builder: (_) => _OfferFormDialog(offer: offer),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, B1g1OfferModel o) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Offer?'),
        content: Text('"${o.name}" offer delete kar dein?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref.read(b1g1OfferDatasourceProvider).delete(o.id);
              ref.invalidate(b1g1OffersProvider);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class _OfferCard extends StatelessWidget {
  final B1g1OfferModel offer;
  final List<String> targets;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _OfferCard({
    required this.offer,
    required this.targets,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final running = offer.isRunningOn(DateTime.now());
    final dates = [
      if (offer.startDate != null) 'From ${_fmtDate(offer.startDate!)}',
      if (offer.endDate != null) 'To ${_fmtDate(offer.endDate!)}',
    ].join('  ·  ');

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
              color: const Color(0xFFE6F4EC),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Text('1+1',
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: Color(0xFF2E7D32))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(offer.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: running
                          ? const Color(0xFFE6F4EC)
                          : const Color(0xFFF1F2F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(running ? 'Running' : 'Not running',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: running
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFF8A8FA3))),
                  ),
                ]),
                const SizedBox(height: 6),
                for (final t in targets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(t,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF5A5F73))),
                  ),
                if (dates.isNotEmpty)
                  Text(dates,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF8A8FA3))),
              ],
            ),
          ),
          Switch(value: offer.isActive, onChanged: onToggle),
          IconButton(
            icon: const AppIcon(AppIcons.editOutlined, size: 18),
            tooltip: 'Edit',
            onPressed: onEdit,
          ),
          IconButton(
            icon: const AppIcon(AppIcons.deleteOutline,
                size: 18, color: Colors.redAccent),
            tooltip: 'Delete',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _OfferFormDialog extends ConsumerStatefulWidget {
  final B1g1OfferModel? offer;
  const _OfferFormDialog({this.offer});

  @override
  ConsumerState<_OfferFormDialog> createState() => _OfferFormDialogState();
}

class _OfferFormDialogState extends ConsumerState<_OfferFormDialog> {
  late final TextEditingController _nameCtrl;
  late Set<String> _productIds;
  late Set<String> _brandIds;
  late Set<String> _categoryIds;
  DateTime? _start;
  DateTime? _end;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final o = widget.offer;
    _nameCtrl = TextEditingController(text: o?.name ?? '');
    _productIds = {...?o?.productIds};
    _brandIds = {...?o?.brandIds};
    _categoryIds = {...?o?.categoryIds};
    _start = o?.startDate;
    _end = o?.endDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _start : _end) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() => isStart ? _start = picked : _end = picked);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    String? error;
    if (name.isEmpty) {
      error = 'Offer ka naam likhein';
    } else if (_productIds.isEmpty &&
        _brandIds.isEmpty &&
        _categoryIds.isEmpty) {
      error = 'Kam az kam ek Article, Brand ya Category chunein';
    } else if (_start != null && _end != null && _end!.isBefore(_start!)) {
      error = 'End date start date se pehle nahi ho sakti';
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(b1g1OfferDatasourceProvider).save(B1g1OfferModel(
            id: widget.offer?.id ?? '',
            name: name,
            productIds: _productIds.toList(),
            brandIds: _brandIds.toList(),
            categoryIds: _categoryIds.toList(),
            startDate: _start,
            endDate: _end,
            isActive: widget.offer?.isActive ?? true,
          ));
      ref.invalidate(b1g1OffersProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString();
        });
      }
    }
  }

  Widget _multi(String label, List<B1g1Lookup> all, Set<String> ids,
      ValueChanged<Set<String>> onChanged) {
    return AppMultiSelectDropdown<B1g1Lookup>(
      label: label,
      allItems: all,
      selectedItems: all.where((l) => ids.contains(l.id)).toList(),
      itemLabel: (l) => l.name,
      onChanged: (list) => setState(() => onChanged(list.map((l) => l.id).toSet())),
    );
  }

  Widget _dateBtn(String label, DateTime? value, bool isStart) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () => _pickDate(isStart),
        onLongPress: () => setState(() => isStart ? _start = null : _end = null),
        child: Text(value == null ? label : '$label: ${_fmtDate(value)}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(b1g1ProductsProvider).value ?? const [];
    final brands = ref.watch(b1g1BrandsProvider).value ?? const [];
    final categories = ref.watch(b1g1CategoriesProvider).value ?? const [];

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.offer == null ? 'Add B1G1 Offer' : 'Edit B1G1 Offer'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Offer Name (e.g. Eid Sale)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              _multi('Articles', products, _productIds,
                  (v) => _productIds = v),
              const SizedBox(height: 12),
              _multi('Brands', brands, _brandIds, (v) => _brandIds = v),
              const SizedBox(height: 12),
              _multi('Categories', categories, _categoryIds,
                  (v) => _categoryIds = v),
              const SizedBox(height: 14),
              Row(children: [
                _dateBtn('Start', _start, true),
                const SizedBox(width: 10),
                _dateBtn('End', _end, false),
              ]),
              const SizedBox(height: 4),
              const Text(
                'Date khali chhorein to offer hamesha chalega (jab tak On ho). Date hatane ke liye button dabaye rakhein.',
                style: TextStyle(fontSize: 11, color: Color(0xFF8A8FA3)),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
