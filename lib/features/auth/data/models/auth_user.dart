/// Represents an authenticated user in the system
class AuthUser {
  /// WordPress/WooCommerce user ID
  final int id;

  /// User's email address
  final String email;

  /// Username for display and login
  final String username;

  /// User's display name
  final String displayName;

  /// URL to user avatar/profile image
  final String? avatarUrl;

  /// User roles (e.g. customer, administrator)
  final List<String> roles;

  /// First name of the user
  final String? firstName;

  /// Last name of the user
  final String? lastName;

  /// Whether the user has verified their email
  final bool isEmailVerified;

  /// Create a new authenticated user
  AuthUser({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    required this.roles,
    this.firstName,
    this.lastName,
    this.isEmailVerified = false,
  });

  /// Create an AuthUser from a JSON map
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    try {
      return AuthUser(
        id: json['id'] as int? ?? 0,
        email: json['email'] as String? ?? '',
        username: json['username'] as String? ?? '',
        displayName: json['display_name'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
        roles:
            json['roles'] != null
                ? (json['roles'] as List<dynamic>)
                    .map((e) => e as String? ?? '')
                    .toList()
                : <String>[],
        firstName: json['first_name'] as String?,
        lastName: json['last_name'] as String?,
        isEmailVerified: json['is_email_verified'] as bool? ?? false,
      );
    } catch (e) {
      print('Error in AuthUser.fromJson: $e');
      print('JSON: $json');
      rethrow;
    }
  }

  /// Convert AuthUser to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'roles': roles,
      'first_name': firstName,
      'last_name': lastName,
      'is_email_verified': isEmailVerified,
    };
  }
}
