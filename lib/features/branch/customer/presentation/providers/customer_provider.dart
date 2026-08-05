import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/datasource/customer_remote_datasource.dart';
import '../../data/model/customer_model.dart';
import '../../data/repository/customer_repository.dart';
import 'customer_state.dart';

final customerRemoteDatasourceProvider =
    Provider<CustomerRemoteDatasource>((_) => CustomerRemoteDatasource());

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(
      remoteDatasource: ref.read(customerRemoteDatasourceProvider));
});

class CustomerNotifier extends StateNotifier<CustomerState> {
  final CustomerRepository _repo;
  CustomerNotifier(this._repo) : super(const CustomerState());

  Future<void> loadAllCustomers() async {
    state = state.copyWith(status: CustomerStatus.loading, errorMessage: null);
    try {
      final customers = await _repo.getAllCustomers();
      state =
          state.copyWith(status: CustomerStatus.success, customers: customers);
    } catch (e) {
      state = state.copyWith(
          status: CustomerStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> loadCustomersByBranch(String branchId) async {
    state = state.copyWith(status: CustomerStatus.loading, errorMessage: null);
    try {
      final customers = await _repo.getCustomersByBranch(branchId);
      state =
          state.copyWith(status: CustomerStatus.success, customers: customers);
    } catch (e) {
      state = state.copyWith(
          status: CustomerStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> loadCustomersForBranches(List<String> branchIds) async {
    state = state.copyWith(status: CustomerStatus.loading, errorMessage: null);
    try {
      final customers = await _repo.getCustomersForBranches(branchIds);
      state =
          state.copyWith(status: CustomerStatus.success, customers: customers);
    } catch (e) {
      state = state.copyWith(
          status: CustomerStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> createCustomer(CustomerModel customer) async {
    state = state.copyWith(status: CustomerStatus.loading, errorMessage: null);
    try {
      await _repo.createCustomer(customer);
      // Fresh reload karo taake duplicate na ho
      final customers = await _repo.getAllCustomers();
      state = state.copyWith(
        status: CustomerStatus.success,
        customers: customers,
      );
    } catch (e) {
      state = state.copyWith(
          status: CustomerStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    state = state.copyWith(status: CustomerStatus.loading, errorMessage: null);
    try {
      final updated = await _repo.updateCustomer(customer);
      final list = state.customers
          .map((c) => c.id == updated.id ? updated : c)
          .toList();
      state =
          state.copyWith(status: CustomerStatus.success, customers: list);
    } catch (e) {
      state = state.copyWith(
          status: CustomerStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> addLoyaltyPoints({
    required String customerId,
    required int points,
  }) async {
    try {
      final updated = await _repo.addLoyaltyPoints(
          customerId: customerId, points: points);
      final list = state.customers
          .map((c) => c.id == updated.id ? updated : c)
          .toList();
      state = state.copyWith(customers: list);
    } catch (e) {
      state = state.copyWith(
          status: CustomerStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> redeemLoyaltyPoints({
    required String customerId,
    required int points,
  }) async {
    try {
      final updated = await _repo.redeemLoyaltyPoints(
          customerId: customerId, points: points);
      final list = state.customers
          .map((c) => c.id == updated.id ? updated : c)
          .toList();
      state = state.copyWith(customers: list);
    } catch (e) {
      state = state.copyWith(
          status: CustomerStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> deleteCustomer(String id) async {
    state = state.copyWith(status: CustomerStatus.loading, errorMessage: null);
    try {
      await _repo.deleteCustomer(id);
      final list = state.customers.where((c) => c.id != id).toList();
      state =
          state.copyWith(status: CustomerStatus.success, customers: list);
    } catch (e) {
      state = state.copyWith(
          status: CustomerStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> toggleActive({
    required String customerId,
    required bool isActive,
  }) async {
    try {
      final updated = await _repo.toggleActive(
          customerId: customerId, isActive: isActive);
      final list = state.customers
          .map((c) => c.id == updated.id ? updated : c)
          .toList();
      state = state.copyWith(customers: list);
    } catch (e) {
      state = state.copyWith(
          status: CustomerStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final customerProvider =
    StateNotifierProvider<CustomerNotifier, CustomerState>((ref) {
  return CustomerNotifier(ref.read(customerRepositoryProvider));
});
