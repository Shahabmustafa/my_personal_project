import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/company_model.dart';

class CompanyRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetch all companies (superadmin/admin)
  Future<List<CompanyModel>> getAllCompanies() async {
    final data = await _client
        .from('companies')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => CompanyModel.fromJson(e)).toList();
  }

  /// Fetch all companies for a specific warehouse
  Future<List<CompanyModel>> getCompaniesByWarehouse(
      String warehouseId) async {
    if (warehouseId.isEmpty) return [];
    final data = await _client
        .from('companies')
        .select()
        .eq('warehouse_id', warehouseId)
        .order('name');
    return (data as List).map((e) => CompanyModel.fromJson(e)).toList();
  }

  /// Fetch companies for multiple warehouses
  Future<List<CompanyModel>> getCompaniesForWarehouses(
      List<String> warehouseIds) async {
    final validIds = warehouseIds.where((id) => id.isNotEmpty).toList();
    if (validIds.isEmpty) return [];
    final data = await _client
        .from('companies')
        .select()
        .inFilter('warehouse_id', validIds)
        .order('name');
    return (data as List).map((e) => CompanyModel.fromJson(e)).toList();
  }

  /// Create new company — duplicate name check per warehouse
  Future<CompanyModel> createCompany(CompanyModel company) async {
    if (company.warehouseId.isEmpty) {
      throw Exception('Select a working warehouse before adding a company');
    }
    final existing = await _client
        .from('companies')
        .select('id')
        .eq('warehouse_id', company.warehouseId)
        .ilike('name', company.name.trim())
        .maybeSingle();

    if (existing != null) {
      throw Exception(
          'A company with this name already exists in this warehouse');
    }

    final data = await _client
        .from('companies')
        .insert(company.toJson())
        .select()
        .single();
    return CompanyModel.fromJson(data);
  }

  /// Update company info — duplicate name check excluding current record
  Future<CompanyModel> updateCompany(CompanyModel company) async {
    if (company.warehouseId.isEmpty) {
      throw Exception('This company has no warehouse assigned');
    }
    final existing = await _client
        .from('companies')
        .select('id')
        .eq('warehouse_id', company.warehouseId)
        .ilike('name', company.name.trim())
        .neq('id', company.id)
        .maybeSingle();

    if (existing != null) {
      throw Exception(
          'Another company with this name already exists in this warehouse');
    }

    final data = await _client
        .from('companies')
        .update(company.toJson())
        .eq('id', company.id)
        .select()
        .single();
    return CompanyModel.fromJson(data);
  }

  /// Delete company
  Future<void> deleteCompany(String id) async {
    await _client.from('companies').delete().eq('id', id);
  }
}
