import '../datasource/customer_remote_datasource.dart';
import '../model/customer_model.dart';

class CustomerRepository {
  final CustomerRemoteDatasource remoteDatasource;
  CustomerRepository({required this.remoteDatasource});

  Future<List<CustomerModel>> getAllCustomers() =>
      remoteDatasource.getAllCustomers();

  Future<List<CustomerModel>> getCustomersByBranch(String branchId) =>
      remoteDatasource.getCustomersByBranch(branchId);

  Future<List<CustomerModel>> getCustomersForBranches(List<String> branchIds) =>
      remoteDatasource.getCustomersForBranches(branchIds);

  Future<CustomerModel> createCustomer(CustomerModel customer) =>
      remoteDatasource.createCustomer(customer);

  Future<CustomerModel> updateCustomer(CustomerModel customer) =>
      remoteDatasource.updateCustomer(customer);

  Future<CustomerModel> addLoyaltyPoints({
    required String customerId,
    required int points,
  }) =>
      remoteDatasource.addLoyaltyPoints(
          customerId: customerId, points: points);

  Future<CustomerModel> redeemLoyaltyPoints({
    required String customerId,
    required int points,
  }) =>
      remoteDatasource.redeemLoyaltyPoints(
          customerId: customerId, points: points);

  Future<void> deleteCustomer(String id) =>
      remoteDatasource.deleteCustomer(id);

  Future<CustomerModel> toggleActive({
    required String customerId,
    required bool isActive,
  }) =>
      remoteDatasource.toggleActive(
          customerId: customerId, isActive: isActive);
}
