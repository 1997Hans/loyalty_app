import 'dart:async';

import 'package:loyalty_app/core/config/app_config.dart';
import 'package:loyalty_app/features/loyalty/domain/models/loyalty_points.dart';
import 'package:loyalty_app/features/loyalty/domain/models/points_transaction.dart';
import 'package:loyalty_app/features/loyalty/domain/services/loyalty_service.dart';
import 'package:loyalty_app/features/loyalty/data/services/loyalty_service_impl.dart'
    as impl;

/// Repository for loyalty data storage and retrieval
class LoyaltyRepository {
  // In-memory storage for simulating database
  LoyaltyPoints _loyaltyPoints = LoyaltyPoints.mock();
  List<PointsTransaction> _transactions =
      PointsTransaction.getMockTransactions();

  // Streams for real-time updates
  final _pointsStreamController = StreamController<LoyaltyPoints>.broadcast();
  final _transactionsStreamController =
      StreamController<List<PointsTransaction>>.broadcast();

  // Getters for streams
  Stream<LoyaltyPoints> get pointsStream => _pointsStreamController.stream;
  Stream<List<PointsTransaction>> get transactionsStream =>
      _transactionsStreamController.stream;

  /// Get current loyalty points
  Future<LoyaltyPoints> getLoyaltyPoints() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _loyaltyPoints;
  }

  /// Get all transactions
  Future<List<PointsTransaction>> getTransactions() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _transactions;
  }

  /// Add a new transaction
  Future<void> addTransaction(PointsTransaction transaction) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    _transactions.insert(0, transaction);
  }

  /// Update points using a callback function
  Future<void> updatePoints(
    LoyaltyPoints Function(LoyaltyPoints) updateFn,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    _loyaltyPoints = updateFn(_loyaltyPoints);
  }

  /// In a real app, this would be a database or API call
  Future<void> clearTransactions() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _transactions.clear();
  }

  // Simulate network delay
  Future<void> _simulateNetworkDelay() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // Get transaction history
  Future<List<PointsTransaction>> getPointsTransactions() async {
    await _simulateNetworkDelay();
    return _transactions;
  }

  // Get expiring points in the next 30 days
  Future<int> getExpiringPoints() async {
    await _simulateNetworkDelay();
    // Simulation - 10% of current points are expiring soon
    return (_loyaltyPoints.currentPoints * 0.1).round();
  }

  // Add points from a purchase
  Future<PointsTransaction?> addPointsFromPurchase({
    required String orderId,
    required String description,
    required double amount,
  }) async {
    await _simulateNetworkDelay();

    // Calculate points based on purchase amount
    final pointsToAdd = (amount * AppConfig.pointsPerPHP).round();

    // Create a transaction record
    final transaction = PointsTransaction(
      id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
      type: TransactionType.purchase,
      points: pointsToAdd,
      description: description,
      createdAt: DateTime.now(),
      metadata: {'order_id': orderId, 'amount': amount.toString()},
    );

    // Add transaction to history
    _transactions.insert(0, transaction);

    // Update loyalty points
    _loyaltyPoints = _loyaltyPoints.addPoints(pointsToAdd);

    // Notify listeners
    _pointsStreamController.add(_loyaltyPoints);
    _transactionsStreamController.add(_transactions);

    return transaction;
  }

  // Add bonus points (promotions, referrals, etc.)
  Future<PointsTransaction?> addBonusPoints({
    required int bonusPoints,
    required String description,
  }) async {
    await _simulateNetworkDelay();

    // Create a transaction record
    final transaction = PointsTransaction(
      id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
      type: TransactionType.bonus,
      points: bonusPoints,
      description: description,
      createdAt: DateTime.now(),
    );

    // Add transaction to history
    _transactions.insert(0, transaction);

    // Update loyalty points
    _loyaltyPoints = _loyaltyPoints.addPoints(bonusPoints);

    // Notify listeners
    _pointsStreamController.add(_loyaltyPoints);
    _transactionsStreamController.add(_transactions);

    return transaction;
  }

  // Redeem points for a reward
  Future<PointsTransaction?> redeemPoints({
    required int pointsToRedeem,
    required String description,
  }) async {
    await _simulateNetworkDelay();

    // Check if user has enough points
    if (_loyaltyPoints.currentPoints < pointsToRedeem) {
      throw Exception('Insufficient points');
    }

    // Create a transaction record
    final transaction = PointsTransaction(
      id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
      type: TransactionType.redemption,
      points: -pointsToRedeem, // Negative value for points spent
      description: description,
      createdAt: DateTime.now(),
    );

    // Add transaction to history
    _transactions.insert(0, transaction);

    // Update loyalty points
    _loyaltyPoints = _loyaltyPoints.redeemPoints(pointsToRedeem);

    // Notify listeners
    _pointsStreamController.add(_loyaltyPoints);
    _transactionsStreamController.add(_transactions);

    return transaction;
  }

  // Calculate the value of points in currency
  double calculatePointsValue(int points) {
    return points * AppConfig.pointValueInPHP;
  }

  // Clean up resources
  void dispose() {
    _pointsStreamController.close();
    _transactionsStreamController.close();
  }
}
