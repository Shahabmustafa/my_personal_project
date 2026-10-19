import '../../data/model/user_model.dart';

enum AuthStatus { initial, loading, success, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  /// App start par saved login check ho chuka (user mila ya nahi). Isse pehle
  /// splash dikhta hai — login screen ek pal ke liye bhi nahi chamakti.
  final bool initialized;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.initialized = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    bool? initialized,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      initialized: initialized ?? this.initialized,
    );
  }

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.success && user != null;
}
