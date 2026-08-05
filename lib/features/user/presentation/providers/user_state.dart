import '../../../auth/data/model/user_model.dart';

enum UserStatus { initial, loading, success, error }

class UserState {
  final UserStatus status;
  final List<UserModel> users;
  final String? errorMessage;

  const UserState({
    this.status = UserStatus.initial,
    this.users = const [],
    this.errorMessage,
  });

  UserState copyWith({UserStatus? status, List<UserModel>? users, String? errorMessage}) {
    return UserState(
      status: status ?? this.status,
      users: users ?? this.users,
      errorMessage: errorMessage,
    );
  }

  bool get isLoading => status == UserStatus.loading;
}
