import 'dart:async';

import 'package:loyalty_app/core/config/app_config.dart';
import 'package:loyalty_app/features/loyalty/data/repositories/loyalty_repository.dart';
import 'package:loyalty_app/features/loyalty/domain/models/loyalty_points.dart';
import 'package:loyalty_app/features/loyalty/domain/models/points_transaction.dart';
import 'package:loyalty_app/features/loyalty/domain/services/loyalty_service.dart';

/// Implementation of LoyaltyService
class LoyaltyServiceImpl implements LoyaltyService {
  final LoyaltyRepository _repository;
  final StreamController<LoyaltyPoints> _pointsStreamController =
      StreamController<LoyaltyPoints>.broadcast();

  LoyaltyServiceImpl({required LoyaltyRepository repository})
    : _repository = repository {
    // Initialize the stream with current points data
    _initializeStream();
  }

  Future<void> _initializeStream() async {
    try {
      final points = await getLoyaltyPoints();
      _pointsStreamController.add(points);
    } catch (e) {
      print('Error initializing points stream: $e');
    }
  }

  @override
  Future<LoyaltyPoints> getLoyaltyPoints() async {
    return await _repository.getLoyaltyPoints();
  }

  @override
  Stream<LoyaltyPoints> getLoyaltyPointsStream() {
    return _pointsStreamController.stream;
  }

  @override
  Future<PointsTransaction?> addPointsFromPurchase(
    double amount,
    String orderId,
    String orderDetails,
  ) async {
    final points = LoyaltyPoints.calculatePointsForPurchase(amount);
    final description = 'Purchase #$orderId: $orderDetails';

    final transaction = PointsTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TransactionType.purchase,
      points: points,
      description: description,
      createdAt: DateTime.now(),
      status: TransactionStatus.completed,
      metadata: {'order_id': orderId, 'amount': amount.toString()},
    );

    await _repository.addTransaction(transaction);
    await _repository.updatePoints((currentPoints) {
      return currentPoints.addPoints(points);
    });

    // Update the stream
    final updatedPoints = await getLoyaltyPoints();
    _pointsStreamController.add(updatedPoints);

    return transaction;
  }

  @override
  Future<PointsTransaction?> redeemPoints(
    int points,
    String rewardTitle,
    double value,
  ) async {
    final currentPoints = await getLoyaltyPoints();

    if (currentPoints.currentPoints < points) {
      return null; // Not enough points
    }

    final transaction = PointsTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TransactionType.redemption,
      points: -points,
      description: 'Redeemed for $rewardTitle',
      createdAt: DateTime.now(),
      status: TransactionStatus.completed,
      metadata: {'reward_title': rewardTitle, 'value': value.toString()},
    );

    await _repository.addTransaction(transaction);
    await _repository.updatePoints((currentPoints) {
      return currentPoints.redeemPoints(points);
    });

    // Update the stream
    final updatedPoints = await getLoyaltyPoints();
    _pointsStreamController.add(updatedPoints);

    return transaction;
  }

  @override
  Future<List<PointsTransaction>> getTransactions() async {
    return await _repository.getTransactions();
  }

  @override
  Future<int> getExpiringPoints() async {
    // Simulate points that will expire in 30 days - in a real app, this would
    // check transaction dates and expiration rules
    final transactions = await getTransactions();

    // For demo purposes, we'll use 10% of the points from purchases in the last 3 months
    final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));

    int expiringPoints = 0;
    for (var transaction in transactions) {
      if (transaction.type == TransactionType.purchase &&
          transaction.createdAt.isAfter(threeMonthsAgo) &&
          transaction.points > 0) {
        expiringPoints += (transaction.points * 0.1).round();
      }
    }

    return expiringPoints;
  }

  @override
  double calculatePointsValue(int points) {
    return points * AppConfig.pointValueInPHP;
  }

  /// Dispose resources
  @override
  void dispose() {
    _pointsStreamController.close();
  }

  /// Reset all data when a user logs out
  void resetData() async {
    try {
      // Clear cached data in the repository
      await _repository.resetData();

      // Reinitialize the stream with empty data
      final initialPoints = LoyaltyPoints.initial();
      _pointsStreamController.add(initialPoints);

      print('Loyalty service data reset completed');
    } catch (e) {
      print('Error resetting loyalty data: $e');
    }
  }
}
