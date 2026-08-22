import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bank_head_model.dart';
import '../models/bank_entry_model.dart';

class BankDatasource {
  final SupabaseClient _client;
  BankDatasource(this._client);

  // ─── BANK HEADS ──────────────────────────────────────────────────────────────

  Future<List<BankHeadModel>> fetchBankHeads() async {
    final response = await _client
        .from('bank_heads')
        .select('*')
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => BankHeadModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> insertBankHead(String bankName) async {
    await _client.from('bank_heads').insert({'bank_name': bankName});
  }

  Future<void> deleteBankHead(String id) async {
    await _client.from('bank_heads').delete().eq('id', id);
  }

  // ─── BANK ENTRIES ────────────────────────────────────────────────────────────

  Future<List<BankEntryModel>> fetchBankEntries() async {
    final response = await _client
        .from('bank_entries')
        .select('*, bank_heads(bank_name), branches(branch_name, address, city)')
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => BankEntryModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> insertBankEntry({
    required String bankId,
    required String branchId,
    required String accountNumber,
    required double openingBalance,
  }) async {
    await _client.from('bank_entries').insert({
      'bank_id':         bankId,
      'branch_id':       branchId,
      'account_number':  accountNumber,
      'opening_balance': openingBalance,
    });
  }

  Future<void> deleteBankEntry(String id) async {
    await _client.from('bank_entries').delete().eq('id', id);
  }
}
