import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:loyalty_app/features/auth/api/auth_api.dart';
import 'package:loyalty_app/features/auth/data/models/auth_user.dart';

/// Repository for managing authentication state and persistence
class AuthRepository {
  final AuthApi _authApi;
  final FlutterSecureStorage _secureStorage;

  // Keys for secure storage
  static const String _usernameKey = 'auth_username';
  static const String _passwordKey = 'auth_password';
  static const String _userDataKey = 'auth_user_data';

  // Current auth state
  AuthUser? _currentUser;
  String? _authString;

  bool get isAuthenticated => _authString != null && _currentUser != null;
  AuthUser? get currentUser => _currentUser;
  String? get token => _authString; // Kept for API compatibility

  /// Create a new auth repository
  AuthRepository({
    required AuthApi authApi,
    FlutterSecureStorage? secureStorage,
  }) : _authApi = authApi,
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Initialize repository by loading saved authentication
  Future<bool> init() async {
    try {
      // Load username and password
      final username = await _secureStorage.read(key: _usernameKey);
      final password = await _secureStorage.read(key: _passwordKey);

      if (username == null || password == null) {
        return false;
      }

      // Create auth string
      final authString = base64Encode(utf8.encode('$username:$password'));

      // Validate credentials
      final isValid = await _authApi.validateToken(authString);
      if (!isValid) {
        await _clearAuthData();
        return false;
      }

      // Load user data
      final userData = await _secureStorage.read(key: _userDataKey);
      if (userData == null) {
        await _clearAuthData();
        return false;
      }

      // Set current auth state
      _authString = authString;
      _currentUser = AuthUser.fromJson(jsonDecode(userData));
      return true;
    } catch (e) {
      await _clearAuthData();
      return false;
    }
  }

  /// Login with username and password
  Future<AuthResult> login(String username, String password) async {
    final result = await _authApi.login(username, password);

    if (result.success && result.token != null && result.user != null) {
      // Save authentication state
      await _saveAuthData(username, password, result.user!);
    }

    return result;
  }

  /// Register a new user
  Future<AuthResult> register(
    String email,
    String username,
    String password,
  ) async {
    final result = await _authApi.register(email, username, password);

    if (result.success && result.user != null) {
      // Save authentication state
      await _saveAuthData(username, password, result.user!);
    }

    return result;
  }

  /// Log out the current user
  Future<bool> logout() async {
    try {
      await _authApi.logout();
      await _clearAuthData();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Request password reset
  Future<bool> requestPasswordReset(String email) {
    return _authApi.requestPasswordReset(email);
  }

  /// Perform password reset
  Future<bool> resetPassword(String resetToken, String newPassword) {
    return _authApi.resetPassword(resetToken, newPassword);
  }

  /// Save auth data to secure storage and memory
  Future<void> _saveAuthData(
    String username,
    String password,
    AuthUser user,
  ) async {
    // Create auth string
    final authString = base64Encode(utf8.encode('$username:$password'));

    // Save to memory
    _authString = authString;
    _currentUser = user;

    // Save to secure storage
    await _secureStorage.write(key: _usernameKey, value: username);
    await _secureStorage.write(key: _passwordKey, value: password);
    await _secureStorage.write(
      key: _userDataKey,
      value: jsonEncode(user.toJson()),
    );
  }

  /// Clear auth data from secure storage and memory
  Future<void> _clearAuthData() async {
    // Clear memory
    _authString = null;
    _currentUser = null;

    // Clear secure storage
    await _secureStorage.delete(key: _usernameKey);
    await _secureStorage.delete(key: _passwordKey);
    await _secureStorage.delete(key: _userDataKey);
  }
}
