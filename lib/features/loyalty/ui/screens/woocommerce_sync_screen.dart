import 'package:flutter/material.dart';
import 'package:loyalty_app/core/common/widgets/simple_glass_card.dart';
import 'package:loyalty_app/core/config/app_config.dart';
import 'package:loyalty_app/core/di/dependency_injection.dart';
import 'package:loyalty_app/core/utils/gradient_background.dart';
import 'package:loyalty_app/features/loyalty/api/woocommerce_sync_service.dart';
import 'package:loyalty_app/features/loyalty/api/woocommerce_client.dart';

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
  late WooCommerceSyncService _syncService;

  // API information for diagnostics
  final String _apiUrl = AppConfig.woocommerceBaseUrl;
  final String _consumerKey =
      AppConfig.woocommerceConsumerKey.substring(0, 10) + '...';

  @override
  void initState() {
    super.initState();
    _syncService = getIt<WooCommerceSyncService>();

    // Initialize the controller with current ID if set
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load current customer ID if available
      if (_syncService.customerId != null) {
        _customerIdController.text = _syncService.customerId.toString();
      }
      _subscribeToSyncStatus();
      _isInitialized = true;
    });
  }

  void _subscribeToSyncStatus() {
    _syncService.syncStatus.listen((status) {
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
      _syncService.startBackgroundSync();
    } else {
      _syncService.stopBackgroundSync();
    }
  }

  void _manualSync() {
    setState(() {
      _isSyncing = true;
    });

    // Update customer ID if needed
    final customerId = int.tryParse(_customerIdController.text);
    if (customerId != null && customerId > 0) {
      _syncService.customerId = customerId;
    }

    _syncService.syncWooCommerceOrders();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WooCommerce Sync'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showApiDetails,
            tooltip: 'API Info',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isSyncing ? null : _manualSync,
            tooltip: 'Manual Sync',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearLogs,
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: GradientBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SimpleGlassCard(
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
                  const SizedBox(height: 8),
                  const Text(
                    'Earn points automatically from your WooCommerce purchases.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Points Rate: ${AppConfig.woocommercePointsPerAmount} points per ${AppConfig.currencySymbol}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Switch(
                        value: _isAutoSyncEnabled,
                        onChanged: _toggleAutoSync,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _customerIdController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Customer ID',
                            border: OutlineInputBorder(),
                            helperText: 'From WooCommerce',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isSyncing ? null : _manualSync,
                        child: const Text('Sync Now'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isAutoSyncEnabled ? 'Auto-sync is ON' : 'Auto-sync is OFF',
                    style: TextStyle(
                      color: _isAutoSyncEnabled ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Sync Logs',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SimpleGlassCard(
                child:
                    _syncLogs.isEmpty
                        ? const Center(
                          child: Text(
                            'No sync logs yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                        : ListView.builder(
                          itemCount: _syncLogs.length,
                          itemBuilder: (context, index) {
                            final log = _syncLogs[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Text(
                                log,
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      log.contains('error') ||
                                              log.contains('Failed')
                                          ? Colors.red
                                          : log.contains('Awarded') ||
                                              log.contains('Success')
                                          ? Colors.green
                                          : null,
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ),
            const SizedBox(height: 16),
            SimpleGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Troubleshooting',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'If you encounter sync issues:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '1. Verify the Customer ID matches your WooCommerce user',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const Text(
                    '2. Ensure your API keys have Read/Write permissions',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const Text(
                    '3. Check that you have completed orders in WooCommerce',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isSyncing ? null : _testConnection,
                        icon: const Icon(Icons.network_check),
                        label: const Text('Test Connection'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _showApiDetails,
                        icon: const Icon(Icons.settings),
                        label: const Text('API Configuration'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _customerIdController.dispose();
    super.dispose();
  }
}
