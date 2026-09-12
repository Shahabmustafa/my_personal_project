import '../datasource/sale_discount_tier_datasource.dart';
import '../model/sale_discount_tier_model.dart';

class SaleDiscountTierRepository {
  final SaleDiscountTierDatasource _datasource;
  SaleDiscountTierRepository(this._datasource);

  Future<List<SaleDiscountTierModel>> getAll() => _datasource.getAll();
  Future<SaleDiscountTierModel> create(SaleDiscountTierModel tier) => _datasource.create(tier);
  Future<SaleDiscountTierModel> update(SaleDiscountTierModel tier) => _datasource.update(tier);
  Future<void> delete(String id) => _datasource.delete(id);
}
