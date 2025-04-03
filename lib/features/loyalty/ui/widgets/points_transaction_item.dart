import 'package:flutter/material.dart';
import 'package:loyalty_app/core/common/widgets/simple_glass_card.dart';
import 'package:loyalty_app/features/loyalty/domain/models/points_transaction.dart';

class PointsTransactionItem extends StatelessWidget {
  final PointsTransaction transaction;

  const PointsTransactionItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return SimpleGlassCard(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          _buildTransactionIcon(),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  transaction.formattedDate,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (transaction.orderId != null) ...[
                  const SizedBox(height: 4.0),
                  Text(
                    'Order: ${transaction.orderId}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
                if (transaction.status != TransactionStatus.completed) ...[
                  const SizedBox(height: 4.0),
                  Text(
                    'Status: ${transaction.status.toString().split('.').last}',
                    style: TextStyle(
                      color: _getStatusColor(transaction.status),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transaction.pointsFormatted,
                style: TextStyle(
                  color: _getPointsColor(),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (transaction.purchaseAmount != null) ...[
                const SizedBox(height: 4.0),
                Text(
                  transaction.valueFormatted,
                  style: TextStyle(
                    color: _getPointsColor().withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getIconBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(_getTransactionIcon(), color: Colors.white, size: 20),
    );
  }

  IconData _getTransactionIcon() {
    switch (transaction.type) {
      case PointsTransactionType.purchase:
        return Icons.shopping_cart;
      case PointsTransactionType.redemption:
        return Icons.redeem;
      case PointsTransactionType.expired:
        return Icons.access_time;
      case PointsTransactionType.adjustment:
        return Icons.sync;
      case PointsTransactionType.bonus:
        return Icons.stars;
    }
  }

  Color _getIconBackgroundColor() {
    switch (transaction.type) {
      case PointsTransactionType.purchase:
        return Colors.green;
      case PointsTransactionType.redemption:
        return Colors.blue;
      case PointsTransactionType.expired:
        return Colors.red;
      case PointsTransactionType.adjustment:
        return transaction.isEarning ? Colors.purple : Colors.orange;
      case PointsTransactionType.bonus:
        return Colors.amber;
    }
  }

  Color _getPointsColor() {
    if (transaction.isEarning) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return Colors.amber;
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.canceled:
        return Colors.grey;
    }
  }
}
