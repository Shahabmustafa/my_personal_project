import '../../data/model/category_model.dart';

enum CategoryStatus { initial, loading, success, error }

class CategoryState {
  final CategoryStatus status;
  final List<CategoryModel> items;
  final String? errorMessage;

  const CategoryState({
    this.status = CategoryStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  CategoryState copyWith({
    CategoryStatus? status,
    List<CategoryModel>? items,
    String? errorMessage,
  }) {
    return CategoryState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  bool get isLoading => status == CategoryStatus.loading;
}
