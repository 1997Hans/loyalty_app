part of 'loyalty_bloc.dart';

abstract class LoyaltyEvent extends Equatable {
  const LoyaltyEvent();

  @override
  List<Object?> get props => [];
}

class SetContext extends LoyaltyEvent {
  final BuildContext context;

  const SetContext(this.context);

  @override
  List<Object?> get props => [context];
}

class LoyaltyPointsLoaded extends LoyaltyEvent {
  final LoyaltyPoints loyaltyPoints;

  const LoyaltyPointsLoaded(this.loyaltyPoints);

  @override
  List<Object?> get props => [loyaltyPoints];
}

class AddPointsFromPurchase extends LoyaltyEvent {
  final double amount;
  final String orderId;
  final String orderDetails;

  const AddPointsFromPurchase({
    required this.amount,
    required this.orderId,
    this.orderDetails = '',
  });

  @override
  List<Object?> get props => [amount, orderId, orderDetails];
}

class RedeemPoints extends LoyaltyEvent {
  final int points;
  final String rewardTitle;
  final double value;

  const RedeemPoints({
    required this.points,
    required this.rewardTitle,
    required this.value,
  });

  @override
  List<Object?> get props => [points, rewardTitle, value];
}

class LoadPointsTransactions extends LoyaltyEvent {
  const LoadPointsTransactions();
}

class ClearRedemptionStatus extends LoyaltyEvent {
  const ClearRedemptionStatus();
}

class CheckExpiringPoints extends LoyaltyEvent {
  const CheckExpiringPoints();
}
