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

  // Track order statuses to detect transitions (order_id -> status)
  final Map<String, String> _orderStatuses = {};

  // Stream controller for sync status updates
  final _syncStatusController = StreamController<String>.broadcast();

  // Sync interval - much faster for real-time updates
  static const int _syncIntervalMinutes = 1; // Changed from 15 to 1 minute
  Timer? _syncTimer;

  // Getters
  Stream<String> get syncStatus => _syncStatusController.stream;
  bool get isAutomaticSyncEnabled => true;
  bool get isSyncing => _isSyncing;
  int? get customerId => _customerId;

  // Set customer ID
  set customerId(int? id) {
    print(
      'WooCommerceSyncService: Setting customer ID from $_customerId to $id',
    );
    _customerId = id;
    if (id != null) {
      _addSyncStatus('Customer ID updated to: $id');
      print(
        'WooCommerceSyncService: Triggering immediate sync for customer $id',
      );
      // Immediate sync when customer ID is set, then start fast background sync
      syncWooCommerceOrders(); // Immediate sync
      startBackgroundSync(
        syncInterval: const Duration(seconds: 30),
      ); // Every 30 seconds
    } else {
      _addSyncStatus('Customer ID cleared');
      stopBackgroundSync();
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
    if (!_disposed) {
      // Always log to console for debugging, regardless of listeners
      print('WooCommerceSyncService: $status');

      // Add to stream if there are listeners
      if (_syncStatusController.hasListener) {
        _syncStatusController.add(status);
      }
    }
  }

  /// Starts the background sync process
  void startBackgroundSync({
    Duration syncInterval = const Duration(seconds: 30),
  }) {
    if (_disposed) return;

    try {
      _addSyncStatus('🚀 Starting WooCommerce sync service...');

      // Cancel any existing timer
      _syncTimer?.cancel();

      if (_customerId == null) {
        _addSyncStatus('❌ Customer ID not set. Background sync not started.');
        return;
      }

      // Schedule periodic sync (no initial sync as it's called separately)
      _syncTimer = Timer.periodic(syncInterval, (_) {
        if (!_disposed && !_isSyncing) {
          syncWooCommerceOrders();
        }
      });

      final intervalText =
          syncInterval.inSeconds < 60
              ? '${syncInterval.inSeconds} seconds'
              : '${syncInterval.inMinutes} minutes';

      _addSyncStatus('✅ Background sync scheduled every $intervalText');
    } catch (e, stackTrace) {
      _addSyncStatus('❌ Error starting background sync: $e');
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
      final startTime = DateTime.now();

      if (_customerId == null) {
        _addSyncStatus('❌ Customer ID not set. Cannot sync orders.');
        return;
      }

      _addSyncStatus('🔄 Starting sync for customer $_customerId...');

      // Test connection first (with faster timeout)
      final isConnected = await _woocommerceClient.testConnection();
      if (!isConnected) {
        _addSyncStatus('❌ Connection failed: ${_woocommerceClient.lastError}');
        return;
      }

      _addSyncStatus('✅ Connected to WooCommerce API');

      // Get orders from WooCommerce
      final ordersJson = await _woocommerceClient.getCustomerOrders(
        _customerId!,
      );

      if (ordersJson.isEmpty) {
        _addSyncStatus('ℹ️ No orders found for customer $_customerId');
        _lastSyncTime = DateTime.now();
        return;
      }

      _addSyncStatus('📦 Found ${ordersJson.length} orders, processing...');

      // Process each order for loyalty points
      int processedCount = 0;

      for (final orderJson in ordersJson) {
        if (_disposed) break;

        await _processOrderForLoyaltyPoints(orderJson);
        processedCount++;
      }

      final duration = DateTime.now().difference(startTime);
      _addSyncStatus(
        '✅ Sync complete! Processed $processedCount orders (${duration.inMilliseconds}ms)',
      );
      _lastSyncTime = DateTime.now();

      // Sync complete
    } catch (e, stackTrace) {
      _addSyncStatus('❌ Sync error: $e');
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
      final currentStatus = order.status;
      final previousStatus = _orderStatuses[orderId];

      _addSyncStatus(
        'Processing order #${order.orderNumber} (status: $currentStatus)',
      );

      // Check if order is fully processed (completed and already awarded)
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

      // Handle status transitions and new orders
      if (currentStatus == 'completed') {
        if (previousStatus == 'processing') {
          // Status transition: processing -> completed
          // Convert pending points to completed points
          try {
            await _loyaltyService.convertPendingToCompleted(
              orderId,
              'WooCommerce order #${order.orderNumber}',
            );
            _addSyncStatus(
              '🔄 Converted $pointsToAward pending points to completed for order #${order.orderNumber}',
            );
          } catch (e) {
            // If no pending transaction found, add as new completed order
            _addSyncStatus(
              'No pending points found, adding as new completed order #${order.orderNumber}',
            );
            await _loyaltyService.addPointsFromPurchase(
              orderTotal,
              orderId,
              'WooCommerce order #${order.orderNumber}',
            );
            _addSyncStatus(
              'Awarded $pointsToAward points for order #${order.orderNumber}',
            );
          }
        } else {
          // New completed order (no previous status or wasn't processing)
          await _loyaltyService.addPointsFromPurchase(
            orderTotal,
            orderId,
            'WooCommerce order #${order.orderNumber}',
          );
          _addSyncStatus(
            'Awarded $pointsToAward points for order #${order.orderNumber}',
          );
        }

        // Mark order as fully processed
        _processedOrders.add(orderId);
      } else if (currentStatus == 'processing') {
        if (previousStatus != 'processing') {
          // New processing order or status change to processing
          await _loyaltyService.addPendingPointsFromPurchase(
            orderTotal,
            orderId,
            'WooCommerce order #${order.orderNumber} (Processing)',
          );
          _addSyncStatus(
            'Added $pointsToAward pending points for order #${order.orderNumber}',
          );
        } else {
          // Order is still processing, no change needed
          _addSyncStatus(
            'Order #${order.orderNumber} still processing, no action needed',
          );
        }
      } else {
        _addSyncStatus(
          'Order #${order.orderNumber} status ($currentStatus) not eligible for points',
        );
      }

      // Update order status tracking
      _orderStatuses[orderId] = currentStatus;
    } catch (e) {
      _addSyncStatus('Error processing order: $e');
      print('Error processing order for loyalty points: $e');
    }
  }

  /// Alias for syncWooCommerceOrders to match method name being called in the code
  Future<void> syncPoints() async {
    return syncWooCommerceOrders();
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
