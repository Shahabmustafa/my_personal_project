import '../../data/model/company_model.dart';

enum CompanyStatus { initial, loading, success, error }

class CompanyState {
  final CompanyStatus status;
  final List<CompanyModel> companies;
  final String? errorMessage;

  const CompanyState({
    this.status = CompanyStatus.initial,
    this.companies = const [],
    this.errorMessage,
  });

  CompanyState copyWith({
    CompanyStatus? status,
    List<CompanyModel>? companies,
    String? errorMessage,
  }) {
    return CompanyState(
      status: status ?? this.status,
      companies: companies ?? this.companies,
      errorMessage: errorMessage,
    );
  }

  bool get isLoading => status == CompanyStatus.loading;
}
