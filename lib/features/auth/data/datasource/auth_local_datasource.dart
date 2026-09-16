import '../../../../core/storage/app_kv_store.dart';
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

  final AppKvStore _store = AppKvStore();

  Future<void> saveUser(UserModel user) async {
    await _store.setString(_kId, user.id);
    await _store.setString(_kUsername, user.username);
    await _store.setString(_kEmail, user.email);
    await _store.setString(_kPhone, user.phoneNumber);
    await _store.setString(_kRole, user.role);
    await _store.setBool(_kIsActive, user.isActive);
    await _store.setString(_kBranchIds, user.branchIds.join(','));
    await _store.setString(_kWarehouseIds, user.warehouseIds.join(','));
    await _store.setBool(_kIsLoggedIn, true);
  }

  Future<UserModel?> getUser() async {
    if (!(await _store.getBool(_kIsLoggedIn) ?? false)) return null;
    final id = await _store.getString(_kId) ?? '';
    if (id.isEmpty) return null;

    return UserModel(
      id: id,
      username: await _store.getString(_kUsername) ?? '',
      email: await _store.getString(_kEmail) ?? '',
      phoneNumber: await _store.getString(_kPhone) ?? '',
      role: await _store.getString(_kRole) ?? 'salesman',
      isActive: await _store.getBool(_kIsActive) ?? true,
      branchIds: _parseIds(await _store.getString(_kBranchIds)),
      warehouseIds: _parseIds(await _store.getString(_kWarehouseIds)),
    );
  }

  Future<bool> isLoggedIn() async {
    return await _store.getBool(_kIsLoggedIn) ?? false;
  }

  Future<void> saveSelectedBranchId(String branchId) async {
    await _store.setString(_kSelectedBranchId, branchId);
  }

  Future<String> getSelectedBranchId() async {
    return await _store.getString(_kSelectedBranchId) ?? '';
  }

  Future<void> saveSelectedWarehouseId(String warehouseId) async {
    await _store.setString(_kSelectedWarehouseId, warehouseId);
  }

  Future<String> getSelectedWarehouseId() async {
    return await _store.getString(_kSelectedWarehouseId) ?? '';
  }

  Future<void> clearUser() async {
    await _store.remove(_kId);
    await _store.remove(_kUsername);
    await _store.remove(_kEmail);
    await _store.remove(_kPhone);
    await _store.remove(_kRole);
    await _store.remove(_kIsActive);
    await _store.remove(_kBranchIds);
    await _store.remove(_kWarehouseIds);
    await _store.remove(_kSelectedBranchId);
    await _store.remove(_kSelectedWarehouseId);
    await _store.setBool(_kIsLoggedIn, false);
  }

  List<String> _parseIds(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    return raw.split(',').where((e) => e.isNotEmpty).toList();
  }
}
