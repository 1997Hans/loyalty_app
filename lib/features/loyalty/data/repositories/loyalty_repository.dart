import 'dart:async';

import 'package:loyalty_app/features/loyalty/domain/models/loyalty_points.dart';
import 'package:loyalty_app/features/loyalty/domain/models/points_transaction.dart';
import 'package:loyalty_app/features/loyalty/domain/services/loyalty_service.dart';

/// Repository for managing loyalty points data
class LoyaltyRepository {
  final LoyaltyService _loyaltyService = LoyaltyService();
  
  // This would connect to a real backend in a production app
  // For demo purposes, we're using in-memory storage
  LoyaltyPoints _points = LoyaltyPoints.mock();
  final List<PointsTransaction> _transactions = PointsTransaction.getMockTransactions();
  
  // Stream controllers for points and transactions
  final _pointsStreamController = StreamController<LoyaltyPoints>.broadcast();
  final _transactionsStreamController = StreamController<List<PointsTransaction>>.broadcast();
  
  // Streams for observing points and transactions
  Stream<LoyaltyPoints> get pointsStream => _pointsStreamController.stream;
  Stream<List<PointsTransaction>> get transactionsStream => _transactionsStreamController.stream;
  
  LoyaltyRepository() {
    // Initialize with mock data
    _pointsStreamController.add(_points);
    _transactionsStreamController.add(_transactions);
  }
  
  /// Get current loyalty points
  Future<LoyaltyPoints> getLoyaltyPoints() async {
    // In a real app, this would fetch from an API
    return _points;
  }
  
  /// Get list of point transactions
  Future<List<PointsTransaction>> getPointsTransactions() async {
    // In a real app, this would fetch from an API
    return _transactions;
  }
  
  /// Add points from a purchase
  Future<void> addPointsFromPurchase({
    required String orderId,
    required String description,
    required double amount,
  }) async {
    // Create transaction
    final transaction = _loyaltyService.processPurchase(
      orderId: orderId, 
      description: description, 
      amount: amount
    );
    
    // Update points
    _points = _points.addPoints(transaction.points);
    
    // Add transaction to history
    _transactions.insert(0, transaction);
    
    // Notify listeners
    _pointsStreamController.add(_points);
    _transactionsStreamController.add(_transactions);
  }
  
  /// Redeem points
  Future<void> redeemPoints({
    required int pointsToRedeem,
    required String description,
  }) async {
    // Check if user has enough points
    if (!_loyaltyService.canRedeemPoints(_points, pointsToRedeem)) {
      throw Exception('Insufficient points for redemption');
    }
    
    // Create transaction
    final transaction = _loyaltyService.processRedemption(
      pointsToRedeem: pointsToRedeem,
      description: description,
    );
    
    // Update points
    _points = _points.redeemPoints(pointsToRedeem);
    
    // Add transaction to history
    _transactions.insert(0, transaction);
    
    // Notify listeners
    _pointsStreamController.add(_points);
    _transactionsStreamController.add(_transactions);
  }
  
  /// Add bonus points
  Future<void> addBonusPoints({
    required int bonusPoints,
    required String description,
  }) async {
    // Create transaction
    final transaction = _loyaltyService.addBonusPoints(
      bonusPoints: bonusPoints,
      description: description,
    );
    
    // Update points
    _points = _points.addPoints(bonusPoints);
    
    // Add transaction to history
    _transactions.insert(0, transaction);
    
    // Notify listeners
    _pointsStreamController.add(_points);
    _transactionsStreamController.add(_transactions);
  }
  
  /// Adjust points (admin operation)
  Future<void> adjustPoints({
    required int adjustment,
    required String description,
  }) async {
    // Create transaction
    final transaction = _loyaltyService.adjustPoints(
      adjustment: adjustment,
      description: description,
    );
    
    // Update points
    if (adjustment > 0) {
      _points = _points.addPoints(adjustment);
    } else {
      try {
        _points = _points.redeemPoints(adjustment.abs());
      } catch (e) {
        throw Exception('Cannot apply negative adjustment: Insufficient points');
      }
    }
    
    // Add transaction to history
    _transactions.insert(0, transaction);
    
    // Notify listeners
    _pointsStreamController.add(_points);
    _transactionsStreamController.add(_transactions);
  }
  
  /// Get expiring points
  Future<int> getExpiringPoints() async {
    final expiryDate = DateTime.now().add(const Duration(days: 30));
    return _loyaltyService.getExpiringPoints(_points, expiryDate);
  }
  
  /// Calculate value of points
  double calculatePointsValue(int points) {
    return _loyaltyService.calculateValueOfPoints(points);
  }
  
  /// Calculate points needed for a specific value
  int calculatePointsNeededForValue(double value) {
    return _loyaltyService.calculatePointsNeededForValue(value);
  }
  
  void dispose() {
    _pointsStreamController.close();
    _transactionsStreamController.close();
  }
} 