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

  /// Saari branches ka expense (superadmin "All Branches" view).
  Future<List<ExpenseEntryModel>> getAllBranchEntries() async {
    final data = await _client
        .from('expense_entries')
        .select('*, expense_heads(name), branches(branch_name)')
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

  Future<void> updateEntry({
    required String id,
    required String expenseHeadId,
    required double amount,
    String? note,
  }) async {
    await _client.from('expense_entries').update({
      'expense_head_id': expenseHeadId,
      'amount': amount,
      'note': note,
    }).eq('id', id);
  }

  Future<void> deleteEntry(String id) async {
    await _client.from('expense_entries').delete().eq('id', id);
  }

  // ── Head office (superadmin) ki apni expense — `head_office_expenses` ────
  // Purchase wale kharche bhi isi table mein hain. Is table pe koi trigger
  // nahi, is liye cash counter yahin se update hota hai (purchase jaisa).

  Future<List<ExpenseEntryModel>> getEntriesByHeadOffice(
      String headOfficeId) async {
    if (headOfficeId.isEmpty) return [];
    final data = await _client
        .from('head_office_expenses')
        .select('*, expense_heads(name)')
        .eq('head_office_id', headOfficeId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => ExpenseEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addHeadOfficeEntry({
    required String headOfficeId,
    required String expenseHeadId,
    required double amount,
    String? note,
  }) async {
    final counter = await _client.rpc('get_or_create_ho_counter')
        as Map<String, dynamic>;
    await _client.from('head_office_expenses').insert({
      'head_office_id': headOfficeId,
      'head_office_cash_counter_id': counter['id'],
      'expense_head_id': expenseHeadId,
      'amount': amount,
      'note': note,
    });
    await _client.from('head_office_cash_counter').update({
      'net_amount': _num(counter['net_amount']) - amount,
      'expense': _num(counter['expense']) + amount,
    }).eq('id', counter['id']);
  }

  Future<void> updateHeadOfficeEntry({
    required ExpenseEntryModel entry,
    required String expenseHeadId,
    required double amount,
    String? note,
  }) async {
    await _client.from('head_office_expenses').update({
      'expense_head_id': expenseHeadId,
      'amount': amount,
      'note': note,
    }).eq('id', entry.id);
    await _adjustHeadOfficeCounter(
        entry.branchCashCounterId, amount - entry.amount);
  }

  Future<void> deleteHeadOfficeEntry(ExpenseEntryModel entry) async {
    await _client.from('head_office_expenses').delete().eq('id', entry.id);
    await _adjustHeadOfficeCounter(entry.branchCashCounterId, -entry.amount);
  }

  /// Expense jis din ka hai us counter ka `expense` badalta hai; cash
  /// (`net_amount`) aage carry hota hai is liye wo aaj ke counter pe.
  Future<void> _adjustHeadOfficeCounter(String counterId, double delta) async {
    if (delta == 0) return;
    final today = await _client.rpc('get_or_create_ho_counter')
        as Map<String, dynamic>;
    if (counterId == today['id']?.toString()) {
      await _client.from('head_office_cash_counter').update({
        'net_amount': _num(today['net_amount']) - delta,
        'expense': _num(today['expense']) + delta,
      }).eq('id', counterId);
      return;
    }
    if (counterId.isNotEmpty) {
      final row = await _client
          .from('head_office_cash_counter')
          .select('expense')
          .eq('id', counterId)
          .maybeSingle();
      if (row != null) {
        await _client.from('head_office_cash_counter').update({
          'expense': _num(row['expense']) + delta,
        }).eq('id', counterId);
      }
    }
    await _client.from('head_office_cash_counter').update({
      'net_amount': _num(today['net_amount']) - delta,
    }).eq('id', today['id']);
  }

  static double _num(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
