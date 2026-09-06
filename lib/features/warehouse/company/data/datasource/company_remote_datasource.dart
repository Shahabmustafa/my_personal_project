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

  /// Fetch all companies for a specific head office
  Future<List<CompanyModel>> getCompaniesByHeadOffice(
      String headOfficeId) async {
    if (headOfficeId.isEmpty) return [];
    final data = await _client
        .from('companies')
        .select()
        .eq('head_office_id', headOfficeId)
        .order('name');
    return (data as List).map((e) => CompanyModel.fromJson(e)).toList();
  }

  /// Create new company — duplicate name check per head office
  Future<CompanyModel> createCompany(CompanyModel company) async {
    if (company.headOfficeId.isEmpty) {
      throw Exception('No head office found — add a head office first');
    }
    final existing = await _client
        .from('companies')
        .select('id')
        .eq('head_office_id', company.headOfficeId)
        .ilike('name', company.name.trim())
        .maybeSingle();

    if (existing != null) {
      throw Exception('A company with this name already exists');
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
    if (company.headOfficeId.isEmpty) {
      throw Exception('This company has no head office assigned');
    }
    final existing = await _client
        .from('companies')
        .select('id')
        .eq('head_office_id', company.headOfficeId)
        .ilike('name', company.name.trim())
        .neq('id', company.id)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Another company with this name already exists');
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
