import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../branch_stock_inventory/data/model/branch_stock_model.dart';
import '../../../sale_invoice/presentation/provider/sale_invoice_provider.dart'
    show branchStockCacheProvider;
import '../../../shared/current_branch_provider.dart';
import '../../data/datasource/branch_return_cart_item.dart';
import '../../data/datasource/branch_stock_return_datasource.dart';
import '../../data/model/branch_stock_return_model.dart';
import '../../data/repository/branch_stock_return_repository.dart';

// ── Infrastructure ────────────────────────────────────────────────────────

final branchStockReturnDatasourceProvider = Provider<BranchStockReturnDatasource>(
  (_) => BranchStockReturnDatasource(Supabase.instance.client),
);

final branchStockReturnRepositoryProvider = Provider<BranchStockReturnRepository>(
  (ref) => BranchStockReturnRepository(ref.read(branchStockReturnDatasourceProvider)),
);

// ── Destination branches (sab active branches, khud ko chhod kar) ─────────

final otherBranchesForReturnProvider = FutureProvider<List<BranchModel>>(
  (ref) => ref
      .watch(branchStockReturnRepositoryProvider)
      .getOtherBranches(ref.watch(currentBranchIdProvider)),
);

// ── Sent / incoming returns lists ──────────────────────────────────────────

final sentStockReturnsProvider = FutureProvider<List<BranchStockReturnModel>>(
  (ref) => ref
      .watch(branchStockReturnRepositoryProvider)
      .getSentReturns(ref.watch(currentBranchIdProvider)),
);

final incomingStockReturnsProvider = FutureProvider<List<BranchStockReturnModel>>(
  (ref) => ref
      .watch(branchStockReturnRepositoryProvider)
      .getIncomingReturns(ref.watch(currentBranchIdProvider)),
);

// ── Cart / active return state ─────────────────────────────────────────────

class BranchStockReturnState {
  final String returnNumber;
  final bool numberLoading;
  final BranchModel? destinationBranch;
  final List<BranchReturnCartItem> cartItems;
  final bool isSaving;
  final String? error;

  const BranchStockReturnState({
    this.returnNumber = '',
    this.numberLoading = false,
    this.destinationBranch,
    this.cartItems = const [],
    this.isSaving = false,
    this.error,
  });

  int get totalQuantity => cartItems.fold(0, (sum, i) => sum + i.quantity);

  BranchStockReturnState copyWith({
    String? returnNumber,
    bool? numberLoading,
    BranchModel? destinationBranch,
    bool clearDestination = false,
    List<BranchReturnCartItem>? cartItems,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) =>
      BranchStockReturnState(
        returnNumber: returnNumber ?? this.returnNumber,
        numberLoading: numberLoading ?? this.numberLoading,
        destinationBranch:
            clearDestination ? null : destinationBranch ?? this.destinationBranch,
        cartItems: cartItems ?? this.cartItems,
        isSaving: isSaving ?? this.isSaving,
        error: clearError ? null : error ?? this.error,
      );
}

class BranchStockReturnNotifier extends StateNotifier<BranchStockReturnState> {
  final Ref _ref;
  final BranchStockReturnRepository _repo;
  final String _fromBranchId;

  BranchStockReturnNotifier(this._ref, this._repo, this._fromBranchId)
      : super(const BranchStockReturnState()) {
    _loadNumber();
  }

  Future<void> _loadNumber() async {
    if (!mounted) return;
    state = state.copyWith(numberLoading: true);
    try {
      final num = await _repo.generateReturnNumber();
      if (mounted) {
        state = state.copyWith(returnNumber: num, numberLoading: false);
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(returnNumber: 'RTB-000001', numberLoading: false);
      }
    }
  }

  void selectDestinationBranch(BranchModel? branch) {
    if (branch == null) {
      state = state.copyWith(clearDestination: true);
    } else {
      state = state.copyWith(destinationBranch: branch);
    }
  }

  /// Returns null = success | error message = validation failed.
  String? addCartItem(BranchStockModel stock, {int quantity = 1}) {
    if (stock.quantity <= 0) {
      return 'No stock available for this item in your branch';
    }

    final existing = state.cartItems.indexWhere((c) => c.stockId == stock.id);

    if (existing != -1) {
      final cur = state.cartItems[existing];
      final newQty = cur.quantity + quantity;

      if (newQty > stock.quantity) {
        final remaining = stock.quantity - cur.quantity;
        if (remaining <= 0) {
          return 'Maximum stock reached. Available: ${stock.quantity}, already in cart: ${cur.quantity}';
        }
        return 'Only $remaining more can be added. Available: ${stock.quantity}, in cart: ${cur.quantity}';
      }

      final updated = List<BranchReturnCartItem>.from(state.cartItems);
      updated[existing] = cur.copyWith(quantity: newQty);
      state = state.copyWith(cartItems: updated, clearError: true);
      return null;
    }

    if (quantity > stock.quantity) {
      return 'Insufficient stock. Requested: $quantity, Available: ${stock.quantity}';
    }

    final item = BranchReturnCartItem(
      stockId: stock.id,
      barcode: stock.barcode,
      productId: stock.productId,
      productName: stock.productName ?? '',
      sizeId: stock.sizeId,
      sizeName: stock.sizeName ?? '',
      colorId: stock.colorId,
      colorName: stock.colorName ?? '',
      brandId: stock.brandId,
      brandName: stock.brandName ?? '',
      categoryId: stock.categoryId,
      categoryName: stock.categoryName ?? '',
      typeId: stock.typeId,
      typeName: stock.typeName ?? '',
      availableStock: stock.quantity,
      quantity: quantity,
      salePrice: stock.salePrice,
      purchasePrice: stock.purchasePrice,
      discount: stock.discount,
    );

    state = state.copyWith(cartItems: [...state.cartItems, item], clearError: true);
    return null;
  }

  void updateItemQuantity(String stockId, int quantity) {
    if (quantity <= 0) {
      removeItem(stockId);
      return;
    }
    final updated = state.cartItems.map((i) {
      if (i.stockId != stockId) return i;
      final safe = quantity > i.availableStock ? i.availableStock : quantity;
      return i.copyWith(quantity: safe);
    }).toList();
    state = state.copyWith(cartItems: updated);
  }

  void removeItem(String stockId) {
    state = state.copyWith(
      cartItems: state.cartItems.where((c) => c.stockId != stockId).toList(),
    );
  }

  void clearCart() => state = state.copyWith(cartItems: []);

  Future<String?> saveReturn({String? notes}) async {
    if (state.cartItems.isEmpty) return 'Cart is empty';
    if (state.destinationBranch == null) return 'Please select a destination branch';

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final returnedBy = _ref.read(authProvider).user?.id;

      await _repo.saveReturn(
        fromBranchId: _fromBranchId,
        toBranchId: state.destinationBranch!.id,
        returnedBy: returnedBy,
        notes: notes,
        cartItems: state.cartItems,
      );

      if (mounted) {
        state = state.copyWith(isSaving: false);
      }
      _ref.invalidate(branchStockCacheProvider);
      return null;
    } catch (e) {
      // create_branch_stock_return raises a plain exception (e.g.
      // "Insufficient stock for BC-102: requested 5, available 2") which
      // Postgrest surfaces via PostgrestException.message.
      final message = e is PostgrestException ? e.message : e.toString();
      if (mounted) {
        state = state.copyWith(isSaving: false, error: message);
      }
      return message;
    }
  }

  Future<void> resetReturn() async {
    if (!mounted) return;
    state = const BranchStockReturnState(numberLoading: true);
    await _loadNumber();
  }
}

final branchStockReturnProvider =
    StateNotifierProvider<BranchStockReturnNotifier, BranchStockReturnState>(
  (ref) => BranchStockReturnNotifier(
    ref,
    ref.read(branchStockReturnRepositoryProvider),
    ref.watch(currentBranchIdProvider),
  ),
);
