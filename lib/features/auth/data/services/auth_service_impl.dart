import 'package:loyalty_app/features/auth/api/auth_api.dart';
import 'package:loyalty_app/features/auth/data/models/auth_user.dart';
import 'package:loyalty_app/features/auth/data/repositories/auth_repository.dart';
import 'package:loyalty_app/features/auth/domain/services/auth_service.dart';

/// Implementation of the AuthService interface
class AuthServiceImpl implements AuthService {
  final AuthRepository _repository;

  /// Creates a new AuthServiceImpl
  AuthServiceImpl({required AuthRepository repository})
    : _repository = repository;

  @override
  bool get isAuthenticated => _repository.isAuthenticated;

  @override
  AuthUser? get currentUser => _repository.currentUser;

  @override
  String? get token => _repository.token;

  @override
  Future<bool> init() => _repository.init();

  @override
  Future<AuthResult> login(String username, String password) {
    return _repository.login(username, password);
  }

  @override
  Future<AuthResult> register(String email, String username, String password) {
    return _repository.register(email, username, password);
  }

  @override
  Future<bool> logout() {
    return _repository.logout();
  }

  @override
  Future<bool> requestPasswordReset(String email) {
    return _repository.requestPasswordReset(email);
  }

  @override
  Future<bool> resetPassword(String resetToken, String newPassword) {
    return _repository.resetPassword(resetToken, newPassword);
  }
}
