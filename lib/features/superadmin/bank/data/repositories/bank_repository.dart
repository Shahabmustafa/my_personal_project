import '../datasources/bank_datasource.dart';
import '../models/bank_head_model.dart';
import '../models/bank_entry_model.dart';

class BankRepository {
  final BankDatasource _datasource;
  BankRepository(this._datasource);

  // Bank Heads
  Future<List<BankHeadModel>> getBankHeads()  => _datasource.fetchBankHeads();
  Future<void> addBankHead(String name)        => _datasource.insertBankHead(name);
  Future<void> removeBankHead(String id)       => _datasource.deleteBankHead(id);

  // Bank Entries
  Future<List<BankEntryModel>> getBankEntries() => _datasource.fetchBankEntries();
  Future<void> addBankEntry({
    required String bankId,
    required String branchId,
    required String accountNumber,
    required double openingBalance,
  }) =>
      _datasource.insertBankEntry(
        bankId:         bankId,
        branchId:       branchId,
        accountNumber:  accountNumber,
        openingBalance: openingBalance,
      );
  Future<void> removeBankEntry(String id) => _datasource.deleteBankEntry(id);
}
