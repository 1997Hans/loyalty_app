import 'dart:async';

import 'package:loyalty_app/core/config/app_config.dart';
import 'package:loyalty_app/features/loyalty/api/woocommerce_client.dart';
import 'package:loyalty_app/features/loyalty/domain/models/points_transaction.dart';
import 'package:loyalty_app/features/loyalty/domain/models/woocommerce_order.dart';
import 'package:loyalty_app/features/loyalty/domain/services/loyalty_service.dart';

/// Service for synchronizing WooCommerce orders and processing loyalty points
class WooCommerceSyncService {
  final WooCommerceClient _woocommerceClient;
  final LoyaltyService _loyaltyService;

  // Store customer ID for WooCommerce API
  int? _customerId;
  bool _isSyncing = false;
  bool _disposed = false;
  DateTime? _lastSyncTime;

  // Maintain a set of processed orders to avoid duplicate points
  final Set<String> _processedOrders = {};

  // Stream controller for sync status updates
  final _syncStatusController = StreamController<String>.broadcast();

  // Sync interval in minutes
  static const int _syncIntervalMinutes = 15;
  Timer? _syncTimer;

  // Getters
  Stream<String> get syncStatus => _syncStatusController.stream;
  bool get isAutomaticSyncEnabled => AppConfig.enableAutomaticPointsAward;
  bool get isSyncing => _isSyncing;
  int? get customerId => _customerId;

  // Set customer ID
  set customerId(int? id) {
    _customerId = id;
    if (id != null) {
      _addSyncStatus('Customer ID updated to: $id');
    } else {
      _addSyncStatus('Customer ID cleared');
    }
  }

  WooCommerceSyncService({
    required WooCommerceClient woocommerceClient,
    required LoyaltyService loyaltyService,
    int? customerId,
  }) : _woocommerceClient = woocommerceClient,
       _loyaltyService = loyaltyService {
    if (customerId != null) {
      _customerId = customerId;
    }
  }

  // Safe way to add sync status
  void _addSyncStatus(String status) {
    if (!_disposed && _syncStatusController.hasListener) {
      _syncStatusController.add(status);
    }
  }

  /// Starts the background sync process
  void startBackgroundSync({
    Duration syncInterval = const Duration(minutes: 15),
  }) {
    if (_disposed) return;

    try {
      _addSyncStatus('Starting WooCommerce background sync service...');

      // Cancel any existing timer
      _syncTimer?.cancel();

      if (!AppConfig.enableAutomaticPointsAward) {
        _addSyncStatus(
          'Automatic points award is disabled in config. Background sync not started.',
        );
        return;
      }

      if (_customerId == null) {
        _addSyncStatus('Customer ID not set. Background sync not started.');
        return;
      }

      // Initial sync
      syncWooCommerceOrders();

      // Schedule periodic sync
      _syncTimer = Timer.periodic(syncInterval, (_) {
        if (!_disposed) {
          syncWooCommerceOrders();
        }
      });

      _addSyncStatus(
        'Background sync scheduled every ${syncInterval.inMinutes} minutes',
      );
    } catch (e, stackTrace) {
      _addSyncStatus('Error starting background sync: $e');
      print('WooCommerceSyncService error: $e');
      print(stackTrace);
    }
  }

  /// Stop background synchronization
  void stopBackgroundSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _addSyncStatus('Automatic sync stopped');
  }

  /// Synchronize WooCommerce orders with loyalty system
  Future<void> syncWooCommerceOrders() async {
    if (_disposed || _isSyncing) return;

    try {
      _isSyncing = true;
      if (_customerId == null) {
        _addSyncStatus('Customer ID not set. Cannot sync orders.');
        return;
      }

      _addSyncStatus('Starting WooCommerce orders sync...');

      // Test connection first
      final isConnected = await _woocommerceClient.testConnection();
      if (!isConnected) {
        _addSyncStatus(
          'Failed to connect to WooCommerce API: ${_woocommerceClient.lastError}',
        );
        return;
      }

      // Get orders from WooCommerce
      final ordersJson = await _woocommerceClient.getCustomerOrders(
        _customerId!,
      );

      if (ordersJson.isEmpty) {
        _addSyncStatus('No orders found for customer $_customerId');
        return;
      }

      _addSyncStatus('Found ${ordersJson.length} orders');

      // Process each order for loyalty points
      int processedCount = 0;
      for (final orderJson in ordersJson) {
        if (_disposed) break;

        await _processOrderForLoyaltyPoints(orderJson);
        processedCount++;
      }

      _addSyncStatus('Processed $processedCount orders');
      _lastSyncTime = DateTime.now();
    } catch (e, stackTrace) {
      _addSyncStatus('Error during sync: $e');
      print('WooCommerceSyncService error: $e');
      print(stackTrace);
    } finally {
      _isSyncing = false;
    }
  }

  /// Process an order for loyalty points
  Future<void> _processOrderForLoyaltyPoints(
    Map<String, dynamic> orderJson,
  ) async {
    if (_disposed) return;

    try {
      // Create order object from JSON
      final order = WooCommerceOrder.fromJson(orderJson);
      final orderId = order.id.toString();

      _addSyncStatus(
        'Processing order #${order.orderNumber} (status: ${order.status})',
      );

      // Only process completed orders that haven't been processed before
      if (order.status != 'completed') {
        _addSyncStatus(
          'Order #${order.orderNumber} not completed (${order.status}), skipping',
        );
        return;
      }

      if (_processedOrders.contains(orderId)) {
        _addSyncStatus(
          'Order #${order.orderNumber} already processed, skipping',
        );
        return;
      }

      // Calculate points based on order total and configured points per amount
      final orderTotal = order.total;
      final pointsToAward =
          (orderTotal * AppConfig.woocommercePointsPerAmount).round();

      if (pointsToAward <= 0) {
        _addSyncStatus('No points to award for order #${order.orderNumber}');
        return;
      }

      // Award points through loyalty service
      await _loyaltyService.addPointsFromPurchase(
        orderTotal,
        orderId,
        'WooCommerce order #${order.orderNumber}',
      );

      // Mark order as processed
      _processedOrders.add(orderId);
      _addSyncStatus(
        'Awarded $pointsToAward points for order #${order.orderNumber}',
      );
    } catch (e) {
      _addSyncStatus('Error processing order: $e');
      print('Error processing order for loyalty points: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    if (!_disposed) {
      _disposed = true;
      _syncTimer?.cancel();
      _syncTimer = null;
      _isSyncing = false;

      // Close the stream controller if it's still open
      if (!_syncStatusController.isClosed) {
        _syncStatusController.close();
      }
    }
  }
}
