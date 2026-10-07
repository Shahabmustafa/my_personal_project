import 'package:supabase_flutter/supabase_flutter.dart';

/// Stock tables that point at catalog rows, and which FK columns each has.
const _stockTables = {
  'warehouse_stock_inventory': {
    'product_id', 'size_id', 'color_id', 'brand_id', 'category_id', 'type_id',
    'company_id',
  },
  'stock_inventory': {
    'product_id', 'size_id', 'color_id', 'brand_id', 'category_id', 'type_id',
    'company_id',
  },
  'branch_stock_inventory': {
    'product_id', 'size_id', 'color_id', 'brand_id', 'category_id', 'type_id',
  },
};

/// Deletes a catalog row only when no stock uses it.
///
/// The DB alone isn't enough: products CASCADE (deleting one wipes its
/// warehouse/head-office stock) and companies SET NULL on the stock tables.
/// So check every stock table first and refuse with a clear message.
/// [alsoCheck] adds non-stock tables to block on (e.g. purchase invoices for
/// a company, which would otherwise silently lose their company).
/// [beforeDelete] runs only once the row is known to be deletable.
Future<void> deleteCatalogRow(
  SupabaseClient client, {
  required String table,
  required String column,
  required String id,
  required String label,
  Map<String, String> alsoCheck = const {},
  Future<void> Function()? beforeDelete,
}) async {
  for (final entry in _stockTables.entries) {
    if (!entry.value.contains(column)) continue;
    if (await _used(client, entry.key, column, id)) {
      throw Exception(
          'This $label is used in stock inventory and cannot be deleted');
    }
  }
  for (final entry in alsoCheck.entries) {
    if (await _used(client, entry.key, column, id)) {
      throw Exception(
          'This $label is used in ${entry.value} and cannot be deleted');
    }
  }
  await beforeDelete?.call();
  try {
    await client.from(table).delete().eq('id', id);
  } on PostgrestException catch (e) {
    // Still referenced by invoices / returns / claims (FK RESTRICT).
    if (e.code == '23503') {
      throw Exception(
          'This $label is used in invoices or returns and cannot be deleted');
    }
    rethrow;
  }
}

Future<bool> _used(
    SupabaseClient client, String table, String column, String id) async {
  final rows = await client.from(table).select('id').eq(column, id).limit(1);
  return (rows as List).isNotEmpty;
}
