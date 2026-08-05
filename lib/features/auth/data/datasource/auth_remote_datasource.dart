import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/user_model.dart';

class AuthRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final authResponse = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final authUser = authResponse.user;
    if (authUser == null) throw Exception('Invalid email or password');

    final data = await _client
        .from('users')
        .select('''
          id, username, email, phone_number, role, is_active,
          user_branches(branch_id),
          user_warehouses(warehouse_id)
        ''')
        .eq('id', authUser.id)
        .single();

    final user = UserModel.fromJson(data);

    if (!user.isActive) {
      await _client.auth.signOut();
      throw Exception('Your account has been deactivated. Contact admin.');
    }

    return user;
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  Future<UserModel?> fetchCurrentUser() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;
    try {
      final data = await _client
          .from('users')
          .select('''
            id, username, email, phone_number, role, is_active,
            user_branches(branch_id),
            user_warehouses(warehouse_id)
          ''')
          .eq('id', authUser.id)
          .single();
      return UserModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
