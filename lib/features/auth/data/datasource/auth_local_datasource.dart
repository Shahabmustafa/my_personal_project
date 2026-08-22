import 'package:shared_preferences/shared_preferences.dart';
import '../model/user_model.dart';

class AuthLocalDatasource {
  static const _kId = 'user_id';
  static const _kUsername = 'user_username';
  static const _kEmail = 'user_email';
  static const _kPhone = 'user_phone';
  static const _kRole = 'user_role';
  static const _kIsActive = 'user_is_active';
  static const _kBranchIds = 'user_branch_ids';
  static const _kWarehouseIds = 'user_warehouse_ids';
  static const _kIsLoggedIn = 'is_logged_in';
  static const _kSelectedBranchId = 'selected_branch_id';
  static const _kSelectedWarehouseId = 'selected_warehouse_id';

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kId, user.id);
    await prefs.setString(_kUsername, user.username);
    await prefs.setString(_kEmail, user.email);
    await prefs.setString(_kPhone, user.phoneNumber);
    await prefs.setString(_kRole, user.role);
    await prefs.setBool(_kIsActive, user.isActive);
    await prefs.setString(_kBranchIds, user.branchIds.join(','));
    await prefs.setString(_kWarehouseIds, user.warehouseIds.join(','));
    await prefs.setBool(_kIsLoggedIn, true);
  }

  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_kIsLoggedIn) ?? false)) return null;
    final id = prefs.getString(_kId) ?? '';
    if (id.isEmpty) return null;

    return UserModel(
      id: id,
      username: prefs.getString(_kUsername) ?? '',
      email: prefs.getString(_kEmail) ?? '',
      phoneNumber: prefs.getString(_kPhone) ?? '',
      role: prefs.getString(_kRole) ?? 'salesman',
      isActive: prefs.getBool(_kIsActive) ?? true,
      branchIds: _parseIds(prefs.getString(_kBranchIds)),
      warehouseIds: _parseIds(prefs.getString(_kWarehouseIds)),
    );
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsLoggedIn) ?? false;
  }

  Future<void> saveSelectedBranchId(String branchId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSelectedBranchId, branchId);
  }

  Future<String> getSelectedBranchId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kSelectedBranchId) ?? '';
  }

  Future<void> saveSelectedWarehouseId(String warehouseId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSelectedWarehouseId, warehouseId);
  }

  Future<String> getSelectedWarehouseId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kSelectedWarehouseId) ?? '';
  }

  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kId);
    await prefs.remove(_kUsername);
    await prefs.remove(_kEmail);
    await prefs.remove(_kPhone);
    await prefs.remove(_kRole);
    await prefs.remove(_kIsActive);
    await prefs.remove(_kBranchIds);
    await prefs.remove(_kWarehouseIds);
    await prefs.remove(_kSelectedBranchId);
    await prefs.remove(_kSelectedWarehouseId);
    await prefs.setBool(_kIsLoggedIn, false);
  }

  List<String> _parseIds(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    return raw.split(',').where((e) => e.isNotEmpty).toList();
  }
}
