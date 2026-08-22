import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../purchase_invoice/data/models/warehouse_stock_model.dart';
import '../../data/datasources/assign_stock_datasource.dart';
import '../../data/models/assign_stock_model.dart';
import '../../data/repositories/assign_stock_repository.dart';
import '../../../shared/current_warehouse_provider.dart';

// ── Infrastructure ────────────────────────────────────────────────────────
final assignStockDatasourceProvider = Provider<AssignStockDatasource>(
  (ref) => AssignStockDatasource(Supabase.instance.client),
);

final assignStockRepositoryProvider = Provider<AssignStockRepository>(
  (ref) => AssignStockRepository(ref.read(assignStockDatasourceProvider)),
);

// ── Branches dropdown ─────────────────────────────────────────────────────
final branchesProvider = FutureProvider<List<BranchModel>>(
  (ref) => ref.watch(assignStockRepositoryProvider).getBranches(),
);

// ── Warehouse stock cache ─────────────────────────────────────────────────
final assignWarehouseStockProvider =
    FutureProvider<List<WarehouseStockModel>>(
  (ref) => ref
      .watch(assignStockRepositoryProvider)
      .getWarehouseStock(ref.watch(currentWarehouseIdProvider)),
);

// ── Assignment list ───────────────────────────────────────────────────────

class AssignListState {
  final List<AssignStockModel> assignments;
  final bool isLoading;
  final String? error;

  const AssignListState({
    this.assignments = const [],
    this.isLoading = false,
    this.error,
  });

  AssignListState copyWith({
    List<AssignStockModel>? assignments,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      AssignListState(
        assignments: assignments ?? this.assignments,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class AssignListNotifier extends StateNotifier<AssignListState> {
  final AssignStockRepository _repo;
  final String _warehouseId;

  AssignListNotifier(this._repo, this._warehouseId)
      : super(const AssignListState()) {
    loadAssignments();
  }

  Future<void> loadAssignments() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repo.getAssignments(_warehouseId);
      state = state.copyWith(assignments: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> acceptAssignment(String assignmentId) async {
    try {
      await _repo.acceptAssignment(assignmentId);
      await loadAssignments();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> rejectAssignment(String assignmentId) async {
    try {
      await _repo.rejectAssignment(assignmentId);
      await loadAssignments();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final assignListProvider =
    StateNotifierProvider<AssignListNotifier, AssignListState>(
  (ref) => AssignListNotifier(
    ref.read(assignStockRepositoryProvider),
    ref.watch(currentWarehouseIdProvider),
  ),
);

// ── Cart / active assignment state ────────────────────────────────────────

class AssignStockState {
  final String assignmentNumber;
  final bool numberLoading;
  final BranchModel? selectedBranch;
  final List<AssignCartItem> cartItems;
  final bool isSaving;
  final String? error;

  const AssignStockState({
    this.assignmentNumber = '',
    this.numberLoading = false,
    this.selectedBranch,
    this.cartItems = const [],
    this.isSaving = false,
    this.error,
  });

  int get totalQuantity =>
      cartItems.fold(0, (sum, i) => sum + i.quantity);

  AssignStockState copyWith({
    String? assignmentNumber,
    bool? numberLoading,
    BranchModel? selectedBranch,
    bool clearBranch = false,
    List<AssignCartItem>? cartItems,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) =>
      AssignStockState(
        assignmentNumber: assignmentNumber ?? this.assignmentNumber,
        numberLoading: numberLoading ?? this.numberLoading,
        selectedBranch:
            clearBranch ? null : selectedBranch ?? this.selectedBranch,
        cartItems: cartItems ?? this.cartItems,
        isSaving: isSaving ?? this.isSaving,
        error: clearError ? null : error ?? this.error,
      );
}

class AssignStockNotifier extends StateNotifier<AssignStockState> {
  final AssignStockRepository _repo;
  final String _warehouseId;

  AssignStockNotifier(this._repo, this._warehouseId)
      : super(const AssignStockState()) {
    _loadNumber();
  }

  Future<void> _loadNumber() async {
    if (!mounted) return;
    state = state.copyWith(numberLoading: true);
    try {
      final num = await _repo.generateAssignmentNumber();
      if (mounted) {
        state = state.copyWith(assignmentNumber: num, numberLoading: false);
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(
            assignmentNumber: 'ASB-000001', numberLoading: false);
      }
    }
  }

  void selectBranch(BranchModel? branch) {
    if (branch == null) {
      state = state.copyWith(clearBranch: true);
    } else {
      state = state.copyWith(selectedBranch: branch);
    }
  }

  // ── Add to cart with full stock validation ────────────────────────────
  // Returns null = success | error message = validation failed
  String? addCartItem(WarehouseStockModel stock, {int quantity = 1}) {
    // ✅ Zero stock check
    if (stock.quantity <= 0) {
      return 'No stock available for this item';
    }

    final existing =
        state.cartItems.indexWhere((c) => c.stockId == stock.id);

    if (existing != -1) {
      final cur = state.cartItems[existing];
      final newQty = cur.quantity + quantity;

      // ✅ Combined qty > warehouse stock check
      if (newQty > stock.quantity) {
        final remaining = stock.quantity - cur.quantity;
        if (remaining <= 0) {
          return 'Maximum stock reached. Available: ${stock.quantity}, already in cart: ${cur.quantity}';
        }
        return 'Only $remaining more can be added. Available: ${stock.quantity}, in cart: ${cur.quantity}';
      }

      final updated = List<AssignCartItem>.from(state.cartItems);
      updated[existing] = cur.copyWith(quantity: newQty);
      state = state.copyWith(cartItems: updated, clearError: true);
      return null;
    }

    // ✅ New item qty > warehouse stock check
    if (quantity > stock.quantity) {
      return 'Insufficient stock. Requested: $quantity, Available: ${stock.quantity}';
    }

    final item = AssignCartItem(
      stockId:        stock.id,
      barcode:        stock.barcode,
      productId:      stock.productId,
      productName:    stock.productName ?? '',
      sizeId:         stock.sizeId,
      sizeName:       stock.sizeName ?? '',
      colorId:        stock.colorId,
      colorName:      stock.colorName ?? '',
      brandId:        stock.brandId,
      brandName:      stock.brandName ?? '',
      categoryId:     stock.categoryId,
      categoryName:   stock.categoryName ?? '',
      typeId:         stock.typeId,
      typeName:       stock.typeName ?? '',
      warehouseStock: stock.quantity,
      quantity:       quantity,
      salePrice:      stock.salePrice,
      purchasePrice:  stock.purchasePrice,
      discount:       stock.discountPct,
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
      // ✅ warehouseStock se zyada kabhi nahi
      final safe = quantity > i.warehouseStock ? i.warehouseStock : quantity;
      return i.copyWith(quantity: safe);
    }).toList();
    state = state.copyWith(cartItems: updated);
  }

  void removeItem(String stockId) {
    state = state.copyWith(
      cartItems: state.cartItems.where((c) => c.stockId != stockId).toList(),
    );
  }

  void clearCart() {
    state = state.copyWith(cartItems: []);
  }

  Future<String?> saveAssignment({String? notes}) async {
    if (state.cartItems.isEmpty) return 'Cart is empty';
    if (state.selectedBranch == null) return 'Please select a branch';

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final freshNumber = await _repo.generateAssignmentNumber();

      await _repo.saveAssignment(
        assignmentNumber: freshNumber,
        warehouseId:      _warehouseId,
        branchId:         state.selectedBranch!.id,
        cartItems:        state.cartItems,
        notes:            notes,
      );

      if (mounted) {
        state = state.copyWith(isSaving: false, assignmentNumber: freshNumber);
      }
      return null;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isSaving: false, error: e.toString());
      }
      return e.toString();
    }
  }

  Future<void> resetAssignment() async {
    if (!mounted) return;
    state = const AssignStockState(numberLoading: true);
    await _loadNumber();
  }
}

final assignStockProvider =
    StateNotifierProvider<AssignStockNotifier, AssignStockState>(
  (ref) => AssignStockNotifier(
    ref.read(assignStockRepositoryProvider),
    ref.watch(currentWarehouseIdProvider),
  ),
);
