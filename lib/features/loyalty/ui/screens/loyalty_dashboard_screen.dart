import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loyalty_app/core/common/widgets/dinarys_logo.dart';
import 'package:loyalty_app/core/common/widgets/simple_glass_card.dart';
import 'package:loyalty_app/core/constants/app_config.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';
import 'package:loyalty_app/core/utils/gradient_background.dart';
import 'package:loyalty_app/features/loyalty/domain/models/loyalty_level.dart';
import 'package:loyalty_app/features/loyalty/domain/models/loyalty_transaction.dart';
import 'package:loyalty_app/features/loyalty/domain/blocs/loyalty_bloc.dart';
import 'package:loyalty_app/features/loyalty/ui/screens/loyalty_points_screen.dart';
import 'package:loyalty_app/features/loyalty/ui/widgets/loyalty_points_widget.dart';

class LoyaltyDashboardScreen extends StatelessWidget {
  const LoyaltyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = LoyaltyTransaction.getMockTransactions();
    final loyaltyLevel = LoyaltyLevel.platinum();

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Welcome Section
                  _buildWelcomeSection(),
                  const SizedBox(height: 30),

                  // Current Level Section
                  _buildCurrentLevelSection(context, loyaltyLevel),
                  const SizedBox(height: 20),

                  // Add the loyalty points widget before the cashback card
                  const SizedBox(height: 24.0),
                  const LoyaltyPointsWidget(),
                  
                  const SizedBox(height: 24.0),
                  // Cashback Section
                  _buildCashbackSection(context),
                  const SizedBox(height: 20),

                  // Add rewards section after user levels
                  const SizedBox(height: 24.0),
                  _buildRewardsSection(context),
                  
                  // Add proper spacing between Redeem Points and History sections
                  const SizedBox(height: 32.0),

                  // History Section
                  _buildHistorySection(context, transactions),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Row(
      children: [
        const DinarysLogo(),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
          color: Colors.white,
        ),
      ],
    );
  }

  Widget _buildCurrentLevelSection(BuildContext context, LoyaltyLevel level) {
    return Row(
      children: [
        const BackButton(color: Colors.white),
        const Text(
          'Current level',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCashbackSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cashback',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),

        // Cashback Balance Card
        SimpleGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '${AppConfig.currencySymbol}525,681',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Platinum',
                    style: TextStyle(
                      color: AppTheme.platinumColor,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '№ 111 235 532',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(), // Empty spacer
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoyaltyPointsScreen(),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            const Text(
                              'View Points',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.blue.shade200,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          // Show level details
                        },
                        child: Text(
                          'User levels details',
                          style: TextStyle(
                            color: Colors.blue.shade200,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Cashback Level Card
        SimpleGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cashback level',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.platinumColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                        AppTheme.smallBorderRadius,
                      ),
                    ),
                    child: const Text(
                      'Platinum',
                      style: TextStyle(
                        color: AppTheme.platinumColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'From 09/20',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '№ 111 235 532',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Cashback Percentages
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCashbackRateItem(
                    icon: Icons.shopping_bag_outlined,
                    rate: '10%',
                    label: 'For goods',
                  ),
                  _buildCashbackRateItem(
                    icon: Icons.support_agent,
                    rate: '15%',
                    label: 'For services',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Achievement Criteria
              _buildAchievementItem(
                icon: Icons.circle,
                iconColor: Colors.green,
                text: 'Purchase of equipment from Dinarys B2B',
                progress: 0.6,
              ),

              const SizedBox(height: 16),

              _buildAchievementItem(
                icon: Icons.emoji_events,
                iconColor: Colors.amber,
                text:
                    'Purchase of goods and services worth more than ${AppConfig.currencySymbol}10,000,000 within 3 years',
                progress: 0.3,
              ),

              const SizedBox(height: 24),

              // Ruby Level Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(
                    AppTheme.smallBorderRadius,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Ruby level',
                      style: TextStyle(
                        color: AppTheme.rubyColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.keyboard_arrow_down, color: AppTheme.rubyColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection(
    BuildContext context,
    List<LoyaltyTransaction> transactions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                const Text(
                  'October',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white70,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Transaction List
        ...transactions.map(
          (transaction) => _buildTransactionItem(transaction),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(LoyaltyTransaction transaction) {
    final IconData icon;
    final Color iconBgColor;

    switch (transaction.title) {
      case 'Spare parts':
        icon = Icons.settings;
        iconBgColor = Colors.purple;
        break;
      case 'Light':
        icon = Icons.flash_on;
        iconBgColor = Colors.amber;
        break;
      case 'Consulting':
        icon = Icons.support_agent;
        iconBgColor = Colors.blue;
        break;
      default:
        icon = Icons.monetization_on;
        iconBgColor = Colors.green;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: SimpleGlassCard(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.formattedDate,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              transaction.amountFormatted,
              style: TextStyle(
                color: transaction.isPositive ? Colors.green : Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashbackRateItem({
    required IconData icon,
    required String rate,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rate,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAchievementItem({
    required IconData icon,
    required Color iconColor,
    required String text,
    required double progress,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRewardsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Redeem Your Points',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildRewardOption(
                context,
                'Discount Voucher',
                '200 pts',
                '₱50 off',
                Icons.local_offer,
                Colors.orangeAccent,
              ),
              const SizedBox(width: 12),
              _buildRewardOption(
                context,
                'Free Delivery',
                '350 pts',
                'On your next order',
                Icons.delivery_dining,
                Colors.greenAccent,
              ),
              const SizedBox(width: 12),
              _buildRewardOption(
                context,
                'Cash Rebate',
                '500 pts',
                '₱100 cashback',
                Icons.attach_money,
                Colors.purpleAccent,
              ),
              const SizedBox(width: 12),
              _buildRewardOption(
                context,
                'Premium Status',
                '1000 pts',
                '30 days of VIP benefits',
                Icons.star,
                Colors.amberAccent,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRewardOption(
    BuildContext context,
    String title,
    String points,
    String description,
    IconData icon,
    Color color,
  ) {
    // Extract points value from string (e.g., "200 pts" -> 200)
    final pointsValue = int.parse(points.split(' ')[0]);
    
    return SimpleGlassCard(
      width: 150,
      // Increase height to prevent overflow
      height: 210,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            radius: 20,
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            points,
            style: const TextStyle(
              color: Colors.amberAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Center(
            child: BlocBuilder<LoyaltyBloc, LoyaltyState>(
              builder: (context, state) {
                bool isEnoughPoints = false;
                
                if (state is LoyaltyLoaded) {
                  isEnoughPoints = state.points.currentPoints >= pointsValue;
                }
                
                return SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: ElevatedButton(
                    onPressed: isEnoughPoints ? () {
                      // Use RedeemPoints event
                      context.read<LoyaltyBloc>().add(
                        RedeemPoints(
                          rewardTitle: title,
                          pointsRequired: pointsValue,
                          rewardDescription: description,
                        ),
                      );
                      
                      // Show a snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Redeeming $title for $points'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } : null, // Disable if not enough points
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEnoughPoints ? color.withOpacity(0.8) : Colors.grey.withOpacity(0.5),
                      // Optimize padding to fit better
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(double.infinity, 30),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: Text(isEnoughPoints ? 'Redeem' : 'Not Enough'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
