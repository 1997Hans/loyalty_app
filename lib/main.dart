import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loyalty_app/core/di/dependency_injection.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';
import 'package:loyalty_app/features/auth/bloc/auth_bloc.dart';
import 'package:loyalty_app/features/auth/ui/screens/landing_screen.dart';
import 'package:loyalty_app/features/loyalty/api/woocommerce_sync_service.dart';
import 'package:loyalty_app/features/loyalty/bloc/loyalty_bloc.dart';
import 'package:loyalty_app/core/navigation/main_navigation.dart';

void main() {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Set up dependency injection
  setupDependencies();

  // Run the app with error handling
  runZonedGuarded(() => runApp(const MyApp()), (error, stack) {
    print('Unhandled error in app: $error');
    print(stack);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Don't start WooCommerce sync service here - it will now be started after authentication
    // This prevents unnecessary sync attempts before the user is logged in

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => getIt<AuthBloc>()..add(const AuthInitialize()),
        ),
        BlocProvider<LoyaltyBloc>(create: (context) => getIt<LoyaltyBloc>()),
      ],
      child: MaterialApp(
        title: 'Loyalty App',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: AuthenticationWrapper(),
      ),
    );
  }
}

/// Wrapper widget that handles authentication state
class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          // Show loading indicator while checking auth state
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state is AuthAuthenticated) {
          // User is authenticated, show main navigation
          return const MainNavigation();
        } else {
          // User is not authenticated, show landing screen
          return const LandingScreen();
        }
      },
    );
  }
}
