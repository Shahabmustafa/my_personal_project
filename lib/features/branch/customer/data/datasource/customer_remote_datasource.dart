import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/pagination/pagination.dart';
import '../model/customer_model.dart';

class CustomerRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  /// Server-paginated customers. [branchIds] null = every customer (admin);
  /// otherwise the given branches' customers plus the shared walk-in customer.
  /// Searches name / phone / email / address via PostgreSQL `ilike`.
  Future<PageResult<CustomerModel>> fetchPage(
    PageRequest request, {
    List<String>? branchIds,
  }) async {
    var query = _client.from('customers').select();
    if (branchIds != null) {
      if (branchIds.isEmpty) {
        query = query.eq('is_walkin', true);
      } else {
        query = query.or(
            'branch_id.in.(${branchIds.join(',')}),is_walkin.eq.true');
      }
    }
    if (request.search.isNotEmpty) {
      final q = request.search;
      query = query.or(
          'name.ilike.%$q%,phone_number.ilike.%$q%,email.ilike.%$q%,address.ilike.%$q%');
    }
    final result = await runSupabasePage(
      query.order('is_walkin', ascending: false).order('name'),
      request: request,
    );
    return result.map(CustomerModel.fromJson);
  }

  /// Fetch all customers for a specific branch, plus the one shared
  /// Walk-in Customer (branch_id is null, is_walkin true) that every
  /// branch can select without creating its own.
  Future<List<CustomerModel>> getCustomersByBranch(String branchId) async {
    final data = await _client
        .from('customers')
        .select()
        .or('branch_id.eq.$branchId,is_walkin.eq.true')
        .order('is_walkin', ascending: false)
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

  /// Fetch customers for multiple branches, plus the shared Walk-in Customer.
  Future<List<CustomerModel>> getCustomersForBranches(
      List<String> branchIds) async {
    if (branchIds.isEmpty) return [];
    final ids = branchIds.join(',');
    final data = await _client
        .from('customers')
        .select()
        .or('branch_id.in.($ids),is_walkin.eq.true')
        .order('is_walkin', ascending: false)
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