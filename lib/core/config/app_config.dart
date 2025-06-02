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
      "https://skyrocketstudios.asia/loyalty-app/wp-json/wc/v3";
  static const String woocommerceConsumerKey =
      "ck_db7dec5ac19b37b0586aabf5ac332d128822ba31";
  static const String woocommerceConsumerSecret =
      "cs_6ef9c24051894f4c14fb220771e9e228ef4e3566";

  /// WordPress API Configuration
  static const String wordpressBaseUrl =
      "https://skyrocketstudios.asia/loyalty-app/wp-json";

  /// WordPress Admin Credentials
  /// TODO: Replace these with actual admin credentials when available
  static const String adminUsername =
      "admin_csn1wz2s"; // Admin user that can create users
  static const String adminPassword =
      "~oM1pZQFXzH3Ha9?"; // Regular admin password for authentication

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
