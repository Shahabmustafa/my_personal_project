import '../../data/model/product_model.dart';

enum ProductStatus { initial, loading, success, error }

class ProductState {
  final ProductStatus status;
  final List<ProductModel> items;
  final String? errorMessage;

  const ProductState({
    this.status = ProductStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  ProductState copyWith({
    ProductStatus? status,
    List<ProductModel>? items,
    String? errorMessage,
  }) {
    return ProductState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  bool get isLoading => status == ProductStatus.loading;
}
