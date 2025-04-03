import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loyalty_app/core/di/dependency_injection.dart';
import 'package:loyalty_app/features/auth/data/models/auth_user.dart';
import 'package:loyalty_app/features/auth/domain/services/auth_service.dart';
import 'package:loyalty_app/features/loyalty/api/woocommerce_sync_service.dart';
import 'package:loyalty_app/features/loyalty/bloc/loyalty_bloc.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthInitialize extends AuthEvent {
  const AuthInitialize();
}

class AuthLogin extends AuthEvent {
  final String username;
  final String password;

  const AuthLogin({required this.username, required this.password});

  @override
  List<Object> get props => [username, password];
}

class AuthRegister extends AuthEvent {
  final String email;
  final String username;
  final String password;

  const AuthRegister({
    required this.email,
    required this.username,
    required this.password,
  });

  @override
  List<Object> get props => [email, username, password];
}

class AuthLogout extends AuthEvent {
  const AuthLogout();
}

class AuthRequestPasswordReset extends AuthEvent {
  final String email;

  const AuthRequestPasswordReset({required this.email});

  @override
  List<Object> get props => [email];
}

class AuthResetPassword extends AuthEvent {
  final String resetToken;
  final String newPassword;

  const AuthResetPassword({
    required this.resetToken,
    required this.newPassword,
  });

  @override
  List<Object> get props => [resetToken, newPassword];
}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final AuthUser user;

  const AuthAuthenticated(this.user);

  @override
  List<Object> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthFailure extends AuthState {
  final String error;

  const AuthFailure(this.error);

  @override
  List<Object> get props => [error];
}

class PasswordResetRequested extends AuthState {
  const PasswordResetRequested();
}

class PasswordResetSuccess extends AuthState {
  const PasswordResetSuccess();
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({required AuthService authService})
    : _authService = authService,
      super(const AuthInitial()) {
    on<AuthInitialize>(_onInitialize);
    on<AuthLogin>(_onLogin);
    on<AuthRegister>(_onRegister);
    on<AuthLogout>(_onLogout);
    on<AuthRequestPasswordReset>(_onRequestPasswordReset);
    on<AuthResetPassword>(_onResetPassword);
  }

  Future<void> _onInitialize(
    AuthInitialize event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final isAuthenticated = await _authService.init();
    if (isAuthenticated && _authService.currentUser != null) {
      emit(AuthAuthenticated(_authService.currentUser!));

      // Set customer ID in WooCommerce sync service if available
      try {
        final user = _authService.currentUser!;
        if (user.id != null) {
          final syncService = getIt<WooCommerceSyncService>();
          syncService.customerId = user.id;

          // Trigger initial data loading
          print('Authenticated: Initializing loyalty data for user ${user.id}');

          // Force loyalty data to reload immediately
          final loyaltyBloc = getIt<LoyaltyBloc>();
          loyaltyBloc.add(LoadPointsTransactions());
        }
      } catch (e) {
        print('Error initializing user data: $e');
      }
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(AuthLogin event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    final result = await _authService.login(event.username, event.password);

    if (result.success && result.user != null) {
      print('Authentication successful - triggering data sync');

      // Set customer ID in WooCommerce sync service
      try {
        if (result.user!.id != null) {
          final syncService = getIt<WooCommerceSyncService>();
          syncService.customerId = result.user!.id;

          // Force loyalty data to reload
          final loyaltyBloc = getIt<LoyaltyBloc>();
          loyaltyBloc.add(LoadPointsTransactions());
        }
      } catch (e) {
        print('Error setting customer ID: $e');
      }

      emit(AuthAuthenticated(result.user!));
    } else {
      emit(AuthFailure(result.error ?? 'Failed to log in'));
    }
  }

  Future<void> _onRegister(AuthRegister event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    final result = await _authService.register(
      event.email,
      event.username,
      event.password,
    );

    if (result.success && result.user != null) {
      print('Registration successful - triggering data sync');

      // Set customer ID in WooCommerce sync service
      try {
        if (result.user!.id != null) {
          final syncService = getIt<WooCommerceSyncService>();
          syncService.customerId = result.user!.id;

          // Force loyalty data to reload
          final loyaltyBloc = getIt<LoyaltyBloc>();
          loyaltyBloc.add(LoadPointsTransactions());
        }
      } catch (e) {
        print('Error setting customer ID: $e');
      }

      emit(AuthAuthenticated(result.user!));
    } else {
      emit(AuthFailure(result.error ?? 'Failed to register'));
    }
  }

  Future<void> _onLogout(AuthLogout event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    // Clear WooCommerce sync service customer ID
    try {
      final syncService = getIt<WooCommerceSyncService>();
      syncService.customerId = null;

      // Reset loyalty data to prevent data leakage between users
      final loyaltyBloc = getIt<LoyaltyBloc>();
      loyaltyBloc.add(const ResetLoyaltyData());
    } catch (e) {
      print('Error clearing user data: $e');
    }

    await _authService.logout();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onRequestPasswordReset(
    AuthRequestPasswordReset event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final success = await _authService.requestPasswordReset(event.email);

    if (success) {
      emit(const PasswordResetRequested());
    } else {
      emit(const AuthFailure('Failed to request password reset'));
    }
  }

  Future<void> _onResetPassword(
    AuthResetPassword event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final success = await _authService.resetPassword(
      event.resetToken,
      event.newPassword,
    );

    if (success) {
      emit(const PasswordResetSuccess());
    } else {
      emit(const AuthFailure('Failed to reset password'));
    }
  }
}
