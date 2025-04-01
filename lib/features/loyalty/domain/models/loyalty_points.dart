import 'package:equatable/equatable.dart';
import 'package:loyalty_app/core/constants/app_config.dart';

class LoyaltyPoints extends Equatable {
  final int currentPoints;
  final int lifetimePoints;
  final int pendingPoints;
  final int redeemedPoints;
  final DateTime lastUpdated;

  const LoyaltyPoints({
    required this.currentPoints,
    required this.lifetimePoints,
    this.pendingPoints = 0,
    this.redeemedPoints = 0,
    required this.lastUpdated,
  });

  /// Creates a default instance with zero points
  factory LoyaltyPoints.initial() {
    return LoyaltyPoints(
      currentPoints: 0,
      lifetimePoints: 0,
      lastUpdated: DateTime.now(),
    );
  }

  /// Creates a sample instance with mock data for development
  factory LoyaltyPoints.mock() {
    return LoyaltyPoints(
      currentPoints: 5250,
      lifetimePoints: 8500,
      pendingPoints: 120,
      redeemedPoints: 3250,
      lastUpdated: DateTime.now().subtract(const Duration(days: 3)),
    );
  }

  /// Calculates the peso value of the current points
  double get pointsValue {
    return currentPoints * AppConfig.pesosPerPoint;
  }

  /// Returns the formatted peso value of the points
  String get pointsValueFormatted {
    return '${AppConfig.currencySymbol}${pointsValue.toStringAsFixed(2)}';
  }

  /// Calculate how many points would be earned for a given purchase amount
  static int calculatePointsForPurchase(double purchaseAmount) {
    return (purchaseAmount * AppConfig.pointsPerPeso).round();
  }
  
  /// Calculate the peso value of a given number of points
  static double calculateValueOfPoints(int points) {
    return points * AppConfig.pesosPerPoint;
  }

  /// Creates a new instance with updated points after a purchase
  LoyaltyPoints addPoints(int pointsToAdd) {
    return LoyaltyPoints(
      currentPoints: currentPoints + pointsToAdd,
      lifetimePoints: lifetimePoints + pointsToAdd,
      pendingPoints: pendingPoints,
      redeemedPoints: redeemedPoints,
      lastUpdated: DateTime.now(),
    );
  }

  /// Creates a new instance with updated points after a points redemption
  LoyaltyPoints redeemPoints(int pointsToRedeem) {
    if (pointsToRedeem > currentPoints) {
      throw Exception('Insufficient points for redemption');
    }

    return LoyaltyPoints(
      currentPoints: currentPoints - pointsToRedeem,
      lifetimePoints: lifetimePoints,
      pendingPoints: pendingPoints,
      redeemedPoints: redeemedPoints + pointsToRedeem,
      lastUpdated: DateTime.now(),
    );
  }

  /// Creates a new instance with pending points confirmed
  LoyaltyPoints confirmPendingPoints() {
    return LoyaltyPoints(
      currentPoints: currentPoints + pendingPoints,
      lifetimePoints: lifetimePoints + pendingPoints,
      pendingPoints: 0,
      redeemedPoints: redeemedPoints,
      lastUpdated: DateTime.now(),
    );
  }

  /// Creates a new instance with added pending points
  LoyaltyPoints addPendingPoints(int pointsToAdd) {
    return LoyaltyPoints(
      currentPoints: currentPoints,
      lifetimePoints: lifetimePoints,
      pendingPoints: pendingPoints + pointsToAdd,
      redeemedPoints: redeemedPoints,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  List<Object> get props => [
        currentPoints,
        lifetimePoints,
        pendingPoints,
        redeemedPoints,
        lastUpdated,
      ];
} 