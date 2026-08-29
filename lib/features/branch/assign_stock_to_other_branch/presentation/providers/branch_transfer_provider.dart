import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../warehouse/assign_stock_to_branch/data/models/assign_stock_model.dart';
import '../../../branch_stock_inventory/data/model/branch_stock_model.dart';
import '../../../sale_invoice/presentation/provider/sale_invoice_provider.dart'
    show branchStockCacheProvider;
import '../../../shared/current_branch_provider.dart';
import '../../data/datasource/branch_transfer_cart_item.dart';
import '../../data/datasource/branch_transfer_datasource.dart';
import '../../data/repository/branch_transfer_repository.dart';

// ── Infrastructure ────────────────────────────────────────────────────────

final branchTransferDatasourceProvider = Provider<BranchTransferDatasource>(
  (_) => BranchTransferDatasource(Supabase.instance.client),
);

final branchTransferRepositoryProvider = Provider<BranchTransferRepository>(
  (ref) => BranchTransferRepository(ref.read(branchTransferDatasourceProvider)),
);

// ── Destination branches (sab active branches, khud ko chhod kar) ─────────

final otherBranchesProvider = FutureProvider<List<BranchModel>>(
  (ref) => ref
      .watch(branchTransferRepositoryProvider)
      .getOtherBranches(ref.watch(currentBranchIdProvider)),
);

// ── Sent transfers history (is branch ne doosri branches ko jo bheja) ──────

final sentTransfersProvider = FutureProvider<List<AssignStockModel>>(
  (ref) => ref
      .watch(branchTransferRepositoryProvider)
      .getSentTransfers(ref.watch(currentBranchIdProvider)),
);

// ── Cart / active transfer state ───────────────────────────────────────────

class BranchTransferState {
  final String transferNumber;
  final bool numberLoading;
  final BranchModel? destinationBranch;
  final List<BranchTransferCartItem> cartItems;
  final bool isSaving;
  final String? error;

  const BranchTransferState({
    this.transferNumber = '',
    this.numberLoading = false,
    this.destinationBranch,
    this.cartItems = const [],
    this.isSaving = false,
    this.error,
  });

  int get totalQuantity => cartItems.fold(0, (sum, i) => sum + i.quantity);

  BranchTransferState copyWith({
    String? transferNumber,
    bool? numberLoading,
    BranchModel? destinationBranch,
    bool clearDestination = false,
    List<BranchTransferCartItem>? cartItems,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) =>
      BranchTransferState(
        transferNumber: transferNumber ?? this.transferNumber,
        numberLoading: numberLoading ?? this.numberLoading,
        destinationBranch:
            clearDestination ? null : destinationBranch ?? this.destinationBranch,
        cartItems: cartItems ?? this.cartItems,
        isSaving: isSaving ?? this.isSaving,
        error: clearError ? null : error ?? this.error,
      );
}

class BranchTransferNotifier extends StateNotifier<BranchTransferState> {
  final Ref _ref;
  final BranchTransferRepository _repo;
  final String _fromBranchId;

  BranchTransferNotifier(this._ref, this._repo, this._fromBranchId)
      : super(const BranchTransferState()) {
    _loadNumber();
  }

  Future<void> _loadNumber() async {
    if (!mounted) return;
    state = state.copyWith(numberLoading: true);
    try {
      final num = await _repo.generateAssignmentNumber();
      if (mounted) {
        state = state.copyWith(transferNumber: num, numberLoading: false);
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(transferNumber: 'ASB-000001', numberLoading: false);
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

      final updated = List<BranchTransferCartItem>.from(state.cartItems);
      updated[existing] = cur.copyWith(quantity: newQty);
      state = state.copyWith(cartItems: updated, clearError: true);
      return null;
    }

    if (quantity > stock.quantity) {
      return 'Insufficient stock. Requested: $quantity, Available: ${stock.quantity}';
    }

    final item = BranchTransferCartItem(
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

  Future<String?> saveTransfer({String? notes}) async {
    if (state.cartItems.isEmpty) return 'Cart is empty';
    if (state.destinationBranch == null) return 'Please select a destination branch';

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final freshNumber = await _repo.generateAssignmentNumber();

      await _repo.saveTransfer(
        assignmentNumber: freshNumber,
        fromBranchId: _fromBranchId,
        toBranchId: state.destinationBranch!.id,
        cartItems: state.cartItems,
        notes: notes,
      );

      if (mounted) {
        state = state.copyWith(isSaving: false, transferNumber: freshNumber);
      }
      _ref.invalidate(branchStockCacheProvider);
      return null;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isSaving: false, error: e.toString());
      }
      return e.toString();
    }
  }

  Future<void> resetTransfer() async {
    if (!mounted) return;
    state = const BranchTransferState(numberLoading: true);
    await _loadNumber();
  }
}

final branchTransferProvider =
    StateNotifierProvider<BranchTransferNotifier, BranchTransferState>(
  (ref) => BranchTransferNotifier(
    ref,
    ref.read(branchTransferRepositoryProvider),
    ref.watch(currentBranchIdProvider),
  ),
);
