import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:safishoe_app/core/widget/app_dropdown.dart';

// ── Filter dropdown options (category / type / brand / size) ──────────────
class StockFilterOption {
  final String id;
  final String label;
  const StockFilterOption(this.id, this.label);
}

class StockFilterOptions {
  final List<StockFilterOption> categories;
  final List<StockFilterOption> types;
  final List<StockFilterOption> brands;
  final List<StockFilterOption> sizes;
  const StockFilterOptions({
    this.categories = const [],
    this.types = const [],
    this.brands = const [],
    this.sizes = const [],
  });
}

final stockFilterOptionsProvider =
    FutureProvider.autoDispose<StockFilterOptions>((ref) async {
      final client = Supabase.instance.client;
      Future<List<StockFilterOption>> load(String table, String col) async {
        final res = await client.from(table).select('id, $col').order(col);
        return (res as List)
            .map((e) => StockFilterOption(e['id'] as String, '${e[col]}'))
            .toList();
      }

      final r = await Future.wait([
        load('categories', 'name'),
        load('types', 'name'),
        load('brands', 'name'),
        load('sizes', 'number'),
      ]);
      return StockFilterOptions(
        categories: r[0],
        types: r[1],
        brands: r[2],
        sizes: r[3],
      );
    });

// ── Filter Dropdown ───────────────────────────────────────────────────────────

class StockFilterDropdown extends StatelessWidget {
  final String label;
  final List<StockFilterOption> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  const StockFilterDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Empty id is the "All" entry; real ids are never empty.
    final all = StockFilterOption('', 'All $label');
    final items = [all, ...options];
    final selected = items.firstWhere(
      (o) => o.id == (value ?? ''),
      orElse: () => all,
    );
    return SizedBox(
      width: 170,
      child: AppSearchDropdown<StockFilterOption>(
        label: label,
        items: items,
        selectedItem: selected,
        itemLabel: (o) => o.label,
        onChanged: (o) => onChanged(o == null || o.id.isEmpty ? null : o.id),
      ),
    );
  }
}
