import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:loyalty_app/core/services/notification_service.dart';
import 'package:loyalty_app/features/loyalty/domain/models/loyalty_points.dart';
import 'package:loyalty_app/features/loyalty/domain/models/points_transaction.dart';
import 'package:loyalty_app/features/loyalty/domain/services/loyalty_service.dart';

part 'loyalty_event.dart';
part 'loyalty_state.dart';

class LoyaltyBloc extends Bloc<LoyaltyEvent, LoyaltyState> {
  final LoyaltyService _loyaltyService;
  final NotificationService _notificationService;

  StreamSubscription? _loyaltyPointsSubscription;

  LoyaltyBloc({
    required LoyaltyService loyaltyService,
    NotificationService? notificationService,
  }) : _loyaltyService = loyaltyService,
       _notificationService = notificationService ?? NotificationService(),
       super(LoyaltyState.initial()) {
    on<LoyaltyPointsLoaded>(_onLoyaltyPointsLoaded);
    on<AddPointsFromPurchase>(_onAddPointsFromPurchase);
    on<RedeemPoints>(_onRedeemPoints);
    on<LoadPointsTransactions>(_onLoadPointsTransactions);
    on<ClearRedemptionStatus>(_onClearRedemptionStatus);
    on<CheckExpiringPoints>(_onCheckExpiringPoints);
    on<SetContext>(_onSetContext);
    on<ResetLoyaltyData>(_onResetLoyaltyData);

    // Subscribe to points updates
    _subscribeToPointsUpdates();

    // Initial loading of data
    add(const LoadPointsTransactions());
  }

  Future<void> _onSetContext(
    SetContext event,
    Emitter<LoyaltyState> emit,
  ) async {
    emit(state.copyWith(context: event.context));
  }

  Future<void> _onLoyaltyPointsLoaded(
    LoyaltyPointsLoaded event,
    Emitter<LoyaltyState> emit,
  ) async {
    emit(
      state.copyWith(
        loyaltyPoints: event.loyaltyPoints,
        status: LoyaltyStatus.loaded,
      ),
    );

    // Check for milestone notifications
    if (state.context != null) {
      _notificationService.showPointsMilestoneNotification(
        state.context!,
        event.loyaltyPoints,
      );
    }
  }

  Future<void> _onAddPointsFromPurchase(
    AddPointsFromPurchase event,
    Emitter<LoyaltyState> emit,
  ) async {
    emit(state.copyWith(status: LoyaltyStatus.loading));

    try {
      final transaction = await _loyaltyService.addPointsFromPurchase(
        event.amount,
        event.orderId,
        event.orderDetails,
      );

      // Show notification if context is available
      if (state.context != null && transaction != null) {
        _notificationService.showPointsUpdateNotification(
          state.context!,
          transaction,
        );
      }

      // Check for expiring points
      add(const CheckExpiringPoints());

      emit(state.copyWith(status: LoyaltyStatus.loaded));
    } catch (e) {
      emit(
        state.copyWith(
          status: LoyaltyStatus.error,
          errorMessage: 'Failed to add points: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onRedeemPoints(
    RedeemPoints event,
    Emitter<LoyaltyState> emit,
  ) async {
    emit(
      state.copyWith(
        status: LoyaltyStatus.loading,
        redemptionStatus: RedemptionStatus.loading,
      ),
    );

    try {
      final result = await _loyaltyService.redeemPoints(
        event.points,
        event.rewardTitle,
        event.value,
      );

      if (result != null) {
        emit(
          state.copyWith(
            status: LoyaltyStatus.loaded,
            redemptionStatus: RedemptionStatus.success,
            lastRedeemedTransaction: result,
          ),
        );

        // Show notification if context is available
        if (state.context != null) {
          _notificationService.showRedemptionConfirmationNotification(
            state.context!,
            event.rewardTitle,
            event.points,
            event.value,
          );
        }
      } else {
        emit(
          state.copyWith(
            status: LoyaltyStatus.error,
            redemptionStatus: RedemptionStatus.error,
            errorMessage: 'Failed to redeem points',
          ),
        );

        if (state.context != null) {
          _notificationService.showRedemptionFailureNotification(
            state.context!,
            'Failed to redeem points',
          );
        }
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: LoyaltyStatus.error,
          redemptionStatus: RedemptionStatus.error,
          errorMessage: 'Failed to redeem points: ${e.toString()}',
        ),
      );

      if (state.context != null) {
        _notificationService.showRedemptionFailureNotification(
          state.context!,
          'Failed to redeem points: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _onLoadPointsTransactions(
    LoadPointsTransactions event,
    Emitter<LoyaltyState> emit,
  ) async {
    // Always emit loading state to ensure UI shows loading indicator
    emit(state.copyWith(status: LoyaltyStatus.loading));

    try {
      // Load both points and transactions to ensure data consistency
      final points = await _loyaltyService.getLoyaltyPoints();
      final transactions = await _loyaltyService.getTransactions();

      // Only emit loaded state when both data sources have successfully loaded
      emit(
        state.copyWith(
          status: LoyaltyStatus.loaded,
          loyaltyPoints: points,
          transactions: transactions,
        ),
      );

      // Show notification if context is available and there are new transactions
      if (state.context != null && transactions.isNotEmpty) {
        // Additional notifications could be shown here if needed
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: LoyaltyStatus.error,
          errorMessage: 'Failed to sync data: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onClearRedemptionStatus(
    ClearRedemptionStatus event,
    Emitter<LoyaltyState> emit,
  ) async {
    emit(state.copyWith(redemptionStatus: RedemptionStatus.initial));
  }

  Future<void> _onCheckExpiringPoints(
    CheckExpiringPoints event,
    Emitter<LoyaltyState> emit,
  ) async {
    if (state.loyaltyPoints == null || state.context == null) return;

    try {
      final expiringPoints = await _loyaltyService.getExpiringPoints();

      if (expiringPoints > 0 && state.context != null) {
        _notificationService.showExpiringPointsNotification(
          state.context!,
          expiringPoints,
        );
      }
    } catch (e) {
      // Silently handle expiring points check error
      print('Error checking expiring points: ${e.toString()}');
    }
  }

  Future<void> _onResetLoyaltyData(
    ResetLoyaltyData event,
    Emitter<LoyaltyState> emit,
  ) async {
    // Reset to initial state to clear all data from previous user
    print('Resetting loyalty data due to user logout');
    emit(LoyaltyState.initial());

    // Reset data in the service layer
    _loyaltyService.resetData();

    // Cancel any active subscriptions
    _loyaltyPointsSubscription?.cancel();

    // Re-establish subscription but it won't have data until next login
    _subscribeToPointsUpdates();
  }

  void _subscribeToPointsUpdates() {
    _loyaltyPointsSubscription?.cancel();
    _loyaltyPointsSubscription = _loyaltyService
        .getLoyaltyPointsStream()
        .listen((loyaltyPoints) {
          add(LoyaltyPointsLoaded(loyaltyPoints));
        });
  }

  @override
  Future<void> close() {
    _loyaltyPointsSubscription?.cancel();
    return super.close();
  }
}
