import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loyalty_app/core/navigation/main_navigation.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';
import 'package:loyalty_app/features/auth/ui/screens/landing_screen.dart';
import 'package:loyalty_app/features/loyalty/domain/blocs/loyalty_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoyaltyBloc()..add(LoadLoyaltyData()),
      child: MaterialApp(
        title: 'Loyalty App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AppInitializer(),
      ),
    );
  }
}

// This widget checks authentication state and decides which screen to show
class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context) {
    // For demonstration, we're using a hardcoded authentication state
    // In a real app, you would check authentication status here
    const bool isAuthenticated = true;
    
    if (isAuthenticated) {
      return const MainNavigation();
    } else {
      return const LandingScreen();
    }
  }
}
