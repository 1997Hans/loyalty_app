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
import 'package:loyalty_app/features/loyalty/ui/screens/woocommerce_sync_screen.dart';
import 'package:loyalty_app/features/auth/bloc/auth_bloc.dart' as auth_bloc;
import 'package:loyalty_app/core/animations/animations.dart';
import 'package:flutter/scheduler.dart';

class LoyaltyDashboardScreen extends StatefulWidget {
  const LoyaltyDashboardScreen({super.key});

  @override
  State<LoyaltyDashboardScreen> createState() => _LoyaltyDashboardScreenState();
}

class _LoyaltyDashboardScreenState extends State<LoyaltyDashboardScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Trigger data loading when screen is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loyaltyBloc = context.read<bloc.LoyaltyBloc>();
      loyaltyBloc.add(bloc.SetContext(context));
      loyaltyBloc.add(bloc.LoadPointsTransactions());
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(title: const Text('Loyalty Dashboard')),
      body: BlocConsumer<bloc.LoyaltyBloc, bloc.LoyaltyState>(
        listener: (context, state) {
          // Safe null checks for all state properties
          final status = state.status;
          final redemptionStatus = state.redemptionStatus;
          final lastTransaction = state.lastRedeemedTransaction;
          final errorMsg = state.errorMessage;

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
        builder: (context, state) {
          // If the state is in an error state, show error message
          if (state.status == bloc.LoyaltyStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage ?? 'An error occurred',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<bloc.LoyaltyBloc>().add(
                        bloc.LoadPointsTransactions(),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Check if no loyalty points are available - this means the user has no points yet
          if (state.loyaltyPoints == null) {
            // Create a default empty LoyaltyPoints object instead of showing "No Points Yet" message
            final emptyPoints = LoyaltyPoints.initial();

            return RefreshIndicator(
              onRefresh: () async {
                context.read<bloc.LoyaltyBloc>().add(
                  bloc.LoadPointsTransactions(),
                );
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeSlideTransition.fromController(
                      controller: AnimationController(
                        vsync: this,
                        duration: const Duration(milliseconds: 600),
                      )..forward(),
                      beginOffset: const Offset(0, 0.2),
                      child: _buildWelcomeHeader(context),
                    ),
                    const SizedBox(height: 24),
                    AnimatedCard(
                      duration: const Duration(milliseconds: 800),
                      child: _buildPointsSummaryCard(context, emptyPoints),
                    ),
                    const SizedBox(height: 24),
                    AnimatedCard(
                      duration: const Duration(milliseconds: 800),
                      beginOpacity: 0.0,
                      beginScale: 0.95,
                      curve: Curves.easeOutQuint,
                      child: _buildQuickRedeemCard(context, emptyPoints),
                    ),
                    const SizedBox(height: 24),
                    AnimatedCard(
                      duration: const Duration(milliseconds: 800),
                      beginOpacity: 0.0,
                      beginScale: 0.95,
                      curve: Curves.easeOutQuint,
                      child: _buildRecentActivityCard(context, state),
                    ),
                  ],
                ),
              ),
            );
          }

          // If we have real points data, use it (no dummy data)
          final points = state.loyaltyPoints!;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<bloc.LoyaltyBloc>().add(
                bloc.LoadPointsTransactions(),
              );
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeSlideTransition.fromController(
                    controller: AnimationController(
                      vsync: this,
                      duration: const Duration(milliseconds: 600),
                    )..forward(),
                    beginOffset: const Offset(0, 0.2),
                    child: _buildWelcomeHeader(context),
                  ),
                  const SizedBox(height: 24),
                  AnimatedCard(
                    duration: const Duration(milliseconds: 800),
                    child: _buildPointsSummaryCard(context, points),
                  ),
                  const SizedBox(height: 24),
                  AnimatedCard(
                    duration: const Duration(milliseconds: 800),
                    beginOpacity: 0.0,
                    beginScale: 0.95,
                    curve: Curves.easeOutQuint,
                    child: _buildQuickRedeemCard(context, points),
                  ),
                  const SizedBox(height: 24),
                  AnimatedCard(
                    duration: const Duration(milliseconds: 800),
                    beginOpacity: 0.0,
                    beginScale: 0.95,
                    curve: Curves.easeOutQuint,
                    child: _buildRecentActivityCard(context, state),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    // Get username from auth bloc if available
    final authState = context.watch<auth_bloc.AuthBloc>().state;
    String username = 'Customer';

    if (authState is auth_bloc.AuthAuthenticated) {
      username =
          authState.user.displayName ?? authState.user.username ?? 'Customer';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome, $username',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Track your rewards and redeem exclusive offers',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildPointsSummaryCard(BuildContext context, LoyaltyPoints points) {
    return SimpleGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Points',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.stars, color: Colors.amber, size: 36),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedCounter(
                      value: points.currentPoints,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Value: ₱${points.currentValuePHP.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white70,
                    size: 18,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoyaltyPointsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPointsInfoItem(
                  'Lifetime',
                  '${points.lifetimePoints}',
                  Icons.history,
                ),
                _buildPointsInfoItem(
                  'Redeemed',
                  '${points.redeemedPoints}',
                  Icons.redeem,
                ),
                if (points.pendingPoints > 0)
                  _buildPointsInfoItem(
                    'Pending',
                    '${points.pendingPoints}',
                    Icons.pending,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildQuickRedeemCard(BuildContext context, LoyaltyPoints points) {
    final options = [
      _RedemptionOption(
        title: 'Store Discount',
        points: 200,
        icon: Icons.money_off,
      ),
      _RedemptionOption(
        title: 'Free Shipping',
        points: 500,
        icon: Icons.local_shipping,
      ),
      _RedemptionOption(
        title: 'Product Voucher',
        points: 1000,
        icon: Icons.card_giftcard,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Redeem',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => PointsRedemptionScreen(
                          availablePoints: points.currentPoints,
                        ),
                  ),
                );
              },
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isDisabled = points.currentPoints < option.points;

              return Container(
                width: 140,
                margin: EdgeInsets.only(right: 12),
                child: SimpleGlassCard(
                  child: InkWell(
                    onTap:
                        isDisabled
                            ? null
                            : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => PointsRedemptionScreen(
                                        availablePoints: points.currentPoints,
                                      ),
                                ),
                              );
                            },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            option.icon,
                            color: isDisabled ? Colors.white30 : Colors.amber,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            option.title,
                            style: TextStyle(
                              color: isDisabled ? Colors.white30 : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${option.points} pts',
                            style: TextStyle(
                              color:
                                  isDisabled ? Colors.white30 : Colors.white70,
                              fontSize: 12,
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
        ),
      ],
    );
  }

  Widget _buildRecentActivityCard(
    BuildContext context,
    bloc.LoyaltyState state,
  ) {
    final transactions = state.transactions ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to full history
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoyaltyPointsScreen(),
                  ),
                );
              },
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Recent activity list - show transactions or empty state
        SimpleGlassCard(
          child:
              transactions.isEmpty
                  ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.history, color: Colors.white54, size: 32),
                          SizedBox(height: 8),
                          Text(
                            'No transactions yet',
                            style: TextStyle(color: Colors.white70),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Future activity will appear here',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  : Column(
                    children: [
                      for (
                        int i = 0;
                        i < transactions.length.clamp(0, 3);
                        i++
                      ) ...[
                        LoyaltyTransactionItem(transaction: transactions[i]),
                        if (i < transactions.length.clamp(0, 3) - 1)
                          const Divider(color: Colors.white24),
                      ],
                    ],
                  ),
        ),
      ],
    );
  }
}

/// Redemption option data class
class _RedemptionOption {
  final String title;
  final int points;
  final IconData icon;

  const _RedemptionOption({
    required this.title,
    required this.points,
    required this.icon,
  });
}
