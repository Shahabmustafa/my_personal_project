import '../../data/model/type_model.dart';

enum TypeStatus { initial, loading, success, error }

class TypeState {
  final TypeStatus status;
  final List<TypeModel> items;
  final String? errorMessage;

  const TypeState({
    this.status = TypeStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  TypeState copyWith({
    TypeStatus? status,
    List<TypeModel>? items,
    String? errorMessage,
  }) {
    return TypeState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  bool get isLoading => status == TypeStatus.loading;
}
