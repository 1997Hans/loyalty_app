import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loyalty_app/core/common/widgets/dinarys_logo.dart';
import 'package:loyalty_app/core/common/widgets/simple_glass_card.dart';
import 'package:loyalty_app/core/constants/app_config.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';
import 'package:loyalty_app/core/utils/gradient_background.dart';
import 'package:loyalty_app/features/loyalty/domain/models/loyalty_level.dart';
import 'package:loyalty_app/features/loyalty/domain/models/loyalty_transaction.dart';
import 'package:loyalty_app/features/loyalty/domain/blocs/loyalty_bloc.dart'
    as domain_bloc;
import 'package:loyalty_app/features/loyalty/ui/screens/loyalty_points_screen.dart';
import 'package:loyalty_app/features/loyalty/ui/widgets/loyalty_points_widget.dart';
import 'package:loyalty_app/core/services/notification_service.dart';
import 'package:loyalty_app/features/loyalty/bloc/loyalty_bloc.dart' as bloc;
import 'package:loyalty_app/features/loyalty/domain/models/loyalty_points.dart';
import 'package:loyalty_app/features/loyalty/domain/models/points_transaction.dart';
import 'package:loyalty_app/features/loyalty/ui/screens/points_redemption_screen.dart';
import 'package:loyalty_app/features/loyalty/ui/widgets/loyalty_card.dart';
import 'package:loyalty_app/features/loyalty/ui/widgets/loyalty_transaction_item.dart';

class LoyaltyDashboardScreen extends StatefulWidget {
  const LoyaltyDashboardScreen({super.key});

  @override
  State<LoyaltyDashboardScreen> createState() => _LoyaltyDashboardScreenState();
}

class _LoyaltyDashboardScreenState extends State<LoyaltyDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Set context for the bloc on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<bloc.LoyaltyBloc>().add(bloc.SetContext(context));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loyalty Dashboard')),
      body: BlocListener<bloc.LoyaltyBloc, bloc.LoyaltyState>(
        listener: (context, state) {
          // Safe null checks for all state properties
          final status = state?.status;
          final redemptionStatus = state?.redemptionStatus;
          final lastTransaction = state?.lastRedeemedTransaction;
          final errorMsg = state?.errorMessage;

          // Error notifications
          if (status == bloc.LoyaltyStatus.error && errorMsg != null) {
            NotificationService().showRedemptionFailureNotification(
              context,
              errorMsg,
            );
          }

          // Success notifications
          if (redemptionStatus == bloc.RedemptionStatus.success &&
              lastTransaction != null) {
            final transaction = lastTransaction;
            final rewardTitle =
                transaction.metadata['reward_title'] ?? 'Reward';
            final valueStr = transaction.metadata['value'] ?? '0';
            final value = double.tryParse(valueStr) ?? 0.0;

            NotificationService().showRedemptionConfirmationNotification(
              context,
              rewardTitle,
              transaction.points.abs(),
              value,
            );

            context.read<bloc.LoyaltyBloc>().add(
              const bloc.ClearRedemptionStatus(),
            );
          }

          // Check for expiring points
          context.read<bloc.LoyaltyBloc>().add(
            const bloc.CheckExpiringPoints(),
          );
        },
        child: BlocBuilder<bloc.LoyaltyBloc, bloc.LoyaltyState>(
          builder: (context, state) {
            if (state == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final status = state.status;
            final points = state.loyaltyPoints;

            final isLoading =
                status == bloc.LoyaltyStatus.initial ||
                (status == bloc.LoyaltyStatus.loading && points == null);

            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final loyaltyPoints = points;
            if (loyaltyPoints == null) {
              return const Center(child: Text('No loyalty data available'));
            }

            return _DashboardContent(
              loyaltyPoints: loyaltyPoints,
              transactions: state.transactions ?? [],
            );
          },
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final LoyaltyPoints loyaltyPoints;
  final List<PointsTransaction> transactions;

  const _DashboardContent({
    required this.loyaltyPoints,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoyaltyCard(
            currentPoints: loyaltyPoints.currentPoints,
            pointsValue: loyaltyPoints.currentValuePHP,
            onPointsDetailsTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoyaltyPointsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Redeem Points', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildRedemptionOptions(context, loyaltyPoints),
          const SizedBox(height: 24),
          Text(
            'Recent Transactions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildRecentTransactions(context, transactions),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoyaltyPointsScreen(),
                  ),
                );
              },
              child: const Text('View All Transactions'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedemptionOptions(
    BuildContext context,
    LoyaltyPoints loyaltyPoints,
  ) {
    final optionsList = [
      _RedemptionOption(
        title: 'Free Delivery',
        points: 100,
        value: 10.0,
        icon: Icons.local_shipping,
      ),
      _RedemptionOption(
        title: '₱50 Discount',
        points: 500,
        value: 50.0,
        icon: Icons.money_off,
      ),
      _RedemptionOption(
        title: '₱100 Discount',
        points: 1000,
        value: 100.0,
        icon: Icons.money_off,
      ),
      _RedemptionOption(
        title: 'Special Item',
        points: 2500,
        value: 250.0,
        icon: Icons.card_giftcard,
      ),
    ];

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: optionsList.length,
        itemBuilder: (context, index) {
          final option = optionsList[index];
          final canRedeem = loyaltyPoints.currentPoints >= option.points;

          return GestureDetector(
            onTap:
                canRedeem
                    ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => PointsRedemptionScreen(
                                availablePoints: loyaltyPoints.currentPoints,
                              ),
                        ),
                      );
                    }
                    : null,
            child: Container(
              width: 150,
              margin: EdgeInsets.only(
                right: index < optionsList.length - 1 ? 12 : 0,
              ),
              child: Card(
                elevation: 3,
                color: canRedeem ? null : Colors.grey.shade200,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        option.icon,
                        color:
                            canRedeem
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        option.title,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: canRedeem ? null : Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${option.points} points',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              canRedeem
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Value: ₱${option.value.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: canRedeem ? null : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentTransactions(
    BuildContext context,
    List<PointsTransaction> transactions,
  ) {
    final recentTransactions = transactions.take(3).toList();

    if (recentTransactions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('No transactions yet')),
        ),
      );
    }

    return Column(
      children:
          recentTransactions.map((transaction) {
            return LoyaltyTransactionItem(transaction: transaction);
          }).toList(),
    );
  }
}

/// Redemption option data class
class _RedemptionOption {
  final String title;
  final int points;
  final double value;
  final IconData icon;

  const _RedemptionOption({
    required this.title,
    required this.points,
    required this.value,
    required this.icon,
  });
}
