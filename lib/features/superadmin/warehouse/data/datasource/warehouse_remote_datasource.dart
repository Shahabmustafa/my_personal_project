import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/warehouse_model.dart';

class WarehouseRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<WarehouseModel>> getAllWarehouses() async {
    final data = await _client.from('warehouses').select().order('created_at', ascending: false);
    return (data as List).map((e) => WarehouseModel.fromJson(e)).toList();
  }

  Future<List<WarehouseModel>> getWarehousesForUser(List<String> warehouseIds) async {
    if (warehouseIds.isEmpty) return [];
    final data = await _client.from('warehouses').select().inFilter('id', warehouseIds).order('warehouse_name');
    return (data as List).map((e) => WarehouseModel.fromJson(e)).toList();
  }

  Future<WarehouseModel> getWarehouseById(String id) async {
    final data = await _client.from('warehouses').select().eq('id', id).single();
    return WarehouseModel.fromJson(data);
  }

  Future<WarehouseModel> createWarehouse(WarehouseModel warehouse) async {
    final data = await _client
        .from('warehouses')
        .insert({
          'warehouse_name': warehouse.warehouseName,
          'address': warehouse.address,
          'phone_number': warehouse.phoneNumber,
          'city': warehouse.city,
          'status': warehouse.status,
        })
        .select()
        .single();
    return WarehouseModel.fromJson(data);
  }

  Future<WarehouseModel> updateWarehouse(WarehouseModel warehouse) async {
    final data = await _client
        .from('warehouses')
        .update({
          'warehouse_name': warehouse.warehouseName,
          'address': warehouse.address,
          'phone_number': warehouse.phoneNumber,
          'city': warehouse.city,
          'status': warehouse.status,
        })
        .eq('id', warehouse.id)
        .select()
        .single();
    return WarehouseModel.fromJson(data);
  }

  Future<void> deleteWarehouse(String id) async {
    await _client.from('warehouses').delete().eq('id', id);
  }

  Future<void> assignUserToWarehouse({required String userId, required String warehouseId}) async {
    await _client.from('user_warehouses').upsert({'user_id': userId, 'warehouse_id': warehouseId});
  }

  Future<void> removeUserFromWarehouse({required String userId, required String warehouseId}) async {
    await _client.from('user_warehouses').delete().eq('user_id', userId).eq('warehouse_id', warehouseId);
  }
}
