import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loyalty_app/core/common/widgets/simple_glass_card.dart';
import 'package:loyalty_app/core/constants/app_config.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';
import 'package:loyalty_app/core/utils/gradient_background.dart';
import 'package:loyalty_app/features/loyalty/domain/blocs/loyalty_bloc.dart';
import 'package:loyalty_app/features/loyalty/domain/models/points_transaction.dart';
import 'package:loyalty_app/features/loyalty/ui/screens/points_redemption_screen.dart';
import 'package:loyalty_app/features/loyalty/ui/widgets/points_transaction_item.dart';

class LoyaltyPointsScreen extends StatelessWidget {
  const LoyaltyPointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyalty Points'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const GradientBackground(
        child: _LoyaltyPointsContent(),
      ),
    );
  }
}

class _LoyaltyPointsContent extends StatelessWidget {
  const _LoyaltyPointsContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoyaltyBloc, LoyaltyState>(
      builder: (context, state) {
        if (state is LoyaltyLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (state is LoyaltyLoaded) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPointsBalanceCard(context, state),
                  const SizedBox(height: 24.0),
                  _buildExpiringPointsCard(context, state),
                  const SizedBox(height: 24.0),
                  _buildTransactionHistory(context, state),
                ],
              ),
            ),
          );
        } else if (state is LoyaltyError) {
          return Center(
            child: Text(
              'Error: ${state.message}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }
        
        return const Center(
          child: Text(
            'No data available',
            style: TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildPointsBalanceCard(BuildContext context, LoyaltyLoaded state) {
    final points = state.points;
    
    return SimpleGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Points Balance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              const Icon(
                Icons.stars,
                color: Colors.amber,
                size: 40,
              ),
              const SizedBox(width: 16.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${points.currentPoints} pts',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Value: ${points.pointsValueFormatted}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPointsInfoItem(
                'Lifetime',
                '${points.lifetimePoints} pts',
                Icons.history,
              ),
              _buildPointsInfoItem(
                'Redeemed',
                '${points.redeemedPoints} pts',
                Icons.redeem,
              ),
              _buildPointsInfoItem(
                'Pending',
                '${points.pendingPoints} pts',
                Icons.hourglass_empty,
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/rewards', arguments: {
                  'availablePoints': state.points.currentPoints,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 12.0,
                ),
              ),
              child: const Text('Redeem Points'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiringPointsCard(BuildContext context, LoyaltyLoaded state) {
    if (state.expiringPoints <= 0) {
      return const SizedBox.shrink();
    }
    
    return SimpleGlassCard(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.access_time,
              color: Colors.white,
              size: 24.0,
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Points Expiring Soon',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  '${state.expiringPoints} points will expire in 30 days',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory(BuildContext context, LoyaltyLoaded state) {
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
        const SizedBox(height: 16.0),
        ...state.transactions.map((transaction) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: PointsTransactionItem(transaction: transaction),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPointsInfoItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 24.0,
        ),
        const SizedBox(height: 8.0),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
} 