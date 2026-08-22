import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/warehouse_cash_counter_model.dart';

class WarehouseCashCounterRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetch all records for a warehouse, ordered by date descending
  Future<List<WarehouseCashCounterModel>> getByWarehouse(
      String warehouseId) async {
    if (warehouseId.isEmpty) return [];
    final data = await _client
        .from('warehouse_cash_counter')
        .select()
        .eq('warehouse_id', warehouseId)
        .order('counter_date', ascending: false);
    return (data as List)
        .map((e) => WarehouseCashCounterModel.fromJson(e))
        .toList();
  }

  /// Fetch single record by date for a warehouse (may return null)
  Future<WarehouseCashCounterModel?> getByDate(
      String warehouseId, DateTime date) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final data = await _client
        .from('warehouse_cash_counter')
        .select()
        .eq('warehouse_id', warehouseId)
        .eq('counter_date', dateStr)
        .maybeSingle();
    if (data == null) return null;
    return WarehouseCashCounterModel.fromJson(data);
  }

  /// Create new cash counter record
  Future<WarehouseCashCounterModel> create(
      WarehouseCashCounterModel record) async {
    // Check duplicate date per warehouse
    final existing = await _client
        .from('warehouse_cash_counter')
        .select('id')
        .eq('warehouse_id', record.warehouseId)
        .eq('counter_date', record.toJson()['counter_date'])
        .maybeSingle();

    if (existing != null) {
      throw Exception(
          'A record for this date already exists in this warehouse');
    }

    final data = await _client
        .from('warehouse_cash_counter')
        .insert(record.toJson())
        .select()
        .single();
    return WarehouseCashCounterModel.fromJson(data);
  }

  /// Update existing cash counter record
  Future<WarehouseCashCounterModel> update(
      WarehouseCashCounterModel record) async {
    // Check duplicate date excluding current record
    final existing = await _client
        .from('warehouse_cash_counter')
        .select('id')
        .eq('warehouse_id', record.warehouseId)
        .eq('counter_date', record.toJson()['counter_date'])
        .neq('id', record.id)
        .maybeSingle();

    if (existing != null) {
      throw Exception(
          'Another record for this date already exists in this warehouse');
    }

    final data = await _client
        .from('warehouse_cash_counter')
        .update(record.toJson())
        .eq('id', record.id)
        .select()
        .single();
    return WarehouseCashCounterModel.fromJson(data);
  }

  /// Delete a cash counter record
  Future<void> delete(String id) async {
    await _client.from('warehouse_cash_counter').delete().eq('id', id);
  }
}
