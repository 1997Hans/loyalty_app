import 'package:loyalty_app/core/constants/app_config.dart';
import 'package:loyalty_app/features/loyalty/domain/models/loyalty_points.dart';
import 'package:loyalty_app/features/loyalty/domain/models/points_transaction.dart';

/// Service class for handling loyalty points operations
class LoyaltyService {
  /// Calculate points earned from a purchase amount
  int calculatePointsFromPurchase(double purchaseAmount) {
    return LoyaltyPoints.calculatePointsForPurchase(purchaseAmount);
  }

  /// Calculate the value of points in currency
  double calculateValueOfPoints(int points) {
    return LoyaltyPoints.calculateValueOfPoints(points);
  }

  /// Calculate the number of points needed for a specific redemption value
  int calculatePointsNeededForValue(double value) {
    return (value / AppConfig.pesosPerPoint).ceil();
  }

  /// Check if user has enough points for redemption
  bool canRedeemPoints(LoyaltyPoints points, int pointsToRedeem) {
    return points.currentPoints >= pointsToRedeem;
  }

  /// Process a purchase and calculate earned points
  PointsTransaction processPurchase({
    required String orderId,
    required String description,
    required double amount,
  }) {
    final int pointsEarned = calculatePointsFromPurchase(amount);
    
    return PointsTransaction(
      id: 'EARN-${DateTime.now().millisecondsSinceEpoch}',
      points: pointsEarned,
      description: description,
      type: PointsTransactionType.earned,
      date: DateTime.now(),
      referenceId: orderId,
      purchaseAmount: amount,
    );
  }

  /// Process points redemption
  PointsTransaction processRedemption({
    required int pointsToRedeem,
    required String description,
  }) {
    return PointsTransaction(
      id: 'REDM-${DateTime.now().millisecondsSinceEpoch}',
      points: pointsToRedeem,
      description: description,
      type: PointsTransactionType.redeemed,
      date: DateTime.now(),
      referenceId: 'RDM-${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// Add bonus points
  PointsTransaction addBonusPoints({
    required int bonusPoints,
    required String description,
  }) {
    return PointsTransaction(
      id: 'BONUS-${DateTime.now().millisecondsSinceEpoch}',
      points: bonusPoints,
      description: description,
      type: PointsTransactionType.bonus,
      date: DateTime.now(),
    );
  }

  /// Apply points adjustment (can be positive or negative)
  PointsTransaction adjustPoints({
    required int adjustment,
    required String description,
  }) {
    return PointsTransaction(
      id: 'ADJ-${DateTime.now().millisecondsSinceEpoch}',
      points: adjustment,
      description: description,
      type: PointsTransactionType.adjusted,
      date: DateTime.now(),
    );
  }

  /// Get expiring points within a time frame
  int getExpiringPoints(LoyaltyPoints points, DateTime expiryDate) {
    // In a real implementation, this would check points based on their acquisition date
    // For this demo, we'll just return a fixed percentage of the current points
    return (points.currentPoints * 0.1).round(); // 10% of points expiring soon
  }
} 