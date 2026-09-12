import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
// ─────────────────────────────────────────────────────────────────────────────
// AppSearchDropdown — single-select with built-in search (dropdown_search pkg)
// Usage:
//   AppSearchDropdown<Brand>(
//     label: 'Brand',
//     items: brands,
//     selectedItem: selectedBrand,
//     itemLabel: (b) => b.name,
//     onChanged: (b) => setState(() => selectedBrand = b),
//   )
// ─────────────────────────────────────────────────────────────────────────────
class AppSearchDropdown<T> extends StatelessWidget {
  final String label;
  final List<T> items;
  final T? selectedItem;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;
  final String? errorText;
  final Widget? prefixIcon;
  final bool showSearchBox;
  final bool enabled;
  final bool isRequired;

  const AppSearchDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.selectedItem,
    required this.itemLabel,
    required this.onChanged,
    this.errorText,
    this.prefixIcon,
    this.showSearchBox = true,
    this.enabled = true,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = errorText != null;

    return DropdownSearch<T>(
      items: (filter, _) => items
          .where((item) =>
          itemLabel(item).toLowerCase().contains(filter.toLowerCase()))
          .toList(),
      selectedItem: selectedItem,
      enabled: enabled,
      compareFn: (a, b) => itemLabel(a) == itemLabel(b),
      itemAsString: itemLabel,
      onSelected: enabled ? onChanged : null, // ← fixed: onSelected not onChanged
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          prefixIcon: prefixIcon,
          errorText: errorText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: hasError
                    ? theme.colorScheme.error
                    : Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            BorderSide(color: theme.colorScheme.primary, width: 1.5),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade100,
        ),
      ),
      popupProps: PopupProps.menu(
        showSearchBox: showSearchBox,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: 'Search $label...',
            prefixIcon: const AppIcon(AppIcons.search, size: 18),
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
        ),
        menuProps: MenuProps(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 4,
        ),
        constraints: const BoxConstraints(maxHeight: 280),
        itemBuilder: (ctx, item, isSelected, _) => ListTile(
          dense: true,
          title: Text(
            itemLabel(item),
            style: TextStyle(
                fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal),
          ),
          trailing: isSelected
              ? AppIcon(AppIcons.check,
              color: theme.colorScheme.primary, size: 18)
              : null,
          tileColor: isSelected
              ? theme.colorScheme.primary.withOpacity(0.06)
              : null,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppMultiSelectDropdown — chip-based multi-select with searchable dialog
// ─────────────────────────────────────────────────────────────────────────────
class AppMultiSelectDropdown<T> extends StatelessWidget {
  final String label;
  final List<T> allItems;
  final List<T> selectedItems;
  final String Function(T) itemLabel;
  final void Function(List<T>) onChanged;
  final String? errorText;
  final Widget? prefixIcon;
  final bool isRequired;

  const AppMultiSelectDropdown({
    super.key,
    required this.label,
    required this.allItems,
    required this.selectedItems,
    required this.itemLabel,
    required this.onChanged,
    this.errorText,
    this.prefixIcon,
    this.isRequired = false,
  });

  Future<void> _openDialog(BuildContext context) async {
    final result = await showDialog<List<T>>(
      context: context,
      builder: (_) => _MultiSelectDialog<T>(
        label: label,
        allItems: allItems,
        selectedItems: selectedItems,
        itemLabel: itemLabel,
      ),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = errorText != null;

    return GestureDetector(
      onTap: () => _openDialog(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          prefixIcon: prefixIcon,
          errorText: errorText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: hasError
                    ? theme.colorScheme.error
                    : Colors.grey.shade300),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: const AppIcon(AppIcons.arrowDropDown, size: 18),
        ),
        child: selectedItems.isEmpty
            ? Text(
          'Select $label',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.hintColor),
        )
            : Wrap(
          spacing: 6,
          runSpacing: 4,
          children: selectedItems
              .map((item) => Chip(
            label: Text(itemLabel(item),
                style: const TextStyle(fontSize: 12)),
            deleteIcon: const AppIcon(AppIcons.close, size: 14),
            materialTapTargetSize:
            MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(
                horizontal: 4, vertical: 0),
            visualDensity: VisualDensity.compact,
            onDeleted: () {
              final updated = selectedItems
                  .where((e) => e != item)
                  .toList();
              onChanged(updated);
            },
          ))
              .toList(),
        ),
      ),
    );
  }
}

class _MultiSelectDialog<T> extends StatefulWidget {
  final String label;
  final List<T> allItems;
  final List<T> selectedItems;
  final String Function(T) itemLabel;

  const _MultiSelectDialog({
    required this.label,
    required this.allItems,
    required this.selectedItems,
    required this.itemLabel,
  });

  @override
  State<_MultiSelectDialog<T>> createState() => _MultiSelectDialogState<T>();
}

class _MultiSelectDialogState<T> extends State<_MultiSelectDialog<T>> {
  late List<T> _selected;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = widget.allItems
        .where((item) => widget
        .itemLabel(item)
        .toLowerCase()
        .contains(_search.toLowerCase()))
        .toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Select ${widget.label}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
            ),
            if (_selected.isNotEmpty)
              TextButton(
                onPressed: () => setState(() => _selected.clear()),
                child: const Text('Clear',
                    style: TextStyle(color: Colors.white70)),
              ),
          ],
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search ${widget.label}...',
                  prefixIcon: const AppIcon(AppIcons.search, size: 18),
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: filtered.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No results',
                    style: TextStyle(color: Colors.grey)),
              )
                  : ListView(
                shrinkWrap: true,
                children: filtered.map((item) {
                  final checked = _selected.contains(item);
                  return CheckboxListTile(
                    value: checked,
                    title: Text(widget.itemLabel(item),
                        style: const TextStyle(fontSize: 14)),
                    dense: true,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) => setState(() {
                      if (val == true) {
                        _selected.add(item);
                      } else {
                        _selected.remove(item);
                      }
                    }),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: Text('Done (${_selected.length})'),
        ),
      ],
    );
  }
}