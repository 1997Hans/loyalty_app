import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loyalty_app/core/common/widgets/simple_glass_card.dart';
import 'package:loyalty_app/features/loyalty/domain/blocs/loyalty_bloc.dart';
import 'package:loyalty_app/features/loyalty/domain/models/loyalty_points.dart';
import 'package:loyalty_app/features/loyalty/ui/screens/loyalty_points_screen.dart';

class LoyaltyPointsWidget extends StatelessWidget {
  const LoyaltyPointsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoyaltyBloc, LoyaltyState>(
      builder: (context, state) {
        if (state is LoyaltyLoading) {
          return _buildLoadingCard();
        } else if (state is LoyaltyLoaded) {
          return _buildPointsCard(context, state.points);
        }
        
        // Initial or error state
        return _buildEmptyCard(context);
      },
    );
  }

  Widget _buildLoadingCard() {
    return SimpleGlassCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Loyalty Points',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          const Center(
            child: CircularProgressIndicator(),
          ),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context) {
    return SimpleGlassCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Loyalty Points',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Sign in to view your loyalty points',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16.0),
          Center(
            child: ElevatedButton(
              onPressed: () {
                // Trigger loading loyalty data
                context.read<LoyaltyBloc>().add(LoadLoyaltyData());
              },
              child: const Text('Load Points'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard(BuildContext context, LoyaltyPoints points) {
    return SimpleGlassCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Loyalty Points',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoyaltyPointsScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              const Icon(
                Icons.stars,
                color: Colors.amber,
                size: 32,
              ),
              const SizedBox(width: 16.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${points.currentPoints} pts',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Value: ${points.pointsValueFormatted}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (points.pendingPoints > 0) ...[
            const SizedBox(height: 8.0),
            Text(
              'Pending: ${points.pendingPoints} pts',
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
} 