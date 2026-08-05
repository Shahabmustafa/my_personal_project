import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/datasource/company_remote_datasource.dart';
import '../../data/model/company_model.dart';
import '../../data/repository/company_repository.dart';
import 'company_state.dart';

final companyRemoteDatasourceProvider =
    Provider<CompanyRemoteDatasource>((_) => CompanyRemoteDatasource());

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepository(
      remoteDatasource: ref.read(companyRemoteDatasourceProvider));
});

class CompanyNotifier extends StateNotifier<CompanyState> {
  final CompanyRepository _repo;
  CompanyNotifier(this._repo) : super(const CompanyState());

  Future<void> loadAllCompanies() async {
    state = state.copyWith(status: CompanyStatus.loading, errorMessage: null);
    try {
      final companies = await _repo.getAllCompanies();
      state =
          state.copyWith(status: CompanyStatus.success, companies: companies);
    } catch (e) {
      state = state.copyWith(
          status: CompanyStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> loadCompaniesByWarehouse(String warehouseId) async {
    state = state.copyWith(status: CompanyStatus.loading, errorMessage: null);
    try {
      final companies = await _repo.getCompaniesByWarehouse(warehouseId);
      state =
          state.copyWith(status: CompanyStatus.success, companies: companies);
    } catch (e) {
      state = state.copyWith(
          status: CompanyStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> loadCompaniesForWarehouses(List<String> warehouseIds) async {
    state = state.copyWith(status: CompanyStatus.loading, errorMessage: null);
    try {
      final companies = await _repo.getCompaniesForWarehouses(warehouseIds);
      state =
          state.copyWith(status: CompanyStatus.success, companies: companies);
    } catch (e) {
      state = state.copyWith(
          status: CompanyStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> createCompany(CompanyModel company) async {
    state = state.copyWith(status: CompanyStatus.loading, errorMessage: null);
    try {
      await _repo.createCompany(company);
      // Fresh reload to avoid duplicates
      final companies = await _repo.getAllCompanies();
      state = state.copyWith(
        status: CompanyStatus.success,
        companies: companies,
      );
    } catch (e) {
      state = state.copyWith(
          status: CompanyStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> updateCompany(CompanyModel company) async {
    state = state.copyWith(status: CompanyStatus.loading, errorMessage: null);
    try {
      final updated = await _repo.updateCompany(company);
      final list = state.companies
          .map((c) => c.id == updated.id ? updated : c)
          .toList();
      state =
          state.copyWith(status: CompanyStatus.success, companies: list);
    } catch (e) {
      state = state.copyWith(
          status: CompanyStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> deleteCompany(String id) async {
    state = state.copyWith(status: CompanyStatus.loading, errorMessage: null);
    try {
      await _repo.deleteCompany(id);
      final list = state.companies.where((c) => c.id != id).toList();
      state =
          state.copyWith(status: CompanyStatus.success, companies: list);
    } catch (e) {
      state = state.copyWith(
          status: CompanyStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final companyProvider =
    StateNotifierProvider<CompanyNotifier, CompanyState>((ref) {
  return CompanyNotifier(ref.read(companyRepositoryProvider));
});
