import 'package:equatable/equatable.dart';
import 'package:loyalty_app/core/config/app_config.dart';

/// Represents a user's loyalty points balance
class LoyaltyPoints extends Equatable {
  /// Current available points balance
  final int currentPoints;

  /// Total lifetime points earned
  final int lifetimePoints;

  /// Points that have been redeemed
  final int redeemedPoints;

  /// Pending points (not yet confirmed)
  final int pendingPoints;

  /// Date of last update
  final DateTime lastUpdated;

  /// User ID associated with these points
  final String userId;

  LoyaltyPoints({
    required this.currentPoints,
    required this.lifetimePoints,
    required this.redeemedPoints,
    required this.pendingPoints,
    DateTime? lastUpdated,
    this.userId = 'user_123',
  }) : this.lastUpdated = lastUpdated ?? DateTime(2023, 1, 1);

  /// Factory constructor for creating initial empty points
  factory LoyaltyPoints.initial() {
    return LoyaltyPoints(
      currentPoints: 0,
      lifetimePoints: 0,
      redeemedPoints: 0,
      pendingPoints: 0,
    );
  }

  /// Create a mock points object for testing
  factory LoyaltyPoints.mock() {
    return LoyaltyPoints(
      currentPoints: 250,
      lifetimePoints: 300,
      redeemedPoints: 50,
      pendingPoints: 0,
    );
  }

  /// Calculate the value of the current points in PHP
  double get currentValuePHP => calculateValuePHP(currentPoints);

  /// Calculate the value of the lifetime points in PHP
  double get lifetimeValuePHP => calculateValuePHP(lifetimePoints);

  /// Calculate the value of the redeemed points in PHP
  double get redeemedValuePHP => calculateValuePHP(redeemedPoints);

  /// Get formatted value string
  String get pointsValueFormatted => '₱${currentValuePHP.toStringAsFixed(2)}';

  /// Calculate the value of points in PHP
  double calculateValuePHP(int points) {
    return points * AppConfig.pointValueInPHP;
  }

  /// Calculate points earned for a purchase
  static int calculatePointsForPurchase(double amount) {
    return (amount * AppConfig.pointsPerPHP).round();
  }

  /// Add points to the current balance
  LoyaltyPoints addPoints(int points) {
    return copyWith(
      currentPoints: currentPoints + points,
      lifetimePoints: lifetimePoints + points,
      lastUpdated: DateTime.now(),
    );
  }

  /// Add pending points that need confirmation
  LoyaltyPoints addPendingPoints(int points) {
    return copyWith(
      pendingPoints: pendingPoints + points,
      lastUpdated: DateTime.now(),
    );
  }

  /// Confirm pending points, moving them to current and lifetime
  LoyaltyPoints confirmPendingPoints(int points) {
    // Ensure we don't confirm more than what's pending
    final pointsToConfirm = points > pendingPoints ? pendingPoints : points;

    return copyWith(
      currentPoints: currentPoints + pointsToConfirm,
      lifetimePoints: lifetimePoints + pointsToConfirm,
      pendingPoints: pendingPoints - pointsToConfirm,
      lastUpdated: DateTime.now(),
    );
  }

  /// Redeem points from the current balance
  LoyaltyPoints redeemPoints(int points) {
    // Ensure we don't redeem more than available
    if (points > currentPoints) {
      throw Exception('Cannot redeem more points than available');
    }

    return copyWith(
      currentPoints: currentPoints - points,
      redeemedPoints: redeemedPoints + points,
      lastUpdated: DateTime.now(),
    );
  }

  /// Create a copy of this object with optional changes
  LoyaltyPoints copyWith({
    int? currentPoints,
    int? lifetimePoints,
    int? redeemedPoints,
    int? pendingPoints,
    DateTime? lastUpdated,
    String? userId,
  }) {
    return LoyaltyPoints(
      currentPoints: currentPoints ?? this.currentPoints,
      lifetimePoints: lifetimePoints ?? this.lifetimePoints,
      redeemedPoints: redeemedPoints ?? this.redeemedPoints,
      pendingPoints: pendingPoints ?? this.pendingPoints,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      userId: userId ?? this.userId,
    );
  }

  @override
  List<Object?> get props => [
    currentPoints,
    lifetimePoints,
    redeemedPoints,
    pendingPoints,
    lastUpdated,
    userId,
  ];
}
