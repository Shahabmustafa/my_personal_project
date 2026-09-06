import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../head_office_purchase/data/models/warehouse_stock_model.dart';
import '../../../shared/current_head_office_provider.dart';
import '../../data/datasources/ho_assign_stock_datasource.dart';
import '../../data/models/ho_assign_stock_model.dart';
import '../../data/repositories/ho_assign_stock_repository.dart';

// ── Infrastructure ────────────────────────────────────────────────────────
final hoAssignStockDatasourceProvider = Provider<HoAssignStockDatasource>(
  (ref) => HoAssignStockDatasource(Supabase.instance.client),
);

final hoAssignStockRepositoryProvider = Provider<HoAssignStockRepository>(
  (ref) => HoAssignStockRepository(ref.read(hoAssignStockDatasourceProvider)),
);

// ── Branches dropdown ─────────────────────────────────────────────────────
final hoAssignBranchesProvider = FutureProvider<List<HoBranchModel>>(
  (ref) => ref.watch(hoAssignStockRepositoryProvider).getBranches(),
);

// ── Head office stock cache ──────────────────────────────────────────────
final hoAssignStockListProvider = FutureProvider<List<WarehouseStockModel>>(
  (ref) => ref.watch(hoAssignStockRepositoryProvider).getHeadOfficeStock(),
);

// ── Assignment list ───────────────────────────────────────────────────────

class HoAssignListState {
  final List<HoAssignStockModel> assignments;
  final bool isLoading;
  final String? error;

  const HoAssignListState({
    this.assignments = const [],
    this.isLoading = false,
    this.error,
  });

  HoAssignListState copyWith({
    List<HoAssignStockModel>? assignments,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      HoAssignListState(
        assignments: assignments ?? this.assignments,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class HoAssignListNotifier extends StateNotifier<HoAssignListState> {
  final HoAssignStockRepository _repo;
  final String _headOfficeId;

  HoAssignListNotifier(this._repo, this._headOfficeId)
      : super(const HoAssignListState()) {
    loadAssignments();
  }

  Future<void> loadAssignments() async {
    if (_headOfficeId.isEmpty) {
      // Head office id abhi resolve ho raha hai (ya koi head office set nahi).
      state = state.copyWith(isLoading: true, clearError: true);
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repo.getAssignments(_headOfficeId);
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

final hoAssignListProvider =
    StateNotifierProvider<HoAssignListNotifier, HoAssignListState>(
  (ref) => HoAssignListNotifier(
    ref.read(hoAssignStockRepositoryProvider),
    ref.watch(currentHeadOfficeIdProvider),
  ),
);

/// One assignment with its full item breakdown — for the history detail panel.
final hoAssignmentDetailProvider =
    FutureProvider.family<HoAssignStockModel, String>((ref, id) =>
        ref.read(hoAssignStockRepositoryProvider).getAssignmentDetail(id));

// ── Cart / active assignment state ────────────────────────────────────────

class HoAssignStockState {
  final String assignmentNumber;
  final bool numberLoading;
  final HoBranchModel? selectedBranch;
  final List<HoAssignCartItem> cartItems;
  final bool isSaving;
  final String? error;

  const HoAssignStockState({
    this.assignmentNumber = '',
    this.numberLoading = false,
    this.selectedBranch,
    this.cartItems = const [],
    this.isSaving = false,
    this.error,
  });

  int get totalQuantity => cartItems.fold(0, (sum, i) => sum + i.quantity);

  /// Total cost of the stock being assigned = Σ (purchase price × quantity).
  double get totalPurchaseValue =>
      cartItems.fold(0.0, (sum, i) => sum + i.purchasePrice * i.quantity);

  HoAssignStockState copyWith({
    String? assignmentNumber,
    bool? numberLoading,
    HoBranchModel? selectedBranch,
    bool clearBranch = false,
    List<HoAssignCartItem>? cartItems,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) =>
      HoAssignStockState(
        assignmentNumber: assignmentNumber ?? this.assignmentNumber,
        numberLoading: numberLoading ?? this.numberLoading,
        selectedBranch:
            clearBranch ? null : selectedBranch ?? this.selectedBranch,
        cartItems: cartItems ?? this.cartItems,
        isSaving: isSaving ?? this.isSaving,
        error: clearError ? null : error ?? this.error,
      );
}

class HoAssignStockNotifier extends StateNotifier<HoAssignStockState> {
  final HoAssignStockRepository _repo;
  final String _headOfficeId;

  HoAssignStockNotifier(this._repo, this._headOfficeId)
      : super(const HoAssignStockState()) {
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

  void selectBranch(HoBranchModel? branch) {
    if (branch == null) {
      state = state.copyWith(clearBranch: true);
    } else {
      state = state.copyWith(selectedBranch: branch);
    }
  }

  // ── Add to cart with full stock validation ────────────────────────────
  String? addCartItem(WarehouseStockModel stock, {int quantity = 1}) {
    if (stock.quantity <= 0) {
      return 'No stock available for this item';
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

      final updated = List<HoAssignCartItem>.from(state.cartItems);
      updated[existing] = cur.copyWith(quantity: newQty);
      state = state.copyWith(cartItems: updated, clearError: true);
      return null;
    }

    if (quantity > stock.quantity) {
      return 'Insufficient stock. Requested: $quantity, Available: ${stock.quantity}';
    }

    final item = HoAssignCartItem(
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
      headOfficeStock: stock.quantity,
      quantity: quantity,
      salePrice: stock.salePrice,
      purchasePrice: stock.purchasePrice,
      discount: stock.discountPct,
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
      final safe = quantity > i.headOfficeStock ? i.headOfficeStock : quantity;
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
    if (_headOfficeId.isEmpty) {
      return 'Head office set nahi hai. Pehle Head Office add karein.';
    }

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final freshNumber = await _repo.generateAssignmentNumber();

      await _repo.saveAssignment(
        assignmentNumber: freshNumber,
        headOfficeId: _headOfficeId,
        branchId: state.selectedBranch!.id,
        cartItems: state.cartItems,
        notes: notes,
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
    state = const HoAssignStockState(numberLoading: true);
    await _loadNumber();
  }
}

final hoAssignStockProvider =
    StateNotifierProvider<HoAssignStockNotifier, HoAssignStockState>(
  (ref) => HoAssignStockNotifier(
    ref.read(hoAssignStockRepositoryProvider),
    ref.watch(currentHeadOfficeIdProvider),
  ),
);
