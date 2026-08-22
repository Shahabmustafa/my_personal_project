import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/expense_entry_model.dart';
import '../model/expense_head_model.dart';

class ExpenseDatasource {
  final SupabaseClient _client;
  ExpenseDatasource(this._client);

  Future<List<ExpenseHeadModel>> getHeads() async {
    final data = await _client
        .from('expense_heads')
        .select()
        .eq('is_active', true)
        .order('name', ascending: true);
    return (data as List)
        .map((e) => ExpenseHeadModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ExpenseHeadModel> addHead({
    required String name,
    String? description,
  }) async {
    final data = await _client
        .from('expense_heads')
        .insert({'name': name, 'description': description})
        .select()
        .single();
    return ExpenseHeadModel.fromJson(data);
  }

  Future<List<ExpenseEntryModel>> getEntriesByBranch(String branchId) async {
    if (branchId.isEmpty) return [];
    final data = await _client
        .from('expense_entries')
        .select('*, expense_heads(name)')
        .eq('branch_id', branchId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => ExpenseEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Aaj ke din ka branch_cash_counter row (nightly cron se banta hai) —
  /// expense entry usi se link hoti hai.
  Future<String?> getTodaysCashCounterId(String branchId) async {
    if (branchId.isEmpty) return null;
    final data = await _client
        .from('branch_cash_counter')
        .select('id')
        .eq('branch_id', branchId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return data?['id']?.toString();
  }

  Future<void> addEntry({
    required String branchId,
    required String branchCashCounterId,
    required String expenseHeadId,
    required double amount,
    String? note,
  }) async {
    await _client.from('expense_entries').insert({
      'branch_id': branchId,
      'branch_cash_counter_id': branchCashCounterId,
      'expense_head_id': expenseHeadId,
      'amount': amount,
      'note': note,
    });
  }

  Future<void> deleteEntry(String id) async {
    await _client.from('expense_entries').delete().eq('id', id);
  }
}
