import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:loyalty_app/features/loyalty/data/repositories/loyalty_repository.dart';
import 'package:loyalty_app/features/loyalty/domain/models/loyalty_points.dart';
import 'package:loyalty_app/features/loyalty/domain/models/points_transaction.dart';

// Events
abstract class LoyaltyEvent extends Equatable {
  const LoyaltyEvent();

  @override
  List<Object> get props => [];
}

class LoadLoyaltyData extends LoyaltyEvent {}

class AddPurchasePoints extends LoyaltyEvent {
  final String orderId;
  final String description;
  final double amount;

  const AddPurchasePoints({
    required this.orderId,
    required this.description,
    required this.amount,
  });

  @override
  List<Object> get props => [orderId, description, amount];
}

class RedeemLoyaltyPoints extends LoyaltyEvent {
  final int points;
  final String description;

  const RedeemLoyaltyPoints({required this.points, required this.description});

  @override
  List<Object> get props => [points, description];
}

class AddBonusPoints extends LoyaltyEvent {
  final int points;
  final String description;

  const AddBonusPoints({required this.points, required this.description});

  @override
  List<Object> get props => [points, description];
}

class RedeemPoints extends LoyaltyEvent {
  final String rewardTitle;
  final int pointsRequired;
  final String rewardDescription;

  const RedeemPoints({
    required this.rewardTitle,
    required this.pointsRequired,
    required this.rewardDescription,
  });

  @override
  List<Object> get props => [rewardTitle, pointsRequired, rewardDescription];
}

// States
abstract class LoyaltyState extends Equatable {
  const LoyaltyState();

  @override
  List<Object?> get props => [];
}

class LoyaltyInitial extends LoyaltyState {}

class LoyaltyLoading extends LoyaltyState {}

class LoyaltyLoaded extends LoyaltyState {
  final LoyaltyPoints points;
  final List<PointsTransaction> transactions;
  final int expiringPoints;
  final PointsRedemption? lastRedemption;

  const LoyaltyLoaded({
    required this.points,
    required this.transactions,
    this.expiringPoints = 0,
    this.lastRedemption,
  });

  @override
  List<Object?> get props => [
    points,
    transactions,
    expiringPoints,
    lastRedemption,
  ];
}

class LoyaltyError extends LoyaltyState {
  final String message;

  const LoyaltyError(this.message);

  @override
  List<Object?> get props => [message];
}

class PointsRedemptionSuccess extends LoyaltyState {
  final int pointsRedeemed;
  final double value;

  const PointsRedemptionSuccess({
    required this.pointsRedeemed,
    required this.value,
  });

  @override
  List<Object?> get props => [pointsRedeemed, value];
}

class PointsRedemption {
  final String title;
  final int pointsRedeemed;
  final String description;
  final DateTime timestamp;

  PointsRedemption({
    required this.title,
    required this.pointsRedeemed,
    required this.description,
    required this.timestamp,
  });
}

// BLoC
class LoyaltyBloc extends Bloc<LoyaltyEvent, LoyaltyState> {
  final LoyaltyRepository _repository;
  StreamSubscription? _pointsSubscription;
  StreamSubscription? _transactionsSubscription;

  LoyaltyBloc({LoyaltyRepository? repository})
    : _repository = repository ?? LoyaltyRepository(),
      super(LoyaltyInitial()) {
    on<LoadLoyaltyData>(_onLoadLoyaltyData);
    on<AddPurchasePoints>(_onAddPurchasePoints);
    on<RedeemLoyaltyPoints>(_onRedeemLoyaltyPoints);
    on<AddBonusPoints>(_onAddBonusPoints);
    on<RedeemPoints>(_onRedeemPoints);

    // Subscribe to streams
    _pointsSubscription = _repository.pointsStream.listen((_) {
      add(LoadLoyaltyData());
    });

    _transactionsSubscription = _repository.transactionsStream.listen((_) {
      add(LoadLoyaltyData());
    });
  }

  Future<void> _onLoadLoyaltyData(
    LoadLoyaltyData event,
    Emitter<LoyaltyState> emit,
  ) async {
    emit(LoyaltyLoading());
    try {
      final points = await _repository.getLoyaltyPoints();
      final transactions = await _repository.getPointsTransactions();
      final expiringPoints = await _repository.getExpiringPoints();

      emit(
        LoyaltyLoaded(
          points: points,
          transactions: transactions,
          expiringPoints: expiringPoints,
        ),
      );
    } catch (e) {
      emit(LoyaltyError(e.toString()));
    }
  }

  Future<void> _onAddPurchasePoints(
    AddPurchasePoints event,
    Emitter<LoyaltyState> emit,
  ) async {
    try {
      await _repository.addPointsFromPurchase(
        orderId: event.orderId,
        description: event.description,
        amount: event.amount,
      );
      // Loading state will be emitted by the stream subscription
    } catch (e) {
      emit(LoyaltyError(e.toString()));
    }
  }

  Future<void> _onRedeemLoyaltyPoints(
    RedeemLoyaltyPoints event,
    Emitter<LoyaltyState> emit,
  ) async {
    try {
      await _repository.redeemPoints(
        pointsToRedeem: event.points,
        description: event.description,
      );

      final value = _repository.calculatePointsValue(event.points);
      emit(PointsRedemptionSuccess(pointsRedeemed: event.points, value: value));
      // Then load updated loyalty data
      add(LoadLoyaltyData());
    } catch (e) {
      emit(LoyaltyError(e.toString()));
    }
  }

  Future<void> _onAddBonusPoints(
    AddBonusPoints event,
    Emitter<LoyaltyState> emit,
  ) async {
    try {
      await _repository.addBonusPoints(
        bonusPoints: event.points,
        description: event.description,
      );
      // Loading state will be emitted by the stream subscription
    } catch (e) {
      emit(LoyaltyError(e.toString()));
    }
  }

  Future<void> _onRedeemPoints(
    RedeemPoints event,
    Emitter<LoyaltyState> emit,
  ) async {
    if (state is LoyaltyLoaded) {
      final currentState = state as LoyaltyLoaded;
      final currentPoints = currentState.points;

      // Check if user has enough points
      if (currentPoints.currentPoints >= event.pointsRequired) {
        emit(LoyaltyLoading());

        try {
          // Process the redemption through the repository
          await _repository.redeemPoints(
            pointsToRedeem: event.pointsRequired,
            description:
                'Redeemed for ${event.rewardTitle}: ${event.rewardDescription}',
          );

          // Then load updated loyalty data
          add(LoadLoyaltyData());
        } catch (e) {
          emit(LoyaltyError('Failed to redeem points: ${e.toString()}'));
          emit(currentState); // Return to the previous state
        }
      } else {
        // Not enough points
        emit(LoyaltyError('Not enough points for this redemption'));
        emit(currentState); // Return to the previous state
      }
    }
  }

  @override
  Future<void> close() {
    _pointsSubscription?.cancel();
    _transactionsSubscription?.cancel();
    _repository.dispose();
    return super.close();
  }
}
