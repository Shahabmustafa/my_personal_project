import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/branch_model.dart';

class BranchRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<BranchModel>> getAllBranches() async {
    final data = await _client.from('branches').select().order('created_at', ascending: false);
    return (data as List).map((e) => BranchModel.fromJson(e)).toList();
  }

  Future<List<BranchModel>> getBranchesForUser(List<String> branchIds) async {
    if (branchIds.isEmpty) return [];
    final data = await _client
        .from('branches')
        .select()
        .inFilter('id', branchIds)
        .order('branch_name');
    return (data as List).map((e) => BranchModel.fromJson(e)).toList();
  }

  Future<BranchModel> getBranchById(String id) async {
    final data = await _client.from('branches').select().eq('id', id).single();
    return BranchModel.fromJson(data);
  }

  Future<BranchModel> createBranch(BranchModel branch) async {
    final data = await _client
        .from('branches')
        .insert({
          'branch_name': branch.branchName,
          'address': branch.address,
          'phone_number': branch.phoneNumber,
          'city': branch.city,
          'status': branch.status,
          'can_apply_invoice_discount': branch.canApplyInvoiceDiscount,
          'max_invoice_discount_pct': branch.maxInvoiceDiscountPct,
          'monthly_target': branch.monthlyTarget,
        })
        .select()
        .single();
    return BranchModel.fromJson(data);
  }

  Future<BranchModel> updateBranch(BranchModel branch) async {
    final data = await _client
        .from('branches')
        .update({
          'branch_name': branch.branchName,
          'address': branch.address,
          'phone_number': branch.phoneNumber,
          'city': branch.city,
          'status': branch.status,
          'can_apply_invoice_discount': branch.canApplyInvoiceDiscount,
          'max_invoice_discount_pct': branch.maxInvoiceDiscountPct,
          'monthly_target': branch.monthlyTarget,
        })
        .eq('id', branch.id)
        .select()
        .single();
    return BranchModel.fromJson(data);
  }

  Future<void> deleteBranch(String id) async {
    await _client.from('branches').delete().eq('id', id);
  }

  Future<void> assignUserToBranch({required String userId, required String branchId}) async {
    await _client.from('user_branches').upsert({'user_id': userId, 'branch_id': branchId});
  }

  Future<void> removeUserFromBranch({required String userId, required String branchId}) async {
    await _client.from('user_branches').delete().eq('user_id', userId).eq('branch_id', branchId);
  }
}
