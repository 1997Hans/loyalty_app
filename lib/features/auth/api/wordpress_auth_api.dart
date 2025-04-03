import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:loyalty_app/core/config/app_config.dart';
import 'package:loyalty_app/features/auth/api/auth_api.dart';
import 'package:loyalty_app/features/auth/data/models/auth_user.dart';

/// Implementation of AuthApi for WordPress using Basic Authentication
class WordPressAuthApi implements AuthApi {
  final Dio _dio;
  final String _baseUrl;
  final FlutterSecureStorage _secureStorage;

  // Keys for secure storage
  static const String _usernameKey = 'wp_username';
  static const String _passwordKey = 'wp_password';

  /// Create a new WordPress Auth API client
  WordPressAuthApi({Dio? dio, FlutterSecureStorage? secureStorage})
    : _dio = dio ?? Dio(),
      _baseUrl = AppConfig.wordpressBaseUrl,
      _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<AuthResult> login(String username, String password) async {
    try {
      print('Attempting login for user: $username');

      // Create basic auth header
      final authString = base64Encode(utf8.encode('$username:$password'));

      // Get user details with basic auth
      print('Sending request to $_baseUrl/wp/v2/users/me');
      final response = await _dio.get(
        '$_baseUrl/wp/v2/users/me',
        options: Options(
          headers: {'Authorization': 'Basic $authString'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      print('Response status code: ${response.statusCode}');

      // Check for authentication failure
      if (response.statusCode == 401) {
        String errorMessage = 'Authentication failed';
        if (response.data is Map && response.data['message'] != null) {
          errorMessage = response.data['message'];
        }
        print('Authentication failed: $errorMessage');
        return AuthResult(success: false, error: errorMessage);
      }

      if (response.statusCode == 200) {
        print('Authentication successful, processing user data');
        final userData = response.data;
        print('User data from API: $userData');

        // Add null checks and default values for all required fields
        final String email = userData['email'] ?? '';
        final String username = userData['username'] ?? userData['slug'] ?? '';
        final String displayName = userData['name'] ?? username;

        try {
          // Create AuthUser from WordPress response with null safety
          print(
            'Creating AuthUser object with id: ${userData['id']}, email: $email, username: $username, displayName: $displayName',
          );
          final user = AuthUser(
            id: userData['id'] ?? 0,
            email: email,
            username: username,
            displayName: displayName,
            avatarUrl: userData['avatar_urls']?['96'],
            roles: List<String>.from(userData['roles'] ?? []),
            firstName: userData['first_name'],
            lastName: userData['last_name'],
          );
          print('AuthUser object created successfully');

          // Save credentials securely for future API calls
          await _secureStorage.write(key: _usernameKey, value: username);
          await _secureStorage.write(key: _passwordKey, value: password);
          print('Credentials saved to secure storage');

          return AuthResult(success: true, token: authString, user: user);
        } catch (e) {
          print('Error creating AuthUser: $e');
          print('User data from API: $userData');
          return AuthResult(
            success: false,
            error: 'Error processing user data: $e',
          );
        }
      }

      print('Login failed with status code: ${response.statusCode}');
      return AuthResult(
        success: false,
        error:
            response.data?['message'] ?? 'Login failed: ${response.statusCode}',
      );
    } on DioException catch (e) {
      print('DioException during login: ${e.type}');
      if (e.response != null) {
        print(
          'DioException response: ${e.response?.statusCode} - ${e.response?.data}',
        );
      }

      String errorMessage = 'Network error';

      if (e.response?.statusCode == 401) {
        errorMessage = 'Invalid username or password';
      } else if (e.response?.data is Map &&
          e.response?.data['message'] != null) {
        errorMessage = e.response?.data['message'];
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout - please check your internet';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Cannot connect to server - please try again later';
      }

      print('Returning error: $errorMessage');
      return AuthResult(success: false, error: errorMessage);
    } catch (e) {
      print('Unexpected error during login: $e');
      return AuthResult(success: false, error: 'Unexpected error: $e');
    }
  }

  @override
  Future<AuthResult> register(
    String email,
    String username,
    String password,
  ) async {
    try {
      // Use admin credentials for creating users
      final adminUsername = AppConfig.adminUsername;
      final adminPassword = AppConfig.adminPassword;

      if (adminUsername.isEmpty || adminPassword.isEmpty) {
        return AuthResult(
          success: false,
          error: 'Admin credentials not configured for user registration',
        );
      }

      final adminAuthString = base64Encode(
        utf8.encode('$adminUsername:$adminPassword'),
      );

      // Create the new user
      final response = await _dio.post(
        '$_baseUrl/wp/v2/users',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'roles': ['customer'],
        },
        options: Options(
          headers: {'Authorization': 'Basic $adminAuthString'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      // Check for specific error responses
      if (response.statusCode != 201) {
        String errorMessage = 'Registration failed';
        if (response.data is Map && response.data['message'] != null) {
          errorMessage = response.data['message'];
        }
        return AuthResult(success: false, error: errorMessage);
      }

      // Log the successful registration response
      print('Registration successful. Response data: ${response.data}');

      // Now login with the new credentials
      return login(username, password);
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      if (e.response?.statusCode == 400) {
        // Parse WordPress validation errors
        if (e.response?.data is Map && e.response?.data['message'] != null) {
          errorMessage = e.response?.data['message'];

          // Improve common WordPress error messages
          if (errorMessage.contains('existing user login')) {
            errorMessage = 'Username already exists';
          } else if (errorMessage.contains('existing user email')) {
            errorMessage = 'Email already in use';
          } else if (errorMessage.contains('password')) {
            errorMessage = 'Password does not meet requirements';
          }
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout - please check your internet';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Cannot connect to server - please try again later';
      }

      return AuthResult(success: false, error: errorMessage);
    } catch (e) {
      return AuthResult(success: false, error: 'Unexpected error: $e');
    }
  }

  @override
  Future<bool> validateToken(String token) async {
    try {
      // For Basic Auth, we need the stored credentials
      final username = await _secureStorage.read(key: _usernameKey);
      final password = await _secureStorage.read(key: _passwordKey);

      if (username == null || password == null) {
        return false;
      }

      final authString = base64Encode(utf8.encode('$username:$password'));

      final response = await _dio.get(
        '$_baseUrl/wp/v2/users/me',
        options: Options(
          headers: {'Authorization': 'Basic $authString'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> requestPasswordReset(String email) async {
    try {
      // Use admin auth for password reset requests
      final adminUsername = AppConfig.adminUsername;
      final adminPassword = AppConfig.adminPassword;

      final adminAuthString = base64Encode(
        utf8.encode('$adminUsername:$adminPassword'),
      );

      final response = await _dio.post(
        '$_baseUrl/wp/v2/users/lostpassword',
        data: {'user_login': email},
        options: Options(headers: {'Authorization': 'Basic $adminAuthString'}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> resetPassword(String resetToken, String newPassword) async {
    try {
      // Use admin auth for password reset
      final adminUsername = AppConfig.adminUsername;
      final adminPassword = AppConfig.adminPassword;

      final adminAuthString = base64Encode(
        utf8.encode('$adminUsername:$adminPassword'),
      );

      final response = await _dio.post(
        '$_baseUrl/wp/v2/users/resetpassword',
        data: {'rp_key': resetToken, 'password': newPassword},
        options: Options(headers: {'Authorization': 'Basic $adminAuthString'}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> logout() async {
    try {
      // Clear stored credentials
      await _secureStorage.delete(key: _usernameKey);
      await _secureStorage.delete(key: _passwordKey);
      return true;
    } catch (e) {
      return false;
    }
  }
}
