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
  Future<PointsTransaction?> addPendingPointsFromPurchase(
    double amount,
    String orderId,
    String orderDetails,
  ) async {
    final points = LoyaltyPoints.calculatePointsForPurchase(amount);
    final description = 'Processing #$orderId: $orderDetails';

    final transaction = PointsTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TransactionType.purchase,
      points: points,
      description: description,
      createdAt: DateTime.now(),
      status: TransactionStatus.pending,
      metadata: {
        'order_id': orderId,
        'amount': amount.toString(),
        'is_pending': 'true',
      },
    );

    await _repository.addTransaction(transaction);
    await _repository.updatePoints((currentPoints) {
      return currentPoints.addPendingPoints(points);
    });

    // Update the stream
    final updatedPoints = await getLoyaltyPoints();
    _pointsStreamController.add(updatedPoints);

    return transaction;
  }

  @override
  Future<PointsTransaction?> convertPendingToCompleted(
    String orderId,
    String orderDetails,
  ) async {
    // Find pending transaction for this order
    final transactions = await _repository.getTransactions();
    final pendingTransaction = transactions.firstWhere(
      (tx) =>
          tx.metadata['order_id'] == orderId &&
          tx.status == TransactionStatus.pending,
      orElse:
          () =>
              throw Exception(
                'No pending transaction found for order $orderId',
              ),
    );

    // Create a new completed transaction
    final completedTransaction = PointsTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TransactionType.purchase,
      points: pendingTransaction.points,
      description: 'Completed: $orderDetails',
      createdAt: DateTime.now(),
      status: TransactionStatus.completed,
      metadata: {
        'order_id': orderId,
        'converted_from_pending': 'true',
        'original_transaction_id': pendingTransaction.id,
        ...pendingTransaction.metadata,
      },
    );

    // Add the completed transaction
    await _repository.addTransaction(completedTransaction);

    // Update points: convert pending to regular points
    await _repository.updatePoints((currentPoints) {
      return currentPoints.confirmPendingPoints(pendingTransaction.points);
    });

    // Remove or mark the old pending transaction as converted
    // Note: In a real implementation, you might want to keep the history
    // For now, we'll leave the pending transaction but it won't affect totals
    // since confirmPendingPoints handles the point transfer properly

    // Update the stream
    final updatedPoints = await getLoyaltyPoints();
    _pointsStreamController.add(updatedPoints);

    print(
      '✅ Converted ${pendingTransaction.points} pending points to completed for order $orderId',
    );
    return completedTransaction;
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
