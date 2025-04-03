import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loyalty_app/core/common/widgets/simple_glass_card.dart';
import 'package:loyalty_app/core/constants/app_config.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';
import 'package:loyalty_app/core/utils/gradient_background.dart';
import 'package:loyalty_app/core/services/notification_service.dart';
import 'package:loyalty_app/features/loyalty/bloc/loyalty_bloc.dart';
import 'package:loyalty_app/features/loyalty/domain/models/loyalty_points.dart';
import 'package:loyalty_app/features/loyalty/domain/models/points_transaction.dart';
import 'package:loyalty_app/features/loyalty/ui/screens/points_redemption_screen.dart';
import 'package:loyalty_app/features/loyalty/ui/screens/woocommerce_sync_screen.dart';
import 'package:loyalty_app/features/loyalty/ui/widgets/points_transaction_item.dart';
import 'package:loyalty_app/features/loyalty/ui/widgets/loyalty_transaction_item.dart'
    as loyalty;
import 'package:loyalty_app/features/loyalty/ui/widgets/points_summary_card.dart';

class LoyaltyPointsScreen extends StatefulWidget {
  const LoyaltyPointsScreen({super.key});

  @override
  State<LoyaltyPointsScreen> createState() => _LoyaltyPointsScreenState();
}

class _LoyaltyPointsScreenState extends State<LoyaltyPointsScreen> {
  @override
  void initState() {
    super.initState();
    // Load fresh data when screen is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoyaltyBloc>().add(LoadPointsTransactions());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Loyalty Points'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: GradientBackground(
        child: BlocBuilder<LoyaltyBloc, LoyaltyState>(
          builder: (context, state) {
            print('LoyaltyPointsScreen: Building with state ${state.status}');

            if (state.status == LoyaltyStatus.error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.errorMessage ?? 'An error occurred',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<LoyaltyBloc>().add(
                          LoadPointsTransactions(),
                        );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Show a proper UI for no points yet, instead of creating dummy points
            if (state.loyaltyPoints == null) {
              // Create a default empty LoyaltyPoints object instead of showing "No Points History" message
              final emptyPoints = LoyaltyPoints.initial();

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<LoyaltyBloc>().add(LoadPointsTransactions());
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: _buildContent(context, state, emptyPoints),
              );
            }

            // We have real points data, use it directly
            return RefreshIndicator(
              onRefresh: () async {
                context.read<LoyaltyBloc>().add(LoadPointsTransactions());
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: _buildContent(context, state, state.loyaltyPoints!),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    LoyaltyState state,
    LoyaltyPoints points,
  ) {
    final transactions = state.transactions ?? [];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPointsBalanceCard(context, points),
          const SizedBox(height: 24),
          _buildExpiringPointsCard(context, points),
          const SizedBox(height: 24),
          _buildTransactionHistory(context, transactions),
        ],
      ),
    );
  }

  Widget _buildPointsBalanceCard(BuildContext context, LoyaltyPoints points) {
    return SimpleGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Points Balance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.stars, color: Colors.amber, size: 40),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${points.currentPoints}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Value: ${points.pointsValueFormatted}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Lifetime Points',
                points.lifetimePoints.toString(),
                '₱${points.lifetimeValuePHP.toStringAsFixed(2)}',
              ),
              _buildStatItem(
                'Redeemed Points',
                points.redeemedPoints.toString(),
                '₱${points.redeemedValuePHP.toStringAsFixed(2)}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (points.pendingPoints > 0)
            _buildStatItem(
              'Pending Points',
              points.pendingPoints.toString(),
              'Will be added soon',
              icon: Icons.hourglass_top,
              iconColor: Colors.amber,
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    String subtext, {
    IconData? icon,
    Color? iconColor,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: iconColor ?? Colors.white70, size: 16),
          const SizedBox(width: 8),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtext,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpiringPointsCard(BuildContext context, LoyaltyPoints points) {
    final expiringPoints = (points.currentPoints * 0.1).round();

    return SimpleGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expiring Points',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.access_time, color: Colors.amber, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expiringPoints > 0
                          ? '$expiringPoints points expiring in 30 days'
                          : 'No points expiring soon',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Redeem your points before they expire to get maximum benefits',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory(
    BuildContext context,
    List<PointsTransaction> transactions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transaction History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (transactions.isEmpty)
          SimpleGlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.history, color: Colors.white54, size: 36),
                  const SizedBox(height: 12),
                  const Text(
                    'No transactions yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Transactions will appear here after you make purchases',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          for (int i = 0; i < transactions.length; i++) ...[
            loyalty.LoyaltyTransactionItem(transaction: transactions[i]),
            if (i < transactions.length - 1) const SizedBox(height: 8),
          ],
      ],
    );
  }
}
