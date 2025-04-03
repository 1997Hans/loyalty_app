/// Application-wide configuration settings
class AppConfig {
  /// Value of one loyalty point in PHP (Philippine Peso)
  static const double pointValueInPHP = 0.10;

  /// Points earned per PHP spent (e.g., 1 point per 20 PHP)
  static const double pointsPerPHP = 0.05;

  /// Minimum points required to redeem
  static const int minPointsToRedeem = 100;

  /// Default points expiration time in days
  static const int pointsExpirationDays = 365;

  /// Whether to show debug logs
  static const bool enableDebugLogs = true;
}
