part of 'loyalty_bloc.dart';

enum LoyaltyStatus { initial, loading, loaded, error }

enum RedemptionStatus { initial, loading, success, error }

class LoyaltyState extends Equatable {
  final LoyaltyStatus status;
  final RedemptionStatus redemptionStatus;
  final LoyaltyPoints? loyaltyPoints;
  final List<PointsTransaction> transactions;
  final PointsTransaction? lastRedeemedTransaction;
  final String? errorMessage;
  final BuildContext? context;

  const LoyaltyState({
    required this.status,
    required this.redemptionStatus,
    this.loyaltyPoints,
    required this.transactions,
    this.lastRedeemedTransaction,
    this.errorMessage,
    this.context,
  });

  factory LoyaltyState.initial() {
    return const LoyaltyState(
      status: LoyaltyStatus.initial,
      redemptionStatus: RedemptionStatus.initial,
      transactions: [],
    );
  }

  LoyaltyState copyWith({
    LoyaltyStatus? status,
    RedemptionStatus? redemptionStatus,
    LoyaltyPoints? loyaltyPoints,
    List<PointsTransaction>? transactions,
    PointsTransaction? lastRedeemedTransaction,
    String? errorMessage,
    BuildContext? context,
  }) {
    return LoyaltyState(
      status: status ?? this.status,
      redemptionStatus: redemptionStatus ?? this.redemptionStatus,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      transactions: transactions ?? this.transactions,
      lastRedeemedTransaction:
          lastRedeemedTransaction ?? this.lastRedeemedTransaction,
      errorMessage: errorMessage ?? this.errorMessage,
      context: context ?? this.context,
    );
  }

  @override
  List<Object?> get props => [
    status,
    redemptionStatus,
    loyaltyPoints,
    transactions,
    lastRedeemedTransaction,
    errorMessage,
  ];
}
