import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../../core/pagination/pagination.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasource/customer_remote_datasource.dart';
import '../../data/model/customer_model.dart';
import '../../data/repository/customer_repository.dart';

final customerRemoteDatasourceProvider =
    Provider<CustomerRemoteDatasource>((_) => CustomerRemoteDatasource());

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(
      remoteDatasource: ref.read(customerRemoteDatasourceProvider));
});

/// Server-paginated customers. Scope is resolved from the signed-in user:
/// branch/warehouse staff see their branches' customers (+ walk-in); admins
/// see every customer. Search runs as PostgreSQL `ilike` over
/// name/phone/email/address.
class CustomerNotifier extends PaginatedListNotifier<CustomerModel> {
  final CustomerRepository _repo;
  final List<String>? _scopeBranchIds;

  CustomerNotifier(this._repo, this._scopeBranchIds);

  @override
  Future<PageResult<CustomerModel>> fetchPage(PageRequest request) =>
      _repo.fetchPage(request, branchIds: _scopeBranchIds);

  static String _msg(Object e) => e.toString().replaceAll('Exception: ', '');

  Future<String?> createCustomer(CustomerModel customer) async {
    try {
      await _repo.createCustomer(customer);
      await refresh();
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  Future<String?> updateCustomer(CustomerModel customer) async {
    try {
      final updated = await _repo.updateCustomer(customer);
      replaceRow((c) => c.id == updated.id, updated);
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  Future<String?> deleteCustomer(String id) async {
    try {
      await _repo.deleteCustomer(id);
      removeRow((c) => c.id == id);
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  Future<String?> addLoyaltyPoints(
      {required String customerId, required int points}) async {
    try {
      final updated = await _repo.addLoyaltyPoints(
          customerId: customerId, points: points);
      replaceRow((c) => c.id == updated.id, updated);
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  Future<String?> redeemLoyaltyPoints(
      {required String customerId, required int points}) async {
    try {
      final updated = await _repo.redeemLoyaltyPoints(
          customerId: customerId, points: points);
      replaceRow((c) => c.id == updated.id, updated);
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  Future<String?> toggleActive(
      {required String customerId, required bool isActive}) async {
    try {
      final updated = await _repo.toggleActive(
          customerId: customerId, isActive: isActive);
      replaceRow((c) => c.id == updated.id, updated);
      return null;
    } catch (e) {
      return _msg(e);
    }
  }
}

final customerProvider = StateNotifierProvider<CustomerNotifier,
    PaginatedListState<CustomerModel>>((ref) {
  final user = ref.watch(authProvider).user;
  final scope = (user?.canManageBranches ?? false)
      ? null
      : (user?.branchIds ?? const <String>[]);
  return CustomerNotifier(ref.read(customerRepositoryProvider), scope);
});
