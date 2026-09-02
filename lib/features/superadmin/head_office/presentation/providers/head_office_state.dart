import '../../data/model/head_office_model.dart';

enum HeadOfficeStatus { initial, loading, success, error }

class HeadOfficeState {
  final HeadOfficeStatus status;
  final List<HeadOfficeModel> headOffices;
  final String? errorMessage;

  const HeadOfficeState({
    this.status = HeadOfficeStatus.initial,
    this.headOffices = const [],
    this.errorMessage,
  });

  HeadOfficeState copyWith({
    HeadOfficeStatus? status,
    List<HeadOfficeModel>? headOffices,
    String? errorMessage,
  }) {
    return HeadOfficeState(
      status: status ?? this.status,
      headOffices: headOffices ?? this.headOffices,
      errorMessage: errorMessage,
    );
  }

  bool get isLoading => status == HeadOfficeStatus.loading;
}
