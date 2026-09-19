import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/branch_payment_model.dart';

class BranchPaymentDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  /// Branch pays the Head Office — deducts from today's branch cash counter
  /// and leaves the payment `pending` until Admin accepts it.
  Future<void> createPayment({
    required String branchId,
    required double amount,
    String? notes,
  }) async {
    await _client.rpc(
      'create_branch_payment',
      params: {'p_branch_id': branchId, 'p_amount': amount, 'p_notes': notes},
    );
  }

  Future<List<BranchPaymentModel>> fetchIncomingPayments(
    String headOfficeId,
  ) async {
    final res = await _client
        .from('branch_payments')
        .select('*, branches(branch_name)')
        .eq('head_office_id', headOfficeId)
        .order('paid_at', ascending: false);

    return (res as List)
        .map((e) => BranchPaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BranchPaymentModel>> fetchBranchPayments(String branchId) async {
    final res = await _client
        .from('branch_payments')
        .select('*, branches(branch_name)')
        .eq('branch_id', branchId)
        .order('paid_at', ascending: false);

    return (res as List)
        .map((e) => BranchPaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> acceptPayment(String paymentId) async {
    await _client.rpc('accept_branch_payment', params: {'p_payment_id': paymentId});
  }

  Future<void> rejectPayment(String paymentId) async {
    await _client.rpc('reject_branch_payment', params: {'p_payment_id': paymentId});
  }
}
