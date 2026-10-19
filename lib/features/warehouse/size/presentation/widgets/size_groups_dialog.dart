import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safishoe_app/features/warehouse/stock_inventory/data/models/warehouse_stock_model.dart'
    show StockLookupItem;
import 'package:safishoe_app/features/warehouse/stock_inventory/presentation/providers/stock_provider.dart'
    show stockSizesProvider;
import '../../data/model/size_group_model.dart';
import '../providers/size_group_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';

const _primary = Color(0xFF3E63DD);
const _muted = Color(0xFF8A8FA3);
const _border = Color(0xFFE7E9F0);

/// Lists size groups ("Gents = 6–11") used to fill the Add Stock size grid.
class SizeGroupsDialog extends ConsumerWidget {
  final bool readOnly;
  const SizeGroupsDialog({super.key, this.readOnly = false});

  Future<void> _openForm(BuildContext context, WidgetRef ref,
      [SizeGroupModel? group]) async {
    await showDialog(
      context: context,
      builder: (_) => _SizeGroupFormDialog(group: group),
    );
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, SizeGroupModel group) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Size Group'),
        content: Text('Delete "${group.name}"? Sizes themselves stay.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(sizeGroupDatasourceProvider).delete(group.id);
      ref.invalidate(sizeGroupsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst(RegExp(r'^Exception: '), '')),
            backgroundColor: Colors.redAccent));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(sizeGroupsProvider);
    final sizes = ref.watch(stockSizesProvider).value ?? const [];
    final labelOf = {for (final s in sizes) s.id: s.label};

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 6),
              child: Row(children: [
                const AppIcon(AppIcons.formatSizeOutlined,
                    color: _primary, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Size Groups',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
                ),
                if (!readOnly)
                  TextButton.icon(
                    icon: const AppIcon(AppIcons.add, size: 16),
                    label: const Text('New Group'),
                    onPressed: () => _openForm(context, ref),
                  ),
                IconButton(
                  icon: const AppIcon(AppIcons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Choosing a group adds all of its sizes to Add Stock Entry at once.',
                style: TextStyle(fontSize: 12, color: _muted),
              ),
            ),
            const Divider(height: 1, color: _border),
            Flexible(
              child: groupsAsync.when(
                loading: () => const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(e.toString(),
                        style: const TextStyle(color: Colors.redAccent))),
                data: (groups) => groups.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                            child: Text('No size groups yet',
                                style: TextStyle(color: _muted))),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: groups.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: _border),
                        itemBuilder: (_, i) {
                          final g = groups[i];
                          final labels = g.sizeIds
                              .map((id) => labelOf[id])
                              .whereType<String>()
                              .toList()
                            ..sort(compareSizeLabels);
                          return ListTile(
                            title: Text(g.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            subtitle: Text(
                              labels.isEmpty ? 'No sizes' : labels.join(', '),
                              style:
                                  const TextStyle(fontSize: 12, color: _muted),
                            ),
                            trailing: readOnly
                                ? null
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Edit',
                                        icon: const AppIcon(
                                            AppIcons.editOutlined,
                                            size: 18,
                                            color: _primary),
                                        onPressed: () =>
                                            _openForm(context, ref, g),
                                      ),
                                      IconButton(
                                        tooltip: 'Delete',
                                        icon: const AppIcon(
                                            AppIcons.deleteOutline,
                                            size: 18,
                                            color: Colors.redAccent),
                                        onPressed: () =>
                                            _delete(context, ref, g),
                                      ),
                                    ],
                                  ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SizeGroupFormDialog extends ConsumerStatefulWidget {
  final SizeGroupModel? group;
  const _SizeGroupFormDialog({this.group});

  @override
  ConsumerState<_SizeGroupFormDialog> createState() =>
      _SizeGroupFormDialogState();
}

class _SizeGroupFormDialogState extends ConsumerState<_SizeGroupFormDialog> {
  late final TextEditingController _nameCtrl;
  late final Set<String> _selected;
  String? _nameError;
  String? _sizesError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.group?.name ?? '');
    _selected = {...?widget.group?.sizeIds};
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(List<StockLookupItem> sizes) async {
    final name = _nameCtrl.text.trim();
    setState(() {
      _nameError = name.isEmpty ? 'Group name is required' : null;
      _sizesError = _selected.isEmpty ? 'Select at least one size' : null;
    });
    if (_nameError != null || _sizesError != null) return;

    setState(() => _saving = true);
    try {
      // Keep the group in size order so the stock grid reads left to right.
      final ordered = sizes
          .where((s) => _selected.contains(s.id))
          .map((s) => s.id)
          .toList();
      await ref.read(sizeGroupDatasourceProvider).save(SizeGroupModel(
            id: widget.group?.id ?? '',
            name: name,
            sizeIds: ordered,
          ));
      ref.invalidate(sizeGroupsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _saving = false;
        _nameError = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = [...?ref.watch(stockSizesProvider).value]
      ..sort((a, b) => compareSizeLabels(a.label, b.label));
    final isEdit = widget.group != null;
    final allSelected =
        sizes.isNotEmpty && sizes.every((s) => _selected.contains(s.id));

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isEdit ? 'Edit Size Group' : 'New Size Group',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameCtrl,
                autofocus: !isEdit,
                decoration: InputDecoration(
                  labelText: 'Group Name *',
                  hintText: 'e.g. Gents, Ladies, Kids',
                  errorText: _nameError,
                  prefixIcon: const TextFieldIcon(AppIcons.formatSizeOutlined,
                      size: 18, color: _muted),
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: Text('Sizes (${_selected.length} selected)',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _muted)),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    if (allSelected) {
                      _selected.clear();
                    } else {
                      _selected.addAll(sizes.map((s) => s.id));
                    }
                  }),
                  child: Text(allSelected ? 'Clear all' : 'Select all'),
                ),
              ]),
              if (_sizesError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(_sizesError!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12)),
                ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sizes
                    .map((s) => FilterChip(
                          label: Text(s.label),
                          selected: _selected.contains(s.id),
                          selectedColor: _primary.withValues(alpha: 0.15),
                          checkmarkColor: _primary,
                          onSelected: (v) => setState(() {
                            v ? _selected.add(s.id) : _selected.remove(s.id);
                            _sizesError = null;
                          }),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _saving ? null : () => _save(sizes),
          child: Text(isEdit ? 'Update' : 'Save'),
        ),
      ],
    );
  }
}
