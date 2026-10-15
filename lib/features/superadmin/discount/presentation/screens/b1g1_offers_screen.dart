import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widget/app_dropdown.dart';
import '../../data/datasource/b1g1_offer_datasource.dart';
import '../../data/model/b1g1_offer_model.dart';
import '../providers/b1g1_offer_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';

/// Admin yahan "Buy 1 Get 1 Free" offers banata hai — kin Articles (size /
/// color ke sath) par lagega. Sab branches ki Sale Invoice mein har 2 pairs mein
/// se sasta wala khud free ho jata hai. Offer wali invoice par koi aur
/// discount nahi lagta aur offer wale items return/exchange nahi hote.
class B1g1OffersScreen extends ConsumerWidget {
  const B1g1OffersScreen({super.key});

  static const _accent = Color(0xFF3E63DD);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(b1g1OffersProvider);
    final products = ref.watch(b1g1ProductsProvider).value ?? const [];
    final variants = ref.watch(b1g1VariantsProvider).value ?? const [];
    final variantByKey = {for (final v in variants) v.key: v};

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
          'Chune hue Articles par har 2 pairs mein se sasta wala free — sab branches ke liye. Is offer wale items return nahi hote.',
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
                            if (o.variantKeys.isNotEmpty)
                              'Articles: ${o.variantKeys.map((k) => variantByKey[k]?.label ?? '…').join(', ')}',
                            if (o.productIds.isNotEmpty)
                              'Articles (sab sizes/colors): ${names(o.productIds, products)}',
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
  late Set<String> _variantKeys;
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
    _variantKeys = {...?o?.variantKeys};
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
    } else if (_productIds.isEmpty && _variantKeys.isEmpty) {
      error = 'Kam az kam ek Article chunein';
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
            variantKeys: _variantKeys.toList(),
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
    final variants = ref.watch(b1g1VariantsProvider).value ?? const [];

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.offer == null ? 'Add B1G1 Offer' : 'Edit B1G1 Offer'),
      content: SizedBox(
        width: 520,
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
              _VariantField(
                all: variants,
                selected: _variantKeys,
                onChanged: (v) => setState(() => _variantKeys = v),
              ),
              // Purane offers jin mein poora article (har size/color) chuna tha.
              if (_productIds.isNotEmpty) ...[
                const SizedBox(height: 12),
                _multi('Articles (sab sizes/colors)', products, _productIds,
                    (v) => _productIds = v),
              ],
              const SizedBox(height: 4),
              const Text(
                'Do items mein se jis ki qeemat kam hai wo free hoga.',
                style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32)),
              ),
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

/// "Articles" field — Sale Invoice ke Article dropdown jaisa: har stock
/// variant apne color / size / brand / category / type aur qeemat ke sath.
class _VariantField extends StatelessWidget {
  final List<B1g1Variant> all;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const _VariantField({
    required this.all,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final byKey = {for (final v in all) v.key: v};
    return GestureDetector(
      onTap: () async {
        final res = await showDialog<Set<String>>(
          context: context,
          builder: (_) => _VariantPickerDialog(all: all, selected: selected),
        );
        if (res != null) onChanged(res);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Articles',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          suffixIcon: const AppIcon(AppIcons.arrowDropDown, size: 24),
        ),
        child: selected.isEmpty
            ? Text('Select Articles',
                style: TextStyle(color: Theme.of(context).hintColor))
            : Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final k in selected)
                    Chip(
                      label: Text(byKey[k]?.label ?? '…',
                          style: const TextStyle(fontSize: 12)),
                      deleteIcon: const AppIcon(AppIcons.close, size: 14),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      onDeleted: () => onChanged({...selected}..remove(k)),
                    ),
                ],
              ),
      ),
    );
  }
}

class _VariantPickerDialog extends StatefulWidget {
  final List<B1g1Variant> all;
  final Set<String> selected;
  const _VariantPickerDialog({required this.all, required this.selected});

  @override
  State<_VariantPickerDialog> createState() => _VariantPickerDialogState();
}

class _VariantPickerDialogState extends State<_VariantPickerDialog> {
  late final Set<String> _selected = {...widget.selected};
  String _search = '';

  /// Article, color, size, brand, category, type ya barcode — kisi se bhi.
  List<B1g1Variant> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return widget.all;
    return widget.all
        .where((v) => '${v.label} ${v.barcode}'.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final filtered = _filtered;
    final allShownSelected =
        filtered.isNotEmpty && filtered.every((v) => _selected.contains(v.key));

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(children: [
        const Expanded(child: Text('Select Articles')),
        if (_selected.isNotEmpty)
          TextButton(
            onPressed: () => setState(_selected.clear),
            child: const Text('Clear'),
          ),
      ]),
      contentPadding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search article, color, size, brand, category...',
                  prefixIcon: const TextFieldIcon(AppIcons.search, size: 18),
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            CheckboxListTile(
              dense: true,
              value: allShownSelected,
              activeColor: primary,
              title: Text('Sab select karein (${filtered.length})',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              onChanged: filtered.isEmpty
                  ? null
                  : (v) => setState(() {
                        for (final f in filtered) {
                          v == true
                              ? _selected.add(f.key)
                              : _selected.remove(f.key);
                        }
                      }),
            ),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No results',
                          style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final v = filtered[i];
                        return CheckboxListTile(
                          dense: true,
                          value: _selected.contains(v.key),
                          activeColor: primary,
                          title: Text(v.productName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          subtitle: Text(
                            [
                              if (v.details.isNotEmpty) v.details,
                              if (v.barcode.isNotEmpty) 'Barcode: ${v.barcode}',
                            ].join('  •  '),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600),
                          ),
                          secondary: Text(
                            'Rs ${v.salePrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          onChanged: (c) => setState(() => c == true
                              ? _selected.add(v.key)
                              : _selected.remove(v.key)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: Text('Done (${_selected.length})'),
        ),
      ],
    );
  }
}
