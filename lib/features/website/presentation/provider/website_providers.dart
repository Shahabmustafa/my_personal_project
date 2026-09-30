import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/model/website_models.dart';

enum WebsiteTab { home, shop, cart }

final websiteTabProvider = StateProvider<WebsiteTab>((_) => WebsiteTab.home);

/// Category selected on the Shop tab; set from Home so tiles deep-link.
/// Null = all categories.
final shopCategoryProvider = StateProvider<String?>((_) => null);

class CartLine {
  final Shoe shoe;
  final int size;
  final int qty;

  const CartLine({required this.shoe, required this.size, required this.qty});

  String get key => '${shoe.id}:$size';
  double get total => shoe.price * qty;

  CartLine copyWith({int? qty}) => CartLine(shoe: shoe, size: size, qty: qty ?? this.qty);
}

class CartNotifier extends Notifier<List<CartLine>> {
  @override
  List<CartLine> build() => const [];

  void add(Shoe shoe, int size, {int qty = 1}) {
    final key = '${shoe.id}:$size';
    if (state.any((l) => l.key == key)) {
      state = [for (final l in state) if (l.key == key) l.copyWith(qty: l.qty + qty) else l];
    } else {
      state = [...state, CartLine(shoe: shoe, size: size, qty: qty)];
    }
  }

  void setQty(String key, int qty) {
    state = qty <= 0
        ? state.where((l) => l.key != key).toList()
        : [for (final l in state) if (l.key == key) l.copyWith(qty: qty) else l];
  }

  void clear() => state = const [];
}

final cartProvider = NotifierProvider<CartNotifier, List<CartLine>>(CartNotifier.new);

final cartCountProvider = Provider<int>((ref) => ref.watch(cartProvider).fold(0, (sum, l) => sum + l.qty));

final cartSubtotalProvider = Provider<double>(
  (ref) => ref.watch(cartProvider).fold(0.0, (sum, l) => sum + l.total),
);
