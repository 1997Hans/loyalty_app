import 'package:loyalty_app/features/loyalty/domain/models/loyalty_points.dart';
import 'package:loyalty_app/features/loyalty/domain/models/points_transaction.dart';

/// Interface for loyalty service
abstract class LoyaltyService {
  /// Get the current loyalty points
  Future<LoyaltyPoints> getLoyaltyPoints();

  /// Get a stream of loyalty points updates
  Stream<LoyaltyPoints> getLoyaltyPointsStream();

  /// Add points from a purchase
  Future<PointsTransaction?> addPointsFromPurchase(
    double amount,
    String orderId,
    String orderDetails,
  );

  /// Redeem points for a reward
  Future<PointsTransaction?> redeemPoints(
    int points,
    String rewardTitle,
    double value,
  );

  /// Get all point transactions
  Future<List<PointsTransaction>> getTransactions();

  /// Get number of points that will expire soon
  Future<int> getExpiringPoints();

  /// Calculate the monetary value of points
  double calculatePointsValue(int points);

  /// Reset all data (used during logout)
  void resetData();

  /// Cleanup resources
  void dispose();
}
