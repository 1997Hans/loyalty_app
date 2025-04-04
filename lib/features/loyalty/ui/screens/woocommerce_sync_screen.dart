import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loyalty_app/core/common/widgets/simple_glass_card.dart';
import 'package:loyalty_app/core/config/app_config.dart';
import 'package:loyalty_app/core/di/dependency_injection.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';
import 'package:loyalty_app/core/utils/gradient_background.dart';
import 'package:loyalty_app/features/auth/bloc/auth_bloc.dart';
import 'package:loyalty_app/features/loyalty/api/woocommerce_client.dart';
import 'package:loyalty_app/features/loyalty/api/woocommerce_sync_service.dart';
import 'package:loyalty_app/features/loyalty/bloc/loyalty_bloc.dart';

/// Profile screen with user information and WooCommerce connection controls
class WooCommerceSyncScreen extends StatefulWidget {
  const WooCommerceSyncScreen({super.key});

  @override
  State<WooCommerceSyncScreen> createState() => _WooCommerceSyncScreenState();
}

class _WooCommerceSyncScreenState extends State<WooCommerceSyncScreen> {
  final TextEditingController _customerIdController = TextEditingController();
  final List<String> _syncLogs = [];
  bool _isAutoSyncEnabled = AppConfig.enableAutomaticPointsAward;
  bool _isSyncing = false;
  bool _isInitialized = false;
  late WooCommerceSyncService _wooCommerceSyncService;
  final WooCommerceClient _client = getIt<WooCommerceClient>();
  bool _isConnected = false;
  String _statusText = 'Checking connection...';
  String _statusMessage = 'Initializing...';
  StreamSubscription? _syncStatusSubscription;

  // API information for diagnostics
  final String _apiUrl = AppConfig.woocommerceBaseUrl;
  final String _consumerKey =
      '${AppConfig.woocommerceConsumerKey.substring(0, 10)}...';

  @override
  void initState() {
    super.initState();
    _wooCommerceSyncService = getIt<WooCommerceSyncService>();

    // Initialize the controller with current ID if set
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load current customer ID if available
      if (_wooCommerceSyncService.customerId != null) {
        _customerIdController.text =
            _wooCommerceSyncService.customerId.toString();
      }
      _subscribeToSyncStatus();
      _isInitialized = true;
    });

    _checkConnection();
    _initializeSyncService();
  }

  void _subscribeToSyncStatus() {
    _wooCommerceSyncService.syncStatus.listen((status) {
      if (mounted) {
        setState(() {
          _syncLogs.add(status);
          // Limit log size to prevent memory issues
          if (_syncLogs.length > 100) {
            _syncLogs.removeAt(0);
          }
        });
      }
    });
  }

  void _toggleAutoSync(bool value) {
    setState(() {
      _isAutoSyncEnabled = value;
    });

    if (value) {
      _wooCommerceSyncService.startBackgroundSync();
    } else {
      _wooCommerceSyncService.stopBackgroundSync();
    }
  }

  void _manualSync() {
    setState(() {
      _isSyncing = true;
    });

    // Update customer ID if needed
    final customerId = int.tryParse(_customerIdController.text);
    if (customerId != null && customerId > 0) {
      _wooCommerceSyncService.customerId = customerId.toString();
    }

    _wooCommerceSyncService.syncWooCommerceOrders();
  }

  void _clearLogs() {
    setState(() {
      _syncLogs.clear();
    });
  }

  void _testConnection() async {
    if (!mounted) return;

    setState(() {
      _isSyncing = true;
      _syncLogs.insert(
        0,
        '${DateTime.now().toString().substring(0, 19)}: Testing WooCommerce API connection...',
      );
    });

    try {
      // Use the API client directly to test the connection
      final client = getIt<WooCommerceClient>();
      final customerId = int.tryParse(_customerIdController.text) ?? 1;

      // First, try to get customer information
      if (!mounted) return;
      setState(() {
        _syncLogs.insert(
          0,
          '${DateTime.now().toString().substring(0, 19)}: Fetching customer #$customerId data...',
        );
      });

      try {
        final points = await client.getCustomerLoyaltyPoints(customerId);
        if (!mounted) return;
        setState(() {
          _syncLogs.insert(
            0,
            '${DateTime.now().toString().substring(0, 19)}: ✓ Customer API connection successful. Current loyalty points: $points',
          );
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _syncLogs.insert(
            0,
            '${DateTime.now().toString().substring(0, 19)}: ✗ Failed to fetch customer: $e',
          );
        });
      }

      // Then, try to get orders
      if (!mounted) return;
      setState(() {
        _syncLogs.insert(
          0,
          '${DateTime.now().toString().substring(0, 19)}: Fetching orders for customer #$customerId...',
        );
      });

      try {
        final orders = await client.getCustomerOrders(customerId);
        if (!mounted) return;
        setState(() {
          _syncLogs.insert(
            0,
            '${DateTime.now().toString().substring(0, 19)}: ✓ Orders API connection successful. Found ${orders.length} orders.',
          );

          if (orders.isNotEmpty) {
            final statuses = <String>{};
            for (final order in orders) {
              statuses.add(order['status'] as String? ?? 'unknown');
            }

            _syncLogs.insert(
              0,
              '${DateTime.now().toString().substring(0, 19)}: Order statuses: ${statuses.join(', ')}',
            );

            // Check if there are completed orders
            final hasCompleted = statuses.contains('completed');
            if (!hasCompleted) {
              _syncLogs.insert(
                0,
                '${DateTime.now().toString().substring(0, 19)}: ⚠️ No completed orders found. Only completed orders earn points.',
              );
            }
          }
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _syncLogs.insert(
            0,
            '${DateTime.now().toString().substring(0, 19)}: ✗ Failed to fetch orders: $e',
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _syncLogs.insert(
          0,
          '${DateTime.now().toString().substring(0, 19)}: ✗ Connection test failed: $e',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  void _showApiDetails() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('WooCommerce API Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('API URL: $_apiUrl'),
                const SizedBox(height: 8),
                Text('Consumer Key: $_consumerKey'),
                const SizedBox(height: 8),
                Text(
                  'Points per unit currency: ${AppConfig.woocommercePointsPerAmount}',
                ),
                const SizedBox(height: 8),
                const Text(
                  'To update these values, edit lib/core/config/app_config.dart',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Future<void> _checkConnection() async {
    final isConnected = await _client.testConnection();
    setState(() {
      _isConnected = isConnected;
      _statusText =
          isConnected
              ? 'Connected to WooCommerce'
              : 'Not connected: ${_client.lastError ?? "Unknown error"}';
    });
  }

  void _syncNow() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      await _wooCommerceSyncService.syncWooCommerceOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Synchronization completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync failed: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Logout'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.read<AuthBloc>().add(const AuthLogout());
                },
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: GradientBackground(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAccountSection(authState),
                  const SizedBox(height: 24),
                  _buildWooCommerceSection(authState),
                  const SizedBox(height: 24),
                  _buildAppSettingsSection(),
                  const SizedBox(height: 24),
                  _buildAboutSection(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountSection(AuthState authState) {
    String username = 'Guest';
    String email = 'Not signed in';
    bool isAuthenticated = false;

    if (authState is AuthAuthenticated) {
      username =
          authState.user.displayName ?? authState.user.username ?? 'User';
      email = authState.user.email ?? 'No email provided';
      isAuthenticated = true;
    }

    return SimpleGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.amber.withOpacity(0.2),
                child: Icon(Icons.person, size: 36, color: Colors.amber),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(email, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          if (isAuthenticated) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Log Out', style: TextStyle(color: Colors.red)),
              onPressed: _logout,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWooCommerceSection(AuthState authState) {
    bool isCustomerIdSet = _wooCommerceSyncService.customerId != null;
    bool isAuthenticated = authState is AuthAuthenticated;

    return SimpleGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'WooCommerce Integration',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (_isSyncing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                isCustomerIdSet && isAuthenticated
                    ? Icons.check_circle
                    : Icons.info_outline,
                color:
                    isCustomerIdSet && isAuthenticated
                        ? Colors.green
                        : Colors.amber,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isCustomerIdSet && isAuthenticated
                      ? 'Connected and automatically syncing loyalty points'
                      : 'Sign in to automatically sync loyalty points',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Points are automatically awarded for purchases made in the WooCommerce store',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (_syncLogs.isNotEmpty) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text(
                'Sync Activity',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              collapsedIconColor: Colors.white70,
              iconColor: Colors.amber,
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: ListView.builder(
                    itemCount: _syncLogs.length.clamp(0, 20),
                    itemBuilder: (context, index) {
                      return Text(
                        _syncLogs[index],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppSettingsSection() {
    return SimpleGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'App Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text(
              'Push Notifications',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Receive updates about your points',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            value: true,
            activeColor: Colors.amber,
            onChanged: (value) {
              // Would be implemented with actual notification settings
            },
          ),
          const Divider(color: Colors.white24),
          SwitchListTile(
            title: const Text(
              'Dark Theme',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Use dark theme throughout the app',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            value: true,
            activeColor: Colors.amber,
            onChanged: null, // Disabled as dark theme is the only option
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return SimpleGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.amber),
            title: const Text(
              'App Version',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              '1.0.0',
              style: TextStyle(color: Colors.white70),
            ),
            dense: true,
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(
              Icons.privacy_tip_outlined,
              color: Colors.amber,
            ),
            title: const Text(
              'Privacy Policy',
              style: TextStyle(color: Colors.white),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.white70,
            ),
            dense: true,
            onTap: () {
              // Would navigate to privacy policy
            },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.support_outlined, color: Colors.amber),
            title: const Text(
              'Contact Support',
              style: TextStyle(color: Colors.white),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.white70,
            ),
            dense: true,
            onTap: () {
              // Would open contact support options
            },
          ),
        ],
      ),
    );
  }

  Future<void> _initializeSyncService() async {
    try {
      _wooCommerceSyncService = getIt<WooCommerceSyncService>();

      setState(() {
        _statusMessage = 'Connected to sync service';
        _isConnected = true;
      });

      // Listen for sync status updates
      _syncStatusSubscription = _wooCommerceSyncService.syncStatus.listen((
        message,
      ) {
        setState(() {
          _syncLogs.insert(
            0,
            '${DateTime.now().toString().split('.')[0]} - $message',
          );
          if (message.contains('sync')) _isSyncing = true;
          if (message.contains('Processed')) _isSyncing = false;
          if (message.contains('Error')) _isSyncing = false;
        });
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error initializing sync service: $e';
        _isConnected = false;
      });
    }
  }

  @override
  void dispose() {
    _customerIdController.dispose();
    _syncStatusSubscription?.cancel();
    super.dispose();
  }
}
