import '../datasource/expense_datasource.dart';
import '../model/expense_entry_model.dart';
import '../model/expense_head_model.dart';

class ExpenseRepository {
  final ExpenseDatasource _datasource;
  ExpenseRepository(this._datasource);

  Future<List<ExpenseHeadModel>> getHeads() => _datasource.getHeads();

  Future<ExpenseHeadModel> addHead({
    required String name,
    String? description,
  }) =>
      _datasource.addHead(name: name, description: description);

  Future<List<ExpenseEntryModel>> getEntriesByBranch(String branchId) =>
      _datasource.getEntriesByBranch(branchId);

  Future<String?> getTodaysCashCounterId(String branchId) =>
      _datasource.getTodaysCashCounterId(branchId);

  Future<void> addEntry({
    required String branchId,
    required String branchCashCounterId,
    required String expenseHeadId,
    required double amount,
    String? note,
  }) =>
      _datasource.addEntry(
        branchId: branchId,
        branchCashCounterId: branchCashCounterId,
        expenseHeadId: expenseHeadId,
        amount: amount,
        note: note,
      );

  Future<void> deleteEntry(String id) => _datasource.deleteEntry(id);
}
