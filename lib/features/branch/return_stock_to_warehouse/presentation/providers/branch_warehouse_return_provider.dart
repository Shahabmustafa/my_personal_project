import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../superadmin/head_office/data/model/head_office_model.dart';
import '../../../branch_stock_inventory/data/model/branch_stock_model.dart';
import '../../../sale_invoice/presentation/provider/sale_invoice_provider.dart'
    show branchStockCacheProvider;
import '../../../shared/current_branch_provider.dart';
import '../../data/datasource/branch_warehouse_return_cart_item.dart';
import '../../data/datasource/branch_warehouse_return_datasource.dart';
import '../../data/model/branch_warehouse_return_model.dart';
import '../../data/repository/branch_warehouse_return_repository.dart';

// ── Infrastructure ────────────────────────────────────────────────────────

final branchWarehouseReturnDatasourceProvider =
    Provider<BranchWarehouseReturnDatasource>(
      (_) => BranchWarehouseReturnDatasource(Supabase.instance.client),
    );

final branchWarehouseReturnRepositoryProvider =
    Provider<BranchWarehouseReturnRepository>(
      (ref) => BranchWarehouseReturnRepository(
        ref.read(branchWarehouseReturnDatasourceProvider),
      ),
    );

// ── Destination — Admin (Head Office), auto-resolved, koi dropdown nahi ────

final returnHeadOfficeProvider = FutureProvider<HeadOfficeModel?>(
  (ref) => ref.watch(branchWarehouseReturnRepositoryProvider).getHeadOffice(),
);

// ── Sent returns (branch side) ──────────────────────────────────────────────

final sentWarehouseReturnsProvider =
    FutureProvider<List<BranchWarehouseReturnModel>>(
      (ref) => ref
          .watch(branchWarehouseReturnRepositoryProvider)
          .getSentReturns(ref.watch(currentBranchIdProvider)),
    );

// ── Cart / active return state ─────────────────────────────────────────────

class BranchWarehouseReturnState {
  final String returnNumber;
  final bool numberLoading;
  final HeadOfficeModel? destinationHeadOffice;
  final List<BranchWarehouseReturnCartItem> cartItems;
  final bool isSaving;
  final String? error;

  const BranchWarehouseReturnState({
    this.returnNumber = '',
    this.numberLoading = false,
    this.destinationHeadOffice,
    this.cartItems = const [],
    this.isSaving = false,
    this.error,
  });

  int get totalQuantity => cartItems.fold(0, (sum, i) => sum + i.quantity);

  BranchWarehouseReturnState copyWith({
    String? returnNumber,
    bool? numberLoading,
    HeadOfficeModel? destinationHeadOffice,
    bool clearDestination = false,
    List<BranchWarehouseReturnCartItem>? cartItems,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) => BranchWarehouseReturnState(
    returnNumber: returnNumber ?? this.returnNumber,
    numberLoading: numberLoading ?? this.numberLoading,
    destinationHeadOffice: clearDestination
        ? null
        : destinationHeadOffice ?? this.destinationHeadOffice,
    cartItems: cartItems ?? this.cartItems,
    isSaving: isSaving ?? this.isSaving,
    error: clearError ? null : error ?? this.error,
  );
}

class BranchWarehouseReturnNotifier
    extends StateNotifier<BranchWarehouseReturnState> {
  final Ref _ref;
  final BranchWarehouseReturnRepository _repo;
  final String _branchId;

  BranchWarehouseReturnNotifier(this._ref, this._repo, this._branchId)
    : super(const BranchWarehouseReturnState()) {
    _loadNumber();
    _loadHeadOffice();
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
        state = state.copyWith(
          returnNumber: 'RTW-000001',
          numberLoading: false,
        );
      }
    }
  }

  /// Admin (Head Office) auto-resolve hota hai — koi dropdown/selection nahi.
  Future<void> _loadHeadOffice() async {
    try {
      final headOffice = await _repo.getHeadOffice();
      if (mounted) {
        state = state.copyWith(
          destinationHeadOffice: headOffice,
          clearDestination: headOffice == null,
        );
      }
    } catch (_) {}
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

      final updated = List<BranchWarehouseReturnCartItem>.from(state.cartItems);
      updated[existing] = cur.copyWith(quantity: newQty);
      state = state.copyWith(cartItems: updated, clearError: true);
      return null;
    }

    if (quantity > stock.quantity) {
      return 'Insufficient stock. Requested: $quantity, Available: ${stock.quantity}';
    }

    final item = BranchWarehouseReturnCartItem(
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

    state = state.copyWith(
      cartItems: [...state.cartItems, item],
      clearError: true,
    );
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
    if (state.destinationHeadOffice == null) {
      return 'Admin (Head Office) not found. Please add one first.';
    }

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final returnedBy = _ref.read(authProvider).user?.id;

      await _repo.saveReturn(
        branchId: _branchId,
        headOfficeId: state.destinationHeadOffice!.id,
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
      final message = e is PostgrestException ? e.message : e.toString();
      if (mounted) {
        state = state.copyWith(isSaving: false, error: message);
      }
      return message;
    }
  }

  Future<void> resetReturn() async {
    if (!mounted) return;
    state = const BranchWarehouseReturnState(numberLoading: true);
    await _loadNumber();
    await _loadHeadOffice();
  }
}

final branchWarehouseReturnProvider =
    StateNotifierProvider<
      BranchWarehouseReturnNotifier,
      BranchWarehouseReturnState
    >(
      (ref) => BranchWarehouseReturnNotifier(
        ref,
        ref.read(branchWarehouseReturnRepositoryProvider),
        ref.watch(currentBranchIdProvider),
      ),
    );
