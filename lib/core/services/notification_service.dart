import 'package:flutter/material.dart';
import 'package:loyalty_app/features/loyalty/domain/models/loyalty_points.dart';
import 'package:loyalty_app/features/loyalty/domain/models/points_transaction.dart';

/// Service to handle notifications for the loyalty app
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// Show a notification for points update
  void showPointsUpdateNotification(
    BuildContext context,
    PointsTransaction transaction,
  ) {
    final isEarning = transaction.isEarning;
    final color = isEarning ? Colors.green : Colors.blue;
    final icon = isEarning ? Icons.arrow_upward : Icons.redeem;
    final title = isEarning ? 'Points Earned' : 'Points Redeemed';

    _showNotification(
      context: context,
      title: title,
      message: '${transaction.description}: ${transaction.pointsFormatted}',
      color: color,
      icon: icon,
    );
  }

  /// Show a notification for points about to expire
  void showExpiringPointsNotification(
    BuildContext context,
    int expiringPoints,
  ) {
    if (expiringPoints <= 0) return;

    _showNotification(
      context: context,
      title: 'Points Expiring Soon',
      message: '$expiringPoints points will expire within 30 days',
      color: Colors.orange,
      icon: Icons.access_time,
    );
  }

  /// Show redemption confirmation notification
  void showRedemptionConfirmationNotification(
    BuildContext context,
    String rewardTitle,
    int pointsRedeemed,
    double value,
  ) {
    _showNotification(
      context: context,
      title: 'Redemption Confirmed',
      message:
          '$rewardTitle redeemed for $pointsRedeemed points (₱${value.toStringAsFixed(2)})',
      color: Colors.green,
      icon: Icons.check_circle,
    );
  }

  /// Show redemption failure notification
  void showRedemptionFailureNotification(
    BuildContext context,
    String errorMessage,
  ) {
    _showNotification(
      context: context,
      title: 'Redemption Failed',
      message: errorMessage,
      color: Colors.red,
      icon: Icons.error,
    );
  }

  /// Show points earned milestone notification
  void showPointsMilestoneNotification(
    BuildContext context,
    LoyaltyPoints points,
  ) {
    // Check if user has reached a milestone (e.g., 5000, 10000 points)
    final milestones = [5000, 10000, 20000, 50000];

    for (final milestone in milestones) {
      if (points.lifetimePoints >= milestone &&
          points.lifetimePoints - points.pendingPoints < milestone) {
        _showNotification(
          context: context,
          title: 'Points Milestone Reached',
          message: 'Congratulations! You\'ve earned $milestone lifetime points',
          color: Colors.purple,
          icon: Icons.emoji_events,
        );
        break;
      }
    }
  }

  /// Show a notification for a special promotion
  void showPromotionNotification(
    BuildContext context,
    String promotionTitle,
    String promotionDescription,
  ) {
    _showNotification(
      context: context,
      title: promotionTitle,
      message: promotionDescription,
      color: Colors.amber,
      icon: Icons.star,
    );
  }

  /// Internal method to show a notification
  void _showNotification({
    required BuildContext context,
    required String title,
    required String message,
    required Color color,
    required IconData icon,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: color,
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    );

    // Clear any existing SnackBars to avoid overlap
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
