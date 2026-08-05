import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/customer_model.dart';

class CustomerRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetch all customers for a specific branch
  Future<List<CustomerModel>> getCustomersByBranch(String branchId) async {
    final data = await _client
        .from('customers')
        .select()
        .eq('branch_id', branchId)
        .order('name');
    return (data as List).map((e) => CustomerModel.fromJson(e)).toList();
  }

  /// Fetch all customers (superadmin/admin)
  Future<List<CustomerModel>> getAllCustomers() async {
    final data = await _client
        .from('customers')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => CustomerModel.fromJson(e)).toList();
  }

  /// Fetch customers for multiple branches
  Future<List<CustomerModel>> getCustomersForBranches(
      List<String> branchIds) async {
    if (branchIds.isEmpty) return [];
    final data = await _client
        .from('customers')
        .select()
        .inFilter('branch_id', branchIds)
        .order('name');
    return (data as List).map((e) => CustomerModel.fromJson(e)).toList();
  }

  /// Create new customer
  Future<CustomerModel> createCustomer(CustomerModel customer) async {
    // Duplicate phone check (if phone provided)
    if (customer.phoneNumber.isNotEmpty) {
      final existing = await _client
          .from('customers')
          .select('id')
          .eq('phone_number', customer.phoneNumber)
          .maybeSingle();
      if (existing != null) {
        throw Exception(
            'A customer with this phone number already exists');
      }
    }
    final data = await _client
        .from('customers')
        .insert(customer.toJson())
        .select()
        .single();
    return CustomerModel.fromJson(data);
  }

  /// Update customer info
  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    final data = await _client
        .from('customers')
        .update(customer.toJson())
        .eq('id', customer.id)
        .select()
        .single();
    return CustomerModel.fromJson(data);
  }

  /// Add loyalty points
  Future<CustomerModel> addLoyaltyPoints({
    required String customerId,
    required int points,
  }) async {
    // Get current points first
    final current = await _client
        .from('customers')
        .select('loyalty_points')
        .eq('id', customerId)
        .single();

    final currentPoints = (current['loyalty_points'] as num?)?.toInt() ?? 0;

    final data = await _client
        .from('customers')
        .update({'loyalty_points': currentPoints + points})
        .eq('id', customerId)
        .select()
        .single();
    return CustomerModel.fromJson(data);
  }

  /// Redeem loyalty points
  Future<CustomerModel> redeemLoyaltyPoints({
    required String customerId,
    required int points,
  }) async {
    final current = await _client
        .from('customers')
        .select('loyalty_points')
        .eq('id', customerId)
        .single();

    final currentPoints = (current['loyalty_points'] as num?)?.toInt() ?? 0;
    if (currentPoints < points) {
      throw Exception('Not enough loyalty points');
    }

    final data = await _client
        .from('customers')
        .update({'loyalty_points': currentPoints - points})
        .eq('id', customerId)
        .select()
        .single();
    return CustomerModel.fromJson(data);
  }

  /// Delete customer
  Future<void> deleteCustomer(String id) async {
    await _client.from('customers').delete().eq('id', id);
  }

  /// Toggle active status
  Future<CustomerModel> toggleActive({
    required String customerId,
    required bool isActive,
  }) async {
    final data = await _client
        .from('customers')
        .update({'is_active': isActive})
        .eq('id', customerId)
        .select()
        .single();
    return CustomerModel.fromJson(data);
  }
}