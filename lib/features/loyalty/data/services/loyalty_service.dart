class LoyaltyService {
  final LoyaltyRepository _repository;

  LoyaltyService({LoyaltyRepository? repository})
      : _repository = repository ?? LoyaltyRepository();

  /// Get user's loyalty points
  Future<LoyaltyPoints> getUserPoints() async {
    try {
      return await _repository.getLoyaltyPoints();
    } catch (e) {
      throw Exception('Failed to get loyalty points: ${e.toString()}');
    }
  }

  /// Get user's points transactions
  Future<List<PointsTransaction>> getPointsTransactions() async {
    try {
      return await _repository.getPointsTransactions();
    } catch (e) {
      throw Exception('Failed to get transactions: ${e.toString()}');
    }
  }

  /// Add points from a purchase
  Future<LoyaltyPoints> addPurchasePoints({
    required double purchaseAmount,
    String? description,
  }) async {
    try {
      final currentPoints = await _repository.getLoyaltyPoints();
      
      // Calculate points to add based on purchase amount and rate
      final pointsToAdd = (purchaseAmount * currentPoints.pointsPerCurrency).floor();
      
      // Create a transaction record
      final transaction = PointsTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TransactionType.purchase,
        points: pointsToAdd,
        timestamp: DateTime.now(),
        description: description ?? 'Points from purchase of ₱${purchaseAmount.toStringAsFixed(2)}',
        status: TransactionStatus.completed,
      );
      
      // Save the transaction
      await _repository.savePointsTransaction(transaction);
      
      // Update the points balance
      final updatedPoints = LoyaltyPoints(
        userId: currentPoints.userId,
        currentPoints: currentPoints.currentPoints + pointsToAdd,
        lifetimePoints: currentPoints.lifetimePoints + pointsToAdd,
        pendingPoints: currentPoints.pendingPoints,
        pointsPerCurrency: currentPoints.pointsPerCurrency,
        lastUpdated: DateTime.now(),
      );
      
      // Save the updated points
      await _repository.saveLoyaltyPoints(updatedPoints);
      
      return updatedPoints;
    } catch (e) {
      throw Exception('Failed to add purchase points: ${e.toString()}');
    }
  }

  /// Redeems loyalty points for a reward
  Future<LoyaltyPoints> redeemPoints({
    required int pointsToRedeem,
    required String rewardTitle,
    required String rewardDescription,
  }) async {
    try {
      // First check if user has enough points
      final currentPoints = await _repository.getLoyaltyPoints();
      if (currentPoints.currentPoints < pointsToRedeem) {
        throw Exception('Not enough points for this redemption');
      }

      // Create a redemption transaction
      final transaction = PointsTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TransactionType.redemption,
        points: -pointsToRedeem, // Negative since points are being used
        timestamp: DateTime.now(),
        description: 'Redeemed for $rewardTitle: $rewardDescription',
        status: TransactionStatus.completed,
      );

      // Save the transaction
      await _repository.savePointsTransaction(transaction);

      // Update the points balance
      final updatedPoints = LoyaltyPoints(
        userId: currentPoints.userId,
        currentPoints: currentPoints.currentPoints - pointsToRedeem,
        lifetimePoints: currentPoints.lifetimePoints,
        pendingPoints: currentPoints.pendingPoints,
        pointsPerCurrency: currentPoints.pointsPerCurrency,
        lastUpdated: DateTime.now(),
      );

      // Save the updated points
      await _repository.saveLoyaltyPoints(updatedPoints);

      // Return the updated points
      return updatedPoints;
    } catch (e) {
      throw Exception('Failed to redeem points: ${e.toString()}');
    }
  }

  /// Gets available rewards that can be redeemed with points
  Future<List<RewardOption>> getAvailableRewards() async {
    // This could fetch from an API or local data source in a real app
    return [
      RewardOption(
        id: 'discount_50',
        title: 'Discount Voucher',
        pointsRequired: 200,
        description: '₱50 off your next purchase',
        category: RewardCategory.discount,
      ),
      RewardOption(
        id: 'free_delivery',
        title: 'Free Delivery',
        pointsRequired: 350,
        description: 'Free delivery on your next order',
        category: RewardCategory.service,
      ),
      RewardOption(
        id: 'cashback_100',
        title: 'Cash Rebate',
        pointsRequired: 500,
        description: '₱100 cashback to your wallet',
        category: RewardCategory.cash,
      ),
      RewardOption(
        id: 'premium_status',
        title: 'Premium Status',
        pointsRequired: 1000,
        description: '30 days of VIP benefits',
        category: RewardCategory.status,
      ),
    ];
  }
}

/// Represents a reward option that can be redeemed with loyalty points
class RewardOption {
  final String id;
  final String title;
  final int pointsRequired;
  final String description;
  final RewardCategory category;
  final bool isAvailable;

  RewardOption({
    required this.id,
    required this.title,
    required this.pointsRequired,
    required this.description,
    required this.category,
    this.isAvailable = true,
  });
}

/// Categories of rewards
enum RewardCategory {
  discount,
  cash,
  service,
  product,
  status,
} 