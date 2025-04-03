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

  /// WooCommerce API Configuration
  static const String woocommerceBaseUrl =
      "https://sandbox.skyrocket.sg/wp-json/wc/v3";
  static const String woocommerceConsumerKey =
      "ck_3bc2f9bdf9d14b9193e00fd63719a4d4b2a794b9";
  static const String woocommerceConsumerSecret =
      "cs_71d319df94716ae6b0071a997e71f9f9213ffc24";

  /// WooCommerce Loyalty Points Configuration
  static const double woocommercePointsPerAmount =
      1.0; // 1 point per unit of currency

  // Disable automatic sync on app startup to prevent initial connection errors
  // User can enable this from the UI when ready
  static const bool enableAutomaticPointsAward = false;

  /// Currency Configuration
  static const String currencySymbol = '₱';
  static const String currencyCode = 'PHP';
}
