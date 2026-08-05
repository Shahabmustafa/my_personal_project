import '../../data/model/color_model.dart';

enum ColorStatus { initial, loading, success, error }

class ColorState {
  final ColorStatus status;
  final List<ColorModel> items;
  final String? errorMessage;

  const ColorState({
    this.status = ColorStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  ColorState copyWith({
    ColorStatus? status,
    List<ColorModel>? items,
    String? errorMessage,
  }) {
    return ColorState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  bool get isLoading => status == ColorStatus.loading;
}
