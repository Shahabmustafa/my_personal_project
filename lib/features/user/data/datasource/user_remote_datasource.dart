import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/data/model/user_model.dart';

class UserRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  static const _userSelect = '''
    id, username, email, phone_number, role, is_active,
    user_branches(branch_id),
    user_warehouses(warehouse_id),
    user_head_offices(head_office_id)
  ''';

  Future<List<UserModel>> getAllUsers() async {
    final data = await _client
        .from('users')
        .select(_userSelect)
        .order('created_at', ascending: false);
    return (data as List).map((e) => UserModel.fromJson(e)).toList();
  }

  Future<List<UserModel>> getUsersByBranch(String branchId) async {
    final junction = await _client
        .from('user_branches')
        .select('user_id')
        .eq('branch_id', branchId);
    final userIds =
        (junction as List).map((e) => e['user_id'].toString()).toList();
    if (userIds.isEmpty) return [];
    final data = await _client
        .from('users')
        .select(_userSelect)
        .inFilter('id', userIds);
    return (data as List).map((e) => UserModel.fromJson(e)).toList();
  }

  Future<List<UserModel>> getUsersByWarehouse(String warehouseId) async {
    final junction = await _client
        .from('user_warehouses')
        .select('user_id')
        .eq('warehouse_id', warehouseId);
    final userIds =
        (junction as List).map((e) => e['user_id'].toString()).toList();
    if (userIds.isEmpty) return [];
    final data = await _client
        .from('users')
        .select(_userSelect)
        .inFilter('id', userIds);
    return (data as List).map((e) => UserModel.fromJson(e)).toList();
  }

  Future<UserModel> getUserById(String id) async {
    final data = await _client
        .from('users')
        .select(_userSelect)
        .eq('id', id)
        .single();
    return UserModel.fromJson(data);
  }

  /// Create user in Supabase Auth + users table + auto assign branches
  Future<UserModel> createUser({
    required String email,
    required String password,
    required String username,
    required String role,
    String phoneNumber = '',
    List<String> branchIds = const [],
  }) async {
    // Step 1: Supabase Auth signup
    final authResponse = await _client.auth.signUp(
      email: email,
      password: password,
    );

    final authUser = authResponse.user;
    if (authUser == null) throw Exception('Failed to create auth user');

    // Step 2: Insert into users table
    await _client.from('users').insert({
      'id': authUser.id,
      'username': username,
      'email': email,
      'phone_number': phoneNumber,
      'role': role,
      'is_active': true,
    });

    // Step 3: Auto assign branches if provided
    if (branchIds.isNotEmpty) {
      await _client.from('user_branches').insert(
            branchIds
                .map((bid) => {'user_id': authUser.id, 'branch_id': bid})
                .toList(),
          );
    }

    // Step 4: Fetch full user with relations
    final data = await _client
        .from('users')
        .select(_userSelect)
        .eq('id', authUser.id)
        .single();

    return UserModel.fromJson(data);
  }

  Future<UserModel> updateUser({
    required String userId,
    String? role,
    bool? isActive,
    String? phoneNumber,
    String? username,
  }) async {
    final updates = <String, dynamic>{};
    if (role != null) updates['role'] = role;
    if (isActive != null) updates['is_active'] = isActive;
    if (phoneNumber != null) updates['phone_number'] = phoneNumber;
    if (username != null) updates['username'] = username;

    final data = await _client
        .from('users')
        .update(updates)
        .eq('id', userId)
        .select(_userSelect)
        .single();
    return UserModel.fromJson(data);
  }

  Future<void> assignBranchesToUser({
    required String userId,
    required List<String> branchIds,
  }) async {
    await _client.from('user_branches').delete().eq('user_id', userId);
    if (branchIds.isNotEmpty) {
      await _client.from('user_branches').insert(
            branchIds
                .map((bid) => {'user_id': userId, 'branch_id': bid})
                .toList(),
          );
    }
  }

  Future<void> assignWarehousesToUser({
    required String userId,
    required List<String> warehouseIds,
  }) async {
    await _client.from('user_warehouses').delete().eq('user_id', userId);
    if (warehouseIds.isNotEmpty) {
      await _client.from('user_warehouses').insert(
            warehouseIds
                .map((wid) => {'user_id': userId, 'warehouse_id': wid})
                .toList(),
          );
    }
  }

  Future<void> assignHeadOfficesToUser({
    required String userId,
    required List<String> headOfficeIds,
  }) async {
    await _client.from('user_head_offices').delete().eq('user_id', userId);
    if (headOfficeIds.isNotEmpty) {
      await _client.from('user_head_offices').insert(
            headOfficeIds
                .map((hid) => {'user_id': userId, 'head_office_id': hid})
                .toList(),
          );
    }
  }
}
