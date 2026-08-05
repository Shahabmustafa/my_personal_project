import '../../data/model/branch_model.dart';

enum BranchStatus { initial, loading, success, error }

class BranchState {
  final BranchStatus status;
  final List<BranchModel> branches;
  final String? errorMessage;

  const BranchState({
    this.status = BranchStatus.initial,
    this.branches = const [],
    this.errorMessage,
  });

  BranchState copyWith({
    BranchStatus? status,
    List<BranchModel>? branches,
    String? errorMessage,
  }) {
    return BranchState(
      status: status ?? this.status,
      branches: branches ?? this.branches,
      errorMessage: errorMessage,
    );
  }

  bool get isLoading => status == BranchStatus.loading;
}
