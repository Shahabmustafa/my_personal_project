import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/type_model.dart';
import '../providers/type_provider.dart';
import '../providers/type_state.dart';
import '../widgets/type_form_dialog.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';
class TypesScreen extends ConsumerStatefulWidget {
  final bool readOnly;
  const TypesScreen({super.key, this.readOnly = false});

  @override
  ConsumerState<TypesScreen> createState() => _TypesScreenState();
}

class _TypesScreenState extends ConsumerState<TypesScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(typeProvider.notifier).loadAll();
    });
  }

  void _showForm({TypeModel? item}) {
    showDialog(
      context: context,
      builder: (_) => TypeFormDialog(
        item: item,
        onSave: (m) => item == null
            ? ref.read(typeProvider.notifier).create(m)
            : ref.read(typeProvider.notifier).update(m),
      ),
    );
  }

  void _confirmDelete(TypeModel item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Type'),
        content: Text('Delete "${item.name}"?'),
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
              ref.read(typeProvider.notifier).delete(item.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(typeProvider);

    ref.listen<TypeState>(typeProvider, (_, next) {
      if (next.status == TypeStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.errorMessage!),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    });

    final filtered = state.items
        .where((c) => c.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Types',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('${state.items.length} total types',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF8A8FA3))),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showForm(),
                  icon: const AppIcon(AppIcons.add, size: 18),
                  label: const Text('Add Type'),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search types...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
                prefixIcon: const TextFieldIcon(AppIcons.search, size: 16, color: Color(0xFF8A8FA3)),
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
                    borderSide: const BorderSide(
                        color: Color(0xFF3E63DD), width: 1.5)),
              ),
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.status == TypeStatus.error
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AppIcon(AppIcons.errorOutline,
                                size: 48, color: Colors.redAccent),
                            const SizedBox(height: 12),
                            Text(state.errorMessage ?? 'Error',
                                style: const TextStyle(
                                    color: Color(0xFF8A8FA3))),
                            const SizedBox(height: 16),
                            ElevatedButton(
                                onPressed: () => ref
                                    .read(typeProvider.notifier)
                                    .loadAll(),
                                child: const Text('Retry')),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppIcon(AppIcons.styleOutlined,
                                    size: 48, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text(
                                  _search.isEmpty
                                      ? 'No types found'
                                      : 'No results for "$_search"',
                                  style: const TextStyle(
                                      color: Color(0xFF8A8FA3)),
                                ),
                              ],
                            ),
                          )
                        : _TableView(
                            items: filtered,
                            fieldLabel: 'Type Name',
                            readOnly: widget.readOnly,
                            onEdit: _showForm,
                            onDelete: _confirmDelete,
                          ),
          ),
        ],
      ),
    );
  }
}

class _TableView extends StatelessWidget {
  final List<TypeModel> items;
  final String fieldLabel;
  final bool readOnly;
  final Function({TypeModel? item}) onEdit;
  final Function(TypeModel) onDelete;

  const _TableView({
    required this.items,
    required this.fieldLabel,
    this.readOnly = false,
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
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F8FC),
                  border: Border(
                      bottom: BorderSide(color: Color(0xFFE7E9F0))),
                ),
                child: Row(children: [
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Text(fieldLabel,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8A8FA3),
                              letterSpacing: 0.3)),
                    ),
                  ),
                  if (!readOnly)
                    const SizedBox(
                      width: 100,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Text('Actions',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8A8FA3),
                                letterSpacing: 0.3)),
                      ),
                    ),
                ]),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFE7E9F0)),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(children: [
                        Expanded(
                          flex: 4,
                          child: Text(item.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                  color: Color(0xFF1A1D2E))),
                        ),
                        if (!readOnly)
                          SizedBox(
                            width: 100,
                            child: Row(children: [
                              _IconBtn(
                                icon: AppIcons.editOutlined,
                                color: const Color(0xFF3E63DD),
                                tooltip: 'Edit',
                                onTap: () => onEdit(item: item),
                              ),
                              const SizedBox(width: 8),
                              _IconBtn(
                                icon: AppIcons.deleteOutline,
                                color: Colors.redAccent,
                                tooltip: 'Delete',
                                onTap: () => onDelete(item),
                              ),
                            ]),
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
