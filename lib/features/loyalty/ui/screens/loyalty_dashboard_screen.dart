import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loyalty_app/core/common/widgets/simple_glass_card.dart';
import 'package:loyalty_app/features/loyalty/ui/screens/loyalty_points_screen.dart';
import 'package:loyalty_app/core/services/notification_service.dart';
import 'package:loyalty_app/features/loyalty/bloc/loyalty_bloc.dart' as bloc;
import 'package:loyalty_app/features/loyalty/domain/models/loyalty_points.dart';
import 'package:loyalty_app/features/loyalty/ui/screens/points_redemption_screen.dart';
import 'package:loyalty_app/features/loyalty/ui/widgets/loyalty_transaction_item.dart';
import 'package:loyalty_app/features/auth/bloc/auth_bloc.dart' as auth_bloc;
import 'package:loyalty_app/core/animations/animations.dart';
import 'package:loyalty_app/features/loyalty/ui/screens/redemption_history_screen.dart';

class LoyaltyDashboardScreen extends StatefulWidget {
  const LoyaltyDashboardScreen({super.key});

  @override
  State<LoyaltyDashboardScreen> createState() => _LoyaltyDashboardScreenState();
}

class _LoyaltyDashboardScreenState extends State<LoyaltyDashboardScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  // Track the current user ID to detect changes
  String? _currentUserId;

  // Animation controllers
  late AnimationController _welcomeAnimationController;
  late AnimationController _cardsAnimationController;
  bool _animationsInitialized = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _welcomeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _cardsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Get the current user ID
    final authState = context.read<auth_bloc.AuthBloc>().state;
    if (authState is auth_bloc.AuthAuthenticated) {
      _currentUserId = authState.user.id.toString();
    }

    // Initialize by loading points and transactions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPointsAndTransactions();
    });
  }

  @override
  void dispose() {
    _welcomeAnimationController.dispose();
    _cardsAnimationController.dispose();
    super.dispose();
  }

  // Force data reload when auth state changes
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if user has changed
    final authState = context.watch<auth_bloc.AuthBloc>().state;
    String? newUserId;

    if (authState is auth_bloc.AuthAuthenticated) {
      newUserId = authState.user.id.toString();
    }

    // If user ID changed, force refresh data
    if (_currentUserId != newUserId) {
      _currentUserId = newUserId;
      // Force data reload for new user
      _loadPointsAndTransactions();
    }
  }

  /// Loads points and transactions data
  void _loadPointsAndTransactions() {
    // Trigger animations only once per screen visit
    if (!_animationsInitialized) {
      _welcomeAnimationController.forward();

      // Delay the cards animation for a better staggered effect
      Future.delayed(const Duration(milliseconds: 300), () {
        _cardsAnimationController.forward();
      });

      _animationsInitialized = true;
    }

    // Only load data if we have a user
    final authState = context.read<auth_bloc.AuthBloc>().state;
    if (authState is auth_bloc.AuthAuthenticated) {
      final loyaltyBloc = context.read<bloc.LoyaltyBloc>();
      loyaltyBloc.add(bloc.SetContext(context));
      loyaltyBloc.add(const bloc.LoadPointsTransactions());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Check current authentication state
    final authState = context.watch<auth_bloc.AuthBloc>().state;
    String? newUserId;

    if (authState is auth_bloc.AuthAuthenticated) {
      newUserId = authState.user.id.toString();

      // If user ID changed since last check, force reload
      if (_currentUserId != newUserId) {
        _currentUserId = newUserId;
        // Schedule reload in next frame to avoid build issues
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final loyaltyBloc = context.read<bloc.LoyaltyBloc>();
          loyaltyBloc.add(const bloc.LoadPointsTransactions());
        });
      }
    }

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
                    _buildWelcomeHeader(),
                    const SizedBox(height: 24),
                    AnimatedCard(
                      animate:
                          _cardsAnimationController.status !=
                          AnimationStatus.completed,
                      duration: const Duration(milliseconds: 800),
                      child: _buildPointsSummaryCard(context, emptyPoints),
                    ),
                    const SizedBox(height: 24),
                    AnimatedCard(
                      animate:
                          _cardsAnimationController.status !=
                          AnimationStatus.completed,
                      duration: const Duration(milliseconds: 800),
                      beginOpacity: 0.0,
                      beginScale: 0.95,
                      curve: Curves.easeOutQuint,
                      child: _buildQuickRedeemCard(context, emptyPoints),
                    ),
                    const SizedBox(height: 24),
                    AnimatedCard(
                      animate:
                          _cardsAnimationController.status !=
                          AnimationStatus.completed,
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
                  _buildWelcomeHeader(),
                  const SizedBox(height: 24),
                  AnimatedCard(
                    animate:
                        _cardsAnimationController.status !=
                        AnimationStatus.completed,
                    duration: const Duration(milliseconds: 800),
                    child: _buildPointsSummaryCard(context, points),
                  ),
                  const SizedBox(height: 24),
                  AnimatedCard(
                    animate:
                        _cardsAnimationController.status !=
                        AnimationStatus.completed,
                    duration: const Duration(milliseconds: 800),
                    beginOpacity: 0.0,
                    beginScale: 0.95,
                    curve: Curves.easeOutQuint,
                    child: _buildQuickRedeemCard(context, points),
                  ),
                  const SizedBox(height: 24),
                  AnimatedCard(
                    animate:
                        _cardsAnimationController.status !=
                        AnimationStatus.completed,
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

  /// Builds the welcome header section
  Widget _buildWelcomeHeader() {
    final authState = context.read<auth_bloc.AuthBloc>().state;
    final String firstName;

    if (authState is auth_bloc.AuthAuthenticated) {
      firstName =
          authState.user.firstName ??
          authState.user.displayName.split(' ').first;
    } else {
      firstName = 'Guest';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: AnimatedBuilder(
        animation: _welcomeAnimationController,
        builder: (context, child) {
          final animation = CurvedAnimation(
            parent: _welcomeAnimationController,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.25),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              firstName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
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
                    isHighlighted: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsInfoItem(
    String label,
    String value,
    IconData icon, {
    bool isHighlighted = false,
  }) {
    final Color textColor = isHighlighted ? Colors.amber : Colors.white;
    final Color iconColor = isHighlighted ? Colors.amber : Colors.white70;

    return Column(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color:
                isHighlighted ? Colors.amber.withOpacity(0.8) : Colors.white70,
            fontSize: 12,
          ),
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
          height: 160,
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
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isDisabled
                                      ? Colors.grey.withOpacity(0.2)
                                      : Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${option.points} pts',
                              style: TextStyle(
                                color:
                                    isDisabled ? Colors.white30 : Colors.amber,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
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
    final isLoading = state.status == bloc.LoyaltyStatus.loading;

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
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RedemptionHistoryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.history, size: 16),
              label: const Text('Redemption History'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.amber,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Recent activity list - show transactions or loading/empty state
        SimpleGlassCard(
          child:
              isLoading
                  ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.amber,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Loading transactions...',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  )
                  : transactions.isEmpty
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
