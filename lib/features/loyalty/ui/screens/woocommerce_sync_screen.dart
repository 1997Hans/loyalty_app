import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loyalty_app/core/common/widgets/simple_glass_card.dart';
import 'package:loyalty_app/core/config/app_config.dart';
import 'package:loyalty_app/core/di/dependency_injection.dart';
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
  List<String> _syncLogs = [];
  bool _isAutoSyncEnabled = AppConfig.enableAutomaticPointsAward;
  bool _isSyncing = false;
  bool _isInitialized = false;
  late WooCommerceSyncService _wooCommerceSyncService;
  final WooCommerceClient _client = getIt<WooCommerceClient>();
  bool _isConnected = false;
  String _statusText = 'Checking connection...';

  // API information for diagnostics
  final String _apiUrl = AppConfig.woocommerceBaseUrl;
  final String _consumerKey =
      AppConfig.woocommerceConsumerKey.substring(0, 10) + '...';

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
      _wooCommerceSyncService.customerId = customerId;
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
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserProfileSection(),
                const SizedBox(height: 24),
                _buildWooCommerceSection(),
                const SizedBox(height: 24),
                _buildAppSettingsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // User profile section with account details
  Widget _buildUserProfileSection() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          final user = state.user;
          return SimpleGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage:
                          user.avatarUrl != null
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                      child:
                          user.avatarUrl == null
                              ? const Icon(Icons.person, size: 40)
                              : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${user.username}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.badge),
                  title: const Text('Account Type'),
                  subtitle: Text(
                    user.roles.isNotEmpty ? user.roles.first : 'Customer',
                  ),
                ),
                _buildLogoutButton(),
              ],
            ),
          );
        }
        return const SimpleGlassCard(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Please log in to view your profile'),
            ),
          ),
        );
      },
    );
  }

  // WooCommerce integration section
  Widget _buildWooCommerceSection() {
    return SimpleGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WooCommerce Integration',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Link your store account to earn points automatically from purchases',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          // Rest of the WooCommerce section
          _buildCustomerIdField(),
          const SizedBox(height: 16),
          _buildWooCommerceButtons(),
          const SizedBox(height: 16),
          _buildConnectionStatus(),
          const SizedBox(height: 8),
          _buildSyncOptions(),
        ],
      ),
    );
  }

  // App settings section
  Widget _buildAppSettingsSection() {
    return SimpleGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'App Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text(
              'Receive updates about your points and rewards',
            ),
            value: true, // This would be connected to actual settings
            onChanged: (value) {
              // Implement notification settings
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'),
            trailing: const Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text('Logout', style: TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildCustomerIdField() {
    return TextField(
      controller: _customerIdController,
      decoration: InputDecoration(
        labelText: 'WooCommerce Customer ID',
        hintText: 'Enter your WooCommerce customer ID',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: () {
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('WooCommerce Customer ID'),
                    content: const Text(
                      'This is your customer ID from your WooCommerce store. '
                      'You can find this in your account settings on the website.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Got it'),
                      ),
                    ],
                  ),
            );
          },
        ),
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildWooCommerceButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _testConnection,
            icon: const Icon(Icons.wifi),
            label: const Text('Test Connection'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _syncNow,
            icon: const Icon(Icons.sync),
            label: const Text('Sync Now'),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    final statusColor = _isConnected ? Colors.green : Colors.red;
    final statusIcon = _isConnected ? Icons.check_circle : Icons.error;

    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_statusText, style: TextStyle(color: statusColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Automatic Points Sync'),
          subtitle: const Text(
            'Automatically sync and award points for completed orders',
          ),
          value: _isAutoSyncEnabled,
          onChanged: _toggleAutoSync,
        ),
        if (_syncLogs.isNotEmpty) ...[
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sync Logs',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(onPressed: _clearLogs, child: const Text('Clear')),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 150,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: ListView.builder(
              itemCount: _syncLogs.length,
              reverse: true,
              itemBuilder: (context, index) {
                return Text(
                  _syncLogs[index],
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily: 'monospace',
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _customerIdController.dispose();
    super.dispose();
  }
}
