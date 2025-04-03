import 'package:loyalty_app/core/constants/app_config.dart';
import 'package:loyalty_app/features/loyalty/domain/models/loyalty_points.dart';
import 'package:loyalty_app/features/loyalty/domain/models/points_transaction.dart';
import 'package:loyalty_app/features/loyalty/domain/services/loyalty_service.dart';

/// Implementation of the LoyaltyService for handling loyalty points operations
class LoyaltyServiceImpl implements LoyaltyService {
  // In-memory storage for demo purposes
  LoyaltyPoints _points = LoyaltyPoints.mock();
  final List<PointsTransaction> _transactions =
      PointsTransaction.getMockTransactions();

  @override
  Future<LoyaltyPoints> getLoyaltyPoints() async {
    // Simulate delay for network call
    await Future.delayed(const Duration(milliseconds: 300));
    return _points;
  }

  @override
  Future<List<PointsTransaction>> getPointsTransactions() async {
    // Simulate delay for network call
    await Future.delayed(const Duration(milliseconds: 300));
    return _transactions;
  }

  @override
  Future<int> getExpiringPoints() async {
    // Simulate logic to calculate expiring points
    // In a real app, this would query points with expiry dates
    await Future.delayed(const Duration(milliseconds: 200));
    return (_points.currentPoints * 0.1).round(); // 10% of points expiring soon
  }

  @override
  Future<void> addPointsFromPurchase({
    required String orderId,
    required String description,
    required double amount,
  }) async {
    // Calculate points to add (using the configured rate)
    final pointsToAdd = LoyaltyPoints.calculatePointsForPurchase(amount);

    // Create a transaction
    final transaction = PointsTransaction(
      id: 'ORDER-$orderId-${DateTime.now().millisecondsSinceEpoch}',
      userId: _points.userId,
      points: pointsToAdd,
      description: description,
      type: PointsTransactionType.purchase,
      date: DateTime.now(),
      purchaseAmount: amount,
      orderId: orderId,
    );

    // Add to transactions list
    _transactions.insert(0, transaction);

    // Update points
    _points = _points.addPoints(pointsToAdd);

    // Simulate backend delay
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> redeemPoints({
    required int pointsToRedeem,
    required String description,
  }) async {
    // Check if user has enough points
    if (_points.currentPoints < pointsToRedeem) {
      throw Exception('Not enough points to redeem');
    }

    // Create a transaction
    final transaction = PointsTransaction(
      id: 'REDEEM-${DateTime.now().millisecondsSinceEpoch}',
      userId: _points.userId,
      points: -pointsToRedeem, // Negative points for redemption
      description: description,
      type: PointsTransactionType.redemption,
      date: DateTime.now(),
    );

    // Add to transactions list
    _transactions.insert(0, transaction);

    // Update points
    _points = _points.redeemPoints(pointsToRedeem);

    // Simulate backend delay
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> addBonusPoints({
    required int bonusPoints,
    required String description,
  }) async {
    // Create a transaction
    final transaction = PointsTransaction(
      id: 'BONUS-${DateTime.now().millisecondsSinceEpoch}',
      userId: _points.userId,
      points: bonusPoints,
      description: description,
      type: PointsTransactionType.bonus,
      date: DateTime.now(),
    );

    // Add to transactions list
    _transactions.insert(0, transaction);

    // Update points
    _points = _points.addPoints(bonusPoints);

    // Simulate backend delay
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  double calculatePointsValue(int points) {
    return points * AppConfig.pesosPerPoint;
  }

  @override
  void dispose() {
    // No resources to clean up in this implementation
    // In a real app, this might close streams, database connections, etc.
  }
}
