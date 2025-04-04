import 'dart:async';

import 'package:loyalty_app/core/config/app_config.dart';
import 'package:loyalty_app/features/loyalty/api/woocommerce_client.dart';
import 'package:loyalty_app/features/loyalty/domain/models/points_transaction.dart';
import 'package:loyalty_app/features/loyalty/domain/models/woocommerce_order.dart';
import 'package:loyalty_app/features/loyalty/domain/services/loyalty_service.dart';

/// Service for synchronizing WooCommerce orders and processing loyalty points
class WooCommerceSyncService {
  final WooCommerceClient _wooCommerceClient;
  final LoyaltyService _loyaltyService;

  // Store customer ID for WooCommerce API
  String? _customerId;
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
  bool get isAutomaticSyncEnabled => true;
  bool get isSyncing => _isSyncing;
  String? get customerId => _customerId;

  // Set customer ID
  set customerId(String? id) {
    _customerId = id;
    if (id != null) {
      _addSyncStatus('Customer ID updated to: $id');
      // Automatically start sync whenever customer ID is set
      startBackgroundSync(syncInterval: const Duration(minutes: 5));
    } else {
      _addSyncStatus('Customer ID cleared');
      stopBackgroundSync();
    }
  }

  WooCommerceSyncService({
    required WooCommerceClient wooCommerceClient,
    required LoyaltyService loyaltyService,
    String? customerId,
  }) : _wooCommerceClient = wooCommerceClient,
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

  /// Sync WooCommerce orders
  Future<void> syncWooCommerceOrders() async {
    if (_disposed || _customerId == null || _customerId == '') {
      _addSyncStatus('No customer ID set, skipping sync');
      return;
    }

    if (_isSyncing) {
      _addSyncStatus('Sync already in progress, skipping');
      return;
    }

    try {
      _isSyncing = true;
      _addSyncStatus('Starting sync for customer ID: $_customerId');

      // Get orders from WooCommerce
      final int customerIdInt = int.parse(_customerId!);
      final orders = await _wooCommerceClient.getCustomerOrders(customerIdInt);
      _addSyncStatus('Found ${orders.length} orders');

      // Process each order
      for (final order in orders) {
        await _processOrderForLoyaltyPoints(order);
      }

      _addSyncStatus('Sync completed successfully');
      _syncStatusController.add(
        'Sync completed at ${DateTime.now().toIso8601String()}',
      );
    } catch (e) {
      _addSyncStatus('Error syncing orders: $e');
      print('Error syncing WooCommerce orders: $e');
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

      // Calculate points based on order total and configured points per amount
      final orderTotal = order.total;
      final pointsToAward =
          (orderTotal * AppConfig.woocommercePointsPerAmount).round();

      if (pointsToAward <= 0) {
        _addSyncStatus('No points to award for order #${order.orderNumber}');
        return;
      }

      // Track whether the order has been processed for this status
      final statusKey = '${orderId}_${order.status}';

      // Process based on order status
      if (order.status == 'completed') {
        // Check if this was previously a processing order with pending points
        final processingStatusKey = '${orderId}_processing';

        if (_processedOrders.contains(processingStatusKey)) {
          // This order was previously in processing status
          // We should confirm the pending points
          await _confirmPendingPointsForOrder(order, pointsToAward);

          // Remove the processing status key
          _processedOrders.remove(processingStatusKey);

          // Add the completed status key
          _processedOrders.add(statusKey);

          _addSyncStatus(
            'Confirmed $pointsToAward pending points for order #${order.orderNumber}',
          );
          return;
        }

        // Only process completed orders that haven't been processed before
        if (_processedOrders.contains(orderId)) {
          _addSyncStatus(
            'Order #${order.orderNumber} already processed as completed, skipping',
          );
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
      } else if (order.status == 'processing') {
        // Only add pending points once per processing order
        if (_processedOrders.contains(statusKey)) {
          _addSyncStatus(
            'Pending points already added for order #${order.orderNumber}, skipping',
          );
          return;
        }

        // Add pending points for processing orders
        await _addPendingPointsForOrder(order, pointsToAward);

        // Mark this status as processed for this order
        _processedOrders.add(statusKey);
        _addSyncStatus(
          'Added $pointsToAward pending points for order #${order.orderNumber}',
        );
      } else {
        _addSyncStatus(
          'Order #${order.orderNumber} status (${order.status}) not eligible for points',
        );
      }
    } catch (e) {
      _addSyncStatus('Error processing order: $e');
      print('Error processing order for loyalty points: $e');
    }
  }

  /// Confirm pending points for an order that has changed from processing to completed
  Future<void> _confirmPendingPointsForOrder(
    WooCommerceOrder order,
    int pointsToConfirm,
  ) async {
    try {
      // Get all transactions to find the pending transaction
      final transactions = await _loyaltyService.getTransactions();

      // Find the pending transaction for this order
      final pendingTransaction = transactions.firstWhere(
        (t) =>
            t.status == TransactionStatus.pending &&
            t.metadata['order_id'] == order.id.toString(),
        orElse:
            () =>
                throw Exception(
                  'No pending transaction found for order ${order.id}',
                ),
      );

      // Confirm the pending points
      await _loyaltyService.confirmPendingTransaction(
        pendingTransaction.id,
        pointsToConfirm,
      );
    } catch (e) {
      print('Error confirming pending points: $e');
      _addSyncStatus('Failed to confirm pending points: $e');
    }
  }

  /// Add pending points for an order in processing status
  Future<void> _addPendingPointsForOrder(
    WooCommerceOrder order,
    int pointsToAward,
  ) async {
    try {
      // Get current points
      final currentPoints = await _loyaltyService.getLoyaltyPoints();

      // Add pending points to the loyalty points
      final updatedPoints = currentPoints.addPendingPoints(pointsToAward);

      // Create a pending transaction record
      final transaction = PointsTransaction(
        id: 'pending_${order.id}_${DateTime.now().millisecondsSinceEpoch}',
        type: TransactionType.purchase,
        points: pointsToAward,
        description:
            'Pending: +$pointsToAward pts from order #${order.orderNumber}',
        createdAt: DateTime.now(),
        status: TransactionStatus.pending,
        metadata: {
          'order_id': order.id.toString(),
          'amount': order.total.toString(),
          'order_status': 'processing',
          'pending_points': pointsToAward.toString(),
        },
      );

      // Add the transaction to repository
      await _loyaltyService.addPendingTransaction(transaction, updatedPoints);
    } catch (e) {
      print('Error adding pending points: $e');
      _addSyncStatus('Failed to add pending points: $e');
    }
  }

  /// Alias for syncWooCommerceOrders to match method name being called in the code
  Future<void> syncPoints() async {
    return syncWooCommerceOrders();
  }

  /// Cancel all pending operations and clear state when user logs out
  void cancelPendingOperations() {
    if (_isSyncing) {
      _addSyncStatus('Cancelling current sync operation');
      _isSyncing = false;
    }

    // Cancel any timers
    _syncTimer?.cancel();
    _syncTimer = null;

    // Clear processed orders set
    _processedOrders.clear();

    _addSyncStatus('All pending operations cancelled');
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
