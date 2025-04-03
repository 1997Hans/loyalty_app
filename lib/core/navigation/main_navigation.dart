import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loyalty_app/core/di/dependency_injection.dart';
import 'package:loyalty_app/features/loyalty/bloc/loyalty_bloc.dart';
import 'package:loyalty_app/features/loyalty/ui/screens/loyalty_dashboard_screen.dart';
import 'package:loyalty_app/features/loyalty/ui/screens/loyalty_points_screen.dart';
import 'package:loyalty_app/features/loyalty/ui/screens/points_redemption_screen.dart';
import 'package:loyalty_app/features/loyalty/ui/screens/woocommerce_sync_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final _navigatorKeys = {
    0: GlobalKey<NavigatorState>(),
    1: GlobalKey<NavigatorState>(),
    2: GlobalKey<NavigatorState>(),
    3: GlobalKey<NavigatorState>(),
  };

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final isFirstRouteInCurrentTab =
            !await _navigatorKeys[_selectedIndex]!.currentState!.maybePop();

        if (isFirstRouteInCurrentTab) {
          // If we're already at the root page of the current tab, switch to home tab
          if (_selectedIndex != 0) {
            setState(() {
              _selectedIndex = 0;
            });
            return false;
          }
        }
        // If we're on the home tab and at root, let system handle the back button
        return isFirstRouteInCurrentTab;
      },
      child: BlocProvider<LoyaltyBloc>.value(
        value: getIt<LoyaltyBloc>()..add(LoadPointsTransactions()),
        child: Scaffold(
          body: Stack(
            children: [
              _buildOffstageNavigator(0),
              _buildOffstageNavigator(1),
              _buildOffstageNavigator(2),
              _buildOffstageNavigator(3),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 8.0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: BottomNavigationBar(
                    currentIndex: _selectedIndex,
                    onTap: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    type: BottomNavigationBarType.fixed,
                    backgroundColor: const Color(0xFF1E1E1E),
                    selectedItemColor: Colors.amberAccent,
                    unselectedItemColor: Colors.grey,
                    showSelectedLabels: true,
                    showUnselectedLabels: true,
                    elevation: 0,
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home_outlined),
                        activeIcon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.workspace_premium_outlined),
                        activeIcon: Icon(Icons.workspace_premium),
                        label: 'Points',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.redeem_outlined),
                        activeIcon: Icon(Icons.redeem),
                        label: 'Rewards',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.person_outline),
                        activeIcon: Icon(Icons.person),
                        label: 'Settings',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOffstageNavigator(int index) {
    return Offstage(
      offstage: _selectedIndex != index,
      child: Navigator(
        key: _navigatorKeys[index],
        initialRoute: '/',
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) {
              switch (index) {
                case 0:
                  return const LoyaltyDashboardScreen();
                case 1:
                  return const LoyaltyPointsScreen();
                case 2:
                  // Handle the rewards tab navigation
                  if (settings.name == '/rewards' &&
                      settings.arguments != null) {
                    // Extract arguments for the redemption screen
                    final args = settings.arguments as Map<String, dynamic>;
                    final availablePoints = args['availablePoints'] as int;

                    return PointsRedemptionScreen(
                      availablePoints: availablePoints,
                    );
                  }

                  // Use BlocBuilder to get current points when accessing directly from tab
                  return BlocBuilder<LoyaltyBloc, LoyaltyState>(
                    builder: (context, state) {
                      int points = 0;
                      if (state.status == LoyaltyStatus.loaded &&
                          state.loyaltyPoints != null) {
                        points = state.loyaltyPoints!.currentPoints;
                      }

                      return PointsRedemptionScreen(availablePoints: points);
                    },
                  );
                case 3:
                  // Settings page with WooCommerce sync
                  return const WooCommerceSyncScreen();
                default:
                  return const LoyaltyDashboardScreen();
              }
            },
          );
        },
      ),
    );
  }
}
