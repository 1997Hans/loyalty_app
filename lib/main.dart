import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loyalty_app/core/di/dependency_injection.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';
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
    // Start WooCommerce sync service with a delay to avoid blocking app startup
    // This will run after the app is visible to the user
    Future.delayed(const Duration(seconds: 2), () {
      try {
        final syncService = getIt<WooCommerceSyncService>();
        syncService.startBackgroundSync();
      } catch (e) {
        print('Error starting WooCommerce sync service: $e');
      }
    });

    return MaterialApp(
      title: 'Loyalty App',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const MainNavigation(),
    );
  }
}
