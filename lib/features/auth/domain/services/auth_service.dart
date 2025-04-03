import 'package:loyalty_app/features/auth/api/auth_api.dart';
import 'package:loyalty_app/features/auth/data/models/auth_user.dart';

/// Service interface for authentication operations
abstract class AuthService {
  /// Check if user is authenticated
  bool get isAuthenticated;

  /// Get current authenticated user
  AuthUser? get currentUser;

  /// Get current authentication token
  String? get token;

  /// Initialize authentication from storage
  Future<bool> init();

  /// Login with username and password
  Future<AuthResult> login(String username, String password);

  /// Register a new user
  Future<AuthResult> register(String email, String username, String password);

  /// Log out the current user
  Future<bool> logout();

  /// Request password reset
  Future<bool> requestPasswordReset(String email);

  /// Reset password with token
  Future<bool> resetPassword(String resetToken, String newPassword);
}
