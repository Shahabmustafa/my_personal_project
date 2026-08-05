import '../../data/model/size_model.dart';

enum SizeStatus { initial, loading, success, error }

class SizeState {
  final SizeStatus status;
  final List<SizeModel> items;
  final String? errorMessage;

  const SizeState({
    this.status = SizeStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  SizeState copyWith({
    SizeStatus? status,
    List<SizeModel>? items,
    String? errorMessage,
  }) {
    return SizeState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  bool get isLoading => status == SizeStatus.loading;
}
