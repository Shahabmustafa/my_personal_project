import 'package:flutter/material.dart';

import 'package:safishoe_app/core/widget/app_dropdown.dart';

/// Searchable "All / one entry" filter above assignment lists, built on the
/// app's [AppSearchDropdown]. [options] maps an id to its display label; a
/// null value means "All".
class BranchFilterDropdown extends StatelessWidget {
  final String label;
  final String allLabel;
  final Map<String, String> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  const BranchFilterDropdown({
    super.key,
    required this.label,
    required this.allLabel,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // '' is the "All" entry; real ids are never empty.
    final entries = <MapEntry<String, String>>[
      MapEntry('', allLabel),
      ...options.entries,
    ];
    final selected = entries.firstWhere(
      (e) => e.key == (value ?? ''),
      orElse: () => entries.first,
    );
    return SizedBox(
      width: 280,
      child: AppSearchDropdown<MapEntry<String, String>>(
        label: label,
        items: entries,
        selectedItem: selected,
        itemLabel: (e) => e.value,
        onChanged: (e) => onChanged(e == null || e.key.isEmpty ? null : e.key),
      ),
    );
  }
}
