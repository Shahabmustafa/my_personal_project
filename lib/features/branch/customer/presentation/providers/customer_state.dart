import '../../data/model/customer_model.dart';

enum CustomerStatus { initial, loading, success, error }

class CustomerState {
  final CustomerStatus status;
  final List<CustomerModel> customers;
  final String? errorMessage;

  const CustomerState({
    this.status = CustomerStatus.initial,
    this.customers = const [],
    this.errorMessage,
  });

  CustomerState copyWith({
    CustomerStatus? status,
    List<CustomerModel>? customers,
    String? errorMessage,
  }) {
    return CustomerState(
      status: status ?? this.status,
      customers: customers ?? this.customers,
      errorMessage: errorMessage,
    );
  }

  bool get isLoading => status == CustomerStatus.loading;
}
