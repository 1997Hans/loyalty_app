import 'package:flutter/material.dart';
import 'package:loyalty_app/core/common/widgets/dinarys_logo.dart';
import 'package:loyalty_app/core/common/widgets/simple_glass_card.dart';
import 'package:loyalty_app/core/constants/app_config.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';
import 'package:loyalty_app/core/utils/gradient_background.dart';
import 'package:loyalty_app/features/loyalty/domain/models/loyalty_level.dart';
import 'package:loyalty_app/features/loyalty/domain/models/loyalty_transaction.dart';

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

                  // Cashback Section
                  _buildCashbackSection(context),
                  const SizedBox(height: 20),

                  // History Section
                  _buildHistorySection(context, transactions),
                  const SizedBox(height: 30),

                  // Bottom Navigation
                  _buildBottomNavigation(),
                  const SizedBox(height: 20),
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
                  Text(
                    'User levels details',
                    style: TextStyle(
                      color: Colors.blue.shade200,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
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

  Widget _buildBottomNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildNavItem(Icons.home, isSelected: true),
        _buildNavItem(Icons.account_balance_wallet),
        _buildNavItem(Icons.shopping_bag),
        _buildNavItem(Icons.more_horiz),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}
