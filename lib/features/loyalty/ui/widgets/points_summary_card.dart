import 'package:flutter/material.dart';
import 'package:loyalty_app/features/loyalty/domain/models/loyalty_points.dart';

/// A card that displays a summary of loyalty points
class PointsSummaryCard extends StatelessWidget {
  final LoyaltyPoints loyaltyPoints;

  const PointsSummaryCard({super.key, required this.loyaltyPoints});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Points Summary',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPointsRow(
              context,
              'Current Points',
              loyaltyPoints.currentPoints.toString(),
              '₱${loyaltyPoints.currentValuePHP.toStringAsFixed(2)}',
              Colors.green,
            ),
            const Divider(),
            _buildPointsRow(
              context,
              'Lifetime Points',
              loyaltyPoints.lifetimePoints.toString(),
              '₱${loyaltyPoints.lifetimeValuePHP.toStringAsFixed(2)}',
              Colors.blue,
            ),
            const Divider(),
            _buildPointsRow(
              context,
              'Redeemed Points',
              loyaltyPoints.redeemedPoints.toString(),
              '₱${loyaltyPoints.redeemedValuePHP.toStringAsFixed(2)}',
              Colors.orange,
            ),
            if (loyaltyPoints.pendingPoints > 0) ...[
              const Divider(),
              _buildPointsRow(
                context,
                'Pending Points',
                loyaltyPoints.pendingPoints.toString(),
                'Pending confirmation',
                Colors.grey,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Last updated: ${_formatDateTime(loyaltyPoints.lastUpdated)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsRow(
    BuildContext context,
    String label,
    String points,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                points,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(value, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
