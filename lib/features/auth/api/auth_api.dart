import 'package:loyalty_app/features/auth/data/models/auth_user.dart';

/// Interface for authentication API operations
abstract class AuthApi {
  /// Authenticate a user with WordPress/WooCommerce
  Future<AuthResult> login(String username, String password);

  /// Register a new user in WordPress/WooCommerce
  Future<AuthResult> register(String email, String username, String password);

  /// Validate current authentication token
  Future<bool> validateToken(String token);

  /// Request password reset for a user
  Future<bool> requestPasswordReset(String email);

  /// Reset password with a token
  Future<bool> resetPassword(String resetToken, String newPassword);

  /// Logout current user
  Future<bool> logout();
}

/// Result of authentication operations
class AuthResult {
  final bool success;
  final String? token;
  final AuthUser? user;
  final String? error;

  AuthResult({required this.success, this.token, this.user, this.error});
}
