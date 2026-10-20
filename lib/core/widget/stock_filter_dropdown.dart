import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  const StockFilterOptions(
      {this.categories = const [],
      this.types = const [],
      this.brands = const [],
      this.sizes = const []});
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
      categories: r[0], types: r[1], brands: r[2], sizes: r[3]);
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
    final selected = options.any((o) => o.id == value) ? value : null;
    return SizedBox(
      width: 170,
      child: DropdownButtonFormField<String?>(
        key: ValueKey('$label-$selected'),
        initialValue: selected,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
        ),
        style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A2E)),
        items: [
          DropdownMenuItem<String?>(value: null, child: Text('All $label')),
          for (final o in options)
            DropdownMenuItem<String?>(
                value: o.id, child: Text(o.label, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

