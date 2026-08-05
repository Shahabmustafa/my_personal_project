import '../../data/model/brand_model.dart';

enum BrandStatus { initial, loading, success, error }

class BrandState {
  final BrandStatus status;
  final List<BrandModel> items;
  final String? errorMessage;

  const BrandState({
    this.status = BrandStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  BrandState copyWith({
    BrandStatus? status,
    List<BrandModel>? items,
    String? errorMessage,
  }) {
    return BrandState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  bool get isLoading => status == BrandStatus.loading;
}
