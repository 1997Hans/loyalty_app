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

  // Cache bloc instance to ensure it's the same throughout the app
  late final LoyaltyBloc _loyaltyBloc;

  @override
  void initState() {
    super.initState();
    // Get the bloc instance once and use it consistently
    _loyaltyBloc = getIt<LoyaltyBloc>();

    // Trigger initial data loading immediately
    _loadInitialData();
  }

  // Load all initial data when app starts
  void _loadInitialData() {
    print('MainNavigation: Loading initial data');
    _loyaltyBloc.add(LoadPointsTransactions());

    // Additional initialization can be added here
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This will run after the first frame is rendered
      print(
        'MainNavigation: First frame rendered, checking for additional data to load',
      );

      // Ensure data is loaded for current tab
      _loadDataForCurrentTab();
    });
  }

  // Load appropriate data based on the selected tab
  void _loadDataForCurrentTab() {
    print('Loading data for tab $_selectedIndex');

    switch (_selectedIndex) {
      case 0: // Dashboard
        _loyaltyBloc.add(LoadPointsTransactions());
        break;
      case 1: // Points history
        _loyaltyBloc.add(LoadPointsTransactions());
        break;
      case 2: // Rewards
        _loyaltyBloc.add(LoadPointsTransactions());
        break;
      case 3: // Profile
        // No specific data needs to be loaded
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _loyaltyBloc,
      child: Scaffold(
        // Use a simple body selection rather than IndexedStack to avoid state issues
        body: _buildBody(),
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
                    if (_selectedIndex != index) {
                      setState(() {
                        _selectedIndex = index;
                      });

                      // Load appropriate data when tab changes
                      _loadDataForCurrentTab();
                    }
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
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build the appropriate body based on selected index
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const LoyaltyDashboardScreen();
      case 1:
        return const LoyaltyPointsScreen();
      case 2:
        return BlocBuilder<LoyaltyBloc, LoyaltyState>(
          builder: (context, state) {
            print('Building rewards screen with state: ${state.status}');
            int points = 0;
            if (state.status == LoyaltyStatus.loaded &&
                state.loyaltyPoints != null) {
              points = state.loyaltyPoints!.currentPoints;
            }
            return PointsRedemptionScreen(availablePoints: points);
          },
        );
      case 3:
        return const WooCommerceSyncScreen();
      default:
        return const LoyaltyDashboardScreen();
    }
  }
}
