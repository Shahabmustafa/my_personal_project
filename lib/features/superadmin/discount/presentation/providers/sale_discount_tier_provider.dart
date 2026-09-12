import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasource/sale_discount_tier_datasource.dart';
import '../../data/model/sale_discount_tier_model.dart';
import '../../data/repository/sale_discount_tier_repository.dart';

final saleDiscountTierDatasourceProvider = Provider<SaleDiscountTierDatasource>(
  (_) => SaleDiscountTierDatasource(Supabase.instance.client),
);

final saleDiscountTierRepositoryProvider = Provider<SaleDiscountTierRepository>(
  (ref) => SaleDiscountTierRepository(ref.read(saleDiscountTierDatasourceProvider)),
);

/// Sale Invoice (aur kahin bhi) se seedha read karne ke liye — sab tiers,
/// highest min_sale_amount pehle.
final saleDiscountTiersProvider = FutureProvider<List<SaleDiscountTierModel>>(
  (ref) => ref.read(saleDiscountTierRepositoryProvider).getAll(),
);

class SaleDiscountTierState {
  final List<SaleDiscountTierModel> tiers;
  final bool isLoading;
  final String? error;

  const SaleDiscountTierState({this.tiers = const [], this.isLoading = false, this.error});

  SaleDiscountTierState copyWith({
    List<SaleDiscountTierModel>? tiers,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      SaleDiscountTierState(
        tiers: tiers ?? this.tiers,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

/// Superadmin/admin ki "Sale Discount Tiers" screen ke CRUD ke liye.
class SaleDiscountTierNotifier extends StateNotifier<SaleDiscountTierState> {
  final SaleDiscountTierRepository _repo;
  final Ref _ref;
  SaleDiscountTierNotifier(this._repo, this._ref) : super(const SaleDiscountTierState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tiers = await _repo.getAll();
      state = state.copyWith(tiers: tiers, isLoading: false);
      _ref.invalidate(saleDiscountTiersProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> addTier(SaleDiscountTierModel tier) async {
    await _repo.create(tier);
    await load();
  }

  Future<void> updateTier(SaleDiscountTierModel tier) async {
    await _repo.update(tier);
    await load();
  }

  Future<void> deleteTier(String id) async {
    await _repo.delete(id);
    await load();
  }
}

final saleDiscountTierNotifierProvider =
    StateNotifierProvider<SaleDiscountTierNotifier, SaleDiscountTierState>(
  (ref) => SaleDiscountTierNotifier(ref.read(saleDiscountTierRepositoryProvider), ref),
);
