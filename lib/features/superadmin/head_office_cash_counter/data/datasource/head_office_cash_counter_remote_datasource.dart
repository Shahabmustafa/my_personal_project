import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/head_office_cash_counter_model.dart';

class HeadOfficeCashCounterRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetch all records, ordered by date descending. Ensures today's row
  /// exists first (same RPC the purchase screens use to open the counter).
  Future<List<HeadOfficeCashCounterModel>> getAll() async {
    await _client.rpc('get_or_create_ho_counter');

    final data = await _client
        .from('head_office_cash_counter')
        .select()
        .order('counter_date', ascending: false);

    return (data as List)
        .map((e) => HeadOfficeCashCounterModel.fromJson(e))
        .toList();
  }
}
