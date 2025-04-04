import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loyalty_app/core/utils/gradient_background.dart';
import 'package:loyalty_app/features/loyalty/bloc/loyalty_bloc.dart';
import 'package:loyalty_app/features/loyalty/domain/models/points_transaction.dart';

class RedemptionHistoryScreen extends StatefulWidget {
  const RedemptionHistoryScreen({super.key});

  @override
  State<RedemptionHistoryScreen> createState() =>
      _RedemptionHistoryScreenState();
}

class _RedemptionHistoryScreenState extends State<RedemptionHistoryScreen> {
  @override
  void initState() {
    super.initState();

    // Load points transactions when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoyaltyBloc>().add(LoadPointsTransactions());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redemption History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GradientBackground(
        child: BlocBuilder<LoyaltyBloc, LoyaltyState>(
          buildWhen:
              (previous, current) =>
                  previous.transactions != current.transactions ||
                  previous.status != current.status,
          builder: (context, state) {
            // Show loading indicator if data is loading
            if (state.status == LoyaltyStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Filter for redemption transactions only
            final redemptionTransactions =
                state.transactions
                    .where(
                      (transaction) =>
                          transaction.type == TransactionType.redemption,
                    )
                    .toList();

            // Show message if no redemptions found
            if (redemptionTransactions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.redeem_outlined,
                      color: Colors.white54,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No redemptions yet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your past redemptions will appear here',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Return to previous screen
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Go Back'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Show list of redemption transactions
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: redemptionTransactions.length,
              itemBuilder: (context, index) {
                return RedemptionHistoryItem(
                  transaction: redemptionTransactions[index],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class RedemptionHistoryItem extends StatelessWidget {
  final PointsTransaction transaction;

  const RedemptionHistoryItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    // Extract reward information from transaction metadata
    final rewardTitle = transaction.metadata['reward_title'] ?? 'Reward';
    final valueStr = transaction.metadata['value'] ?? '0';
    final value = double.tryParse(valueStr) ?? 0.0;
    final couponCode = transaction.metadata['coupon_code'] ?? 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.redeem, color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rewardTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatDate(transaction.createdAt),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${transaction.points.abs()} pts',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 24),
            _buildInfoRow(
              title: 'Value',
              value: '₱${value.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              title: 'Coupon Code',
              value: couponCode,
              isCouponCode: true,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              title: 'Status',
              value: transaction.statusText,
              statusColor: _getStatusColor(transaction.status),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String title,
    required String value,
    Color? statusColor,
    bool isCouponCode = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        isCouponCode
            ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.amber.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.copy_outlined,
                    color: Colors.amber,
                    size: 14,
                  ),
                ],
              ),
            )
            : Text(
              value,
              style: TextStyle(
                color: statusColor ?? Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
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
}
