import 'package:equatable/equatable.dart';

/// Type of points transaction
enum TransactionType {
  purchase, // Points earned from a purchase
  redemption, // Points spent on a reward
  bonus, // Bonus points (promotions, referrals)
  adjustment, // Manual adjustment (e.g., customer service)
  expiration, // Points expired
}

/// Status of a transaction
enum TransactionStatus {
  pending, // Transaction is being processed
  completed, // Transaction has been processed
  cancelled, // Transaction was cancelled
  failed, // Transaction failed
}

/// Represents a single transaction in the loyalty system
class PointsTransaction extends Equatable {
  /// Unique transaction ID
  final String id;

  /// Type of transaction (purchase, redemption, etc.)
  final TransactionType type;

  /// Points amount (positive for earning, negative for spending)
  final int points;

  /// Description of transaction
  final String description;

  /// When the transaction happened
  final DateTime createdAt;

  /// Status of the transaction
  final TransactionStatus status;

  /// Additional data related to the transaction
  final Map<String, String> metadata;

  const PointsTransaction({
    required this.id,
    required this.type,
    required this.points,
    required this.description,
    required this.createdAt,
    this.status = TransactionStatus.completed,
    this.metadata = const {},
  });

  /// Whether this transaction represents earning points
  bool get isEarning => points > 0;

  /// Whether this transaction represents spending points
  bool get isSpending => points < 0;

  /// Formatted points value with sign
  String get pointsFormatted {
    if (points > 0) {
      return '+$points';
    }
    return '$points';
  }

  /// Get color based on transaction type
  String get statusText {
    switch (status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
      case TransactionStatus.failed:
        return 'Failed';
    }
  }

  /// Create a copy of this transaction with optional changes
  PointsTransaction copyWith({
    String? id,
    TransactionType? type,
    int? points,
    String? description,
    DateTime? createdAt,
    TransactionStatus? status,
    Map<String, String>? metadata,
  }) {
    return PointsTransaction(
      id: id ?? this.id,
      type: type ?? this.type,
      points: points ?? this.points,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Create mock transactions for testing and demo
  static List<PointsTransaction> getMockTransactions() {
    // Return an empty list instead of mock data
    return [];
  }

  @override
  List<Object?> get props => [
    id,
    type,
    points,
    description,
    createdAt,
    status,
    metadata,
  ];
}
