import 'package:loyalty_app/features/loyalty/domain/models/loyalty_points.dart';
import 'package:loyalty_app/features/loyalty/domain/models/points_transaction.dart';

/// Abstract service interface for loyalty functionality
abstract class LoyaltyService {
  /// Get user's current loyalty points
  Future<LoyaltyPoints> getLoyaltyPoints();

  /// Get user's points transactions
  Future<List<PointsTransaction>> getPointsTransactions();

  /// Get points that are about to expire
  Future<int> getExpiringPoints();

  /// Add points from a purchase
  Future<void> addPointsFromPurchase({
    required String orderId,
    required String description,
    required double amount,
  });

  /// Redeem points for rewards
  Future<void> redeemPoints({
    required int pointsToRedeem,
    required String description,
  });

  /// Add bonus points
  Future<void> addBonusPoints({
    required int bonusPoints,
    required String description,
  });

  /// Calculate the monetary value of points
  double calculatePointsValue(int points);

  /// Cleanup resources
  void dispose();
}
