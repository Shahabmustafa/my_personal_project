import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/branch_cash_counter_model.dart';

class BranchCashCounterRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  /// Read-only: fetch all records for a branch, newest first
  Future<List<BranchCashCounterModel>> getByBranch(String branchId) async {
    if (branchId.isEmpty) return [];
    final data = await _client
        .from('branch_cash_counter')
        .select()
        .eq('branch_id', branchId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => BranchCashCounterModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
