import 'dart:async';

import 'package:loyalty_app/features/loyalty/domain/models/loyalty_points.dart';
import 'package:loyalty_app/features/loyalty/domain/models/points_transaction.dart';
import 'package:loyalty_app/features/loyalty/domain/services/loyalty_service.dart';
import 'package:loyalty_app/features/loyalty/data/services/loyalty_service_impl.dart'
    as impl;

/// Repository for managing loyalty points data
class LoyaltyRepository {
  final LoyaltyService _loyaltyService;

  // Stream controllers for points and transactions
  final _pointsStreamController = StreamController<LoyaltyPoints>.broadcast();
  final _transactionsStreamController =
      StreamController<List<PointsTransaction>>.broadcast();

  // Streams for observing points and transactions
  Stream<LoyaltyPoints> get pointsStream => _pointsStreamController.stream;
  Stream<List<PointsTransaction>> get transactionsStream =>
      _transactionsStreamController.stream;

  // Constructor with dependency injection
  LoyaltyRepository({LoyaltyService? loyaltyService})
    : _loyaltyService = loyaltyService ?? impl.LoyaltyServiceImpl() {
    // Initialize data
    _loadInitialData();
  }

  // Load initial data for the repository
  Future<void> _loadInitialData() async {
    final points = await _loyaltyService.getLoyaltyPoints();
    final transactions = await _loyaltyService.getPointsTransactions();

    _pointsStreamController.add(points);
    _transactionsStreamController.add(transactions);
  }

  /// Get current loyalty points
  Future<LoyaltyPoints> getLoyaltyPoints() async {
    final points = await _loyaltyService.getLoyaltyPoints();
    return points;
  }

  /// Get list of point transactions
  Future<List<PointsTransaction>> getPointsTransactions() async {
    final transactions = await _loyaltyService.getPointsTransactions();
    return transactions;
  }

  /// Add points from a purchase
  Future<void> addPointsFromPurchase({
    required String orderId,
    required String description,
    required double amount,
  }) async {
    await _loyaltyService.addPointsFromPurchase(
      orderId: orderId,
      description: description,
      amount: amount,
    );

    // Refresh data after update
    _refreshData();
  }

  /// Redeem points
  Future<void> redeemPoints({
    required int pointsToRedeem,
    required String description,
  }) async {
    await _loyaltyService.redeemPoints(
      pointsToRedeem: pointsToRedeem,
      description: description,
    );

    // Refresh data after update
    _refreshData();
  }

  /// Add bonus points
  Future<void> addBonusPoints({
    required int bonusPoints,
    required String description,
  }) async {
    await _loyaltyService.addBonusPoints(
      bonusPoints: bonusPoints,
      description: description,
    );

    // Refresh data after update
    _refreshData();
  }

  /// Get expiring points
  Future<int> getExpiringPoints() async {
    return await _loyaltyService.getExpiringPoints();
  }

  /// Calculate value of points
  double calculatePointsValue(int points) {
    return _loyaltyService.calculatePointsValue(points);
  }

  /// Helper to refresh data from the service
  Future<void> _refreshData() async {
    final points = await _loyaltyService.getLoyaltyPoints();
    final transactions = await _loyaltyService.getPointsTransactions();

    _pointsStreamController.add(points);
    _transactionsStreamController.add(transactions);
  }

  void dispose() {
    _pointsStreamController.close();
    _transactionsStreamController.close();
    _loyaltyService.dispose();
  }
}
