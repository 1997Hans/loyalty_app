import 'dart:async';

import 'package:loyalty_app/core/config/app_config.dart';
import 'package:loyalty_app/core/di/dependency_injection.dart';
import 'package:loyalty_app/features/loyalty/api/woocommerce_sync_service.dart';
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
  @override
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

  @override
  Future<PointsTransaction?> addPendingTransaction(
    PointsTransaction transaction,
    LoyaltyPoints updatedPoints,
  ) async {
    try {
      // Create a transaction with pending status
      final pendingTransaction = transaction.copyWith(
        status: TransactionStatus.pending,
      );

      // Store the transaction
      final savedTransaction = await _repository.saveTransaction(
        pendingTransaction,
      );

      // Update the points in the stream
      _pointsStreamController.add(updatedPoints);

      return savedTransaction;
    } catch (e) {
      print('Error adding pending transaction: $e');
      return null;
    }
  }

  @override
  Future<void> confirmPendingTransaction(
    String transactionId,
    String orderId,
  ) async {
    try {
      print(
        'Confirming pending transaction: $transactionId for order $orderId',
      );

      // Find the transaction by ID
      final transactions = await _repository.getTransactions();
      print(
        'Found ${transactions.length} transactions, looking for the pending one...',
      );

      // Log all pending transactions
      final pendingTransactions =
          transactions
              .where((t) => t.status == TransactionStatus.pending)
              .toList();
      print('Found ${pendingTransactions.length} pending transactions');
      for (final t in pendingTransactions) {
        print(
          'Transaction: id=${t.id}, status=${t.status}, metadata=${t.metadata}',
        );
      }

      final pendingTransaction = transactions.firstWhere(
        (t) =>
            t.id == transactionId ||
            (t.status == TransactionStatus.pending &&
                t.metadata.containsKey('order_id') &&
                t.metadata['order_id'] == orderId),
        orElse: () {
          print(
            'No matching transaction found for id=$transactionId or orderId=$orderId',
          );
          return PointsTransaction(
            id: '',
            type: TransactionType.purchase,
            points: 0,
            description: '',
            createdAt: DateTime.now(),
          );
        },
      );

      if (pendingTransaction.id.isNotEmpty) {
        print('Found transaction to confirm: ${pendingTransaction.id}');

        // Get the points amount from the transaction
        final pendingPoints = pendingTransaction.points;

        // Update the transaction status to completed
        final updatedTransaction = pendingTransaction.copyWith(
          status: TransactionStatus.completed,
          description: pendingTransaction.description.replaceFirst(
            'Pending: ',
            '',
          ),
        );

        await _repository.updateTransaction(updatedTransaction);

        // Get current loyalty points
        final points = await _repository.getLoyaltyPoints();

        // Confirm the pending points in the loyalty points
        final updatedPoints = points.confirmPendingPoints(pendingPoints);

        // Update the repository
        await _repository.updatePoints((current) => updatedPoints);

        // Update the stream
        _pointsStreamController.add(updatedPoints);

        print(
          'Successfully confirmed transaction: current=${updatedPoints.currentPoints}, pending=${updatedPoints.pendingPoints}',
        );
      } else {
        print('No pending transaction found to confirm');
      }
    } catch (e, stackTrace) {
      print('Error confirming pending transaction: $e');
      print(stackTrace);
    }
  }

  @override
  Future<void> syncProcessingOrders() async {
    try {
      print('Starting processing orders sync to update pending points');

      // Get the WooCommerceSyncService through dependency injection
      final syncService = getIt<WooCommerceSyncService>();

      // Force clear processed orders for testing if needed
      // Uncomment this line to force a full resync (for debugging)
      syncService.clearProcessedOrders();

      // Trigger a sync of WooCommerce orders, which will handle processing orders
      await syncService.syncWooCommerceOrders();

      // Refresh loyalty points after sync to ensure UI is updated
      final points = await _repository.getLoyaltyPoints();
      _pointsStreamController.add(points);

      print('Processing orders sync completed successfully');
    } catch (e, stackTrace) {
      print('Error syncing processing orders: $e');
      print(stackTrace);

      // Even if the sync failed, refresh the points to show the current state
      try {
        final points = await _repository.getLoyaltyPoints();
        _pointsStreamController.add(points);
      } catch (_) {}
    }
  }
}
