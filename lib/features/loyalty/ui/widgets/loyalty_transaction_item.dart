import 'package:flutter/material.dart';
import 'package:loyalty_app/core/config/app_config.dart';
import 'package:loyalty_app/features/loyalty/domain/models/points_transaction.dart';

/// A widget that displays a single loyalty transaction
class LoyaltyTransactionItem extends StatelessWidget {
  final PointsTransaction transaction;

  const LoyaltyTransactionItem({Key? key, required this.transaction})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildTransactionIcon(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(transaction.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (transaction.status != TransactionStatus.completed)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        transaction.statusText,
                        style: TextStyle(
                          fontSize: 10,
                          color: _getStatusColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction.pointsFormatted,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: transaction.isEarning ? Colors.green : Colors.blue,
                  ),
                ),
                Text(
                  '₱${_calculateValue(transaction.points).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionIcon() {
    Color iconColor;
    IconData iconData;

    switch (transaction.type) {
      case TransactionType.purchase:
        iconColor = Colors.green;
        iconData = Icons.shopping_cart;
        break;
      case TransactionType.redemption:
        iconColor = Colors.blue;
        iconData = Icons.redeem;
        break;
      case TransactionType.bonus:
        iconColor = Colors.amber;
        iconData = Icons.stars;
        break;
      case TransactionType.adjustment:
        iconColor = Colors.purple;
        iconData = Icons.build;
        break;
      case TransactionType.expiration:
        iconColor = Colors.red;
        iconData = Icons.access_time;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  Color _getStatusColor() {
    switch (transaction.status) {
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.cancelled:
        return Colors.red;
      case TransactionStatus.failed:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  double _calculateValue(int points) {
    return points.abs() * AppConfig.pointValueInPHP;
  }
}
