class AppConfig {
  // API Configuration
  static const String apiUrl =
      "https://your-woocommerce-site.com/wp-json/loyalty/v1/";

  // Points Configuration
  static const double pointsPerPeso = 10.0;
  static const double pesosPerPoint = 0.1;

  // Currency Configuration
  static const String currencySymbol = '₱';
  static const String currencyCode = 'PHP';

  // Feature Flags
  static const bool enableSocialLogin = true;
  static const bool enablePushNotifications = true;
  static const bool enableReferralProgram = false;

  // App Information
  static const String appName = 'Dinarys Loyalty';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Loyalty Levels Threshold
  static const Map<String, int> loyaltyLevelsThreshold = {
    'Silver': 0,
    'Gold': 5000,
    'Platinum': 10000,
    'Ruby': 20000,
  };
}
