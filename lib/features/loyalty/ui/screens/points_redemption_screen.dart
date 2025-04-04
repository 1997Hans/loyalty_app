import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loyalty_app/core/common/widgets/simple_glass_card.dart';
import 'package:loyalty_app/core/constants/app_config.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';
import 'package:loyalty_app/core/utils/gradient_background.dart';
import 'package:loyalty_app/features/loyalty/bloc/loyalty_bloc.dart';
import 'package:loyalty_app/core/animations/animations.dart';
import 'package:loyalty_app/features/loyalty/ui/screens/redemption_history_screen.dart';

class PointsRedemptionScreen extends StatefulWidget {
  final int availablePoints;

  const PointsRedemptionScreen({super.key, required this.availablePoints});

  @override
  State<PointsRedemptionScreen> createState() => _PointsRedemptionScreenState();
}

class _PointsRedemptionScreenState extends State<PointsRedemptionScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pointsController = TextEditingController();
  int _pointsToRedeem = 0;
  String _selectedRedemptionType = 'Store Discount';

  final _redemptionTypes = [
    'Store Discount',
    'Gift Card',
    'Product Voucher',
    'Service Discount',
  ];

  @override
  void initState() {
    super.initState();
    _pointsController.addListener(_updatePointsToRedeem);

    // Ensure we have fresh data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoyaltyBloc>().add(LoadPointsTransactions());
    });
  }

  @override
  void dispose() {
    _pointsController.removeListener(_updatePointsToRedeem);
    _pointsController.dispose();
    super.dispose();
  }

  void _updatePointsToRedeem() {
    setState(() {
      _pointsToRedeem = int.tryParse(_pointsController.text) ?? 0;
    });
  }

  void _redeemPoints() {
    if (_formKey.currentState?.validate() ?? false) {
      // Calculate value of points based on AppConfig rate
      final value = _pointsToRedeem * AppConfig.pesosPerPoint;

      // Dispatch redemption event to the correct bloc
      context.read<LoyaltyBloc>().add(
        RedeemPoints(
          points: _pointsToRedeem,
          rewardTitle: _selectedRedemptionType,
          value: value,
        ),
      );
    }
  }

  void _showSuccessDialog(BuildContext context, int points, double value) {
    // The coupon code will be available in the last redeemed transaction in the state
    final transaction =
        context.read<LoyaltyBloc>().state.lastRedeemedTransaction;
    final couponCode = transaction?.metadata['coupon_code'] ?? 'N/A';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.cardDarkColor,
            title: const Text(
              'Redemption Successful',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 60),
                SizedBox(height: 16),
                Text(
                  'You have successfully redeemed $points points!',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Value: ${AppConfig.currencySymbol}${value.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Your Coupon Code',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            couponCode,
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.copy, color: Colors.amber, size: 18),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog

                  // Clear form
                  _pointsController.clear();
                  setState(() {
                    _pointsToRedeem = 0;
                  });

                  // Reload the screen with updated points
                  context.read<LoyaltyBloc>().add(LoadPointsTransactions());
                },
                child: const Text('OK', style: TextStyle(color: Colors.amber)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog

                  // Navigate to redemption history screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RedemptionHistoryScreen(),
                    ),
                  );
                },
                child: const Text(
                  'View History',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoyaltyBloc, LoyaltyState>(
      listenWhen:
          (previous, current) =>
              previous.redemptionStatus != current.redemptionStatus ||
              (current.status == LoyaltyStatus.error &&
                  current.errorMessage != null),
      listener: (context, state) {
        if (state.redemptionStatus == RedemptionStatus.success) {
          // Show success dialog instead of navigating away
          _showSuccessDialog(
            context,
            _pointsToRedeem,
            _pointsToRedeem * AppConfig.pesosPerPoint,
          );

          // Clear redemption status so it doesn't trigger again
          context.read<LoyaltyBloc>().add(const ClearRedemptionStatus());
        } else if (state.status == LoyaltyStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Redeem Points'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: GradientBackground(
          child: BlocBuilder<LoyaltyBloc, LoyaltyState>(
            buildWhen:
                (previous, current) =>
                    previous.status != current.status ||
                    previous.loyaltyPoints != current.loyaltyPoints,
            builder: (context, state) {
              print(
                'PointsRedemptionScreen: Building with state ${state.status}',
              );

              // Show the UI regardless of points, with disabled buttons when points are insufficient
              final availablePoints = widget.availablePoints;

              // Always show the redemption form, even with 0 points (just disable the redeem button)
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedCard(
                          beginScale: 0.95,
                          beginOpacity: 0.0,
                          duration: const Duration(milliseconds: 600),
                          child: _buildAvailablePointsCard(),
                        ),
                        const SizedBox(height: 24.0),
                        AnimatedCard(
                          beginScale: 0.95,
                          beginOpacity: 0.0,
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutQuart,
                          child: _buildRedemptionForm(context),
                        ),
                        const SizedBox(height: 24.0),
                        AnimatedCard(
                          beginScale: 0.95,
                          beginOpacity: 0.0,
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutQuart,
                          child: _buildRedemptionSummary(),
                        ),
                        const SizedBox(height: 24.0),
                        AnimatedCard(
                          beginScale: 0.95,
                          beginOpacity: 0.0,
                          duration: const Duration(milliseconds: 850),
                          curve: Curves.easeOutQuart,
                          child: _buildViewHistoryButton(),
                        ),
                        const SizedBox(height: 32.0),
                        FadeSlideTransition.fromController(
                          controller: AnimationController(
                            vsync: this,
                            duration: const Duration(milliseconds: 900),
                          )..forward(),
                          beginOffset: const Offset(0, 0.2),
                          child: _buildRedeemButton(
                            state.status == LoyaltyStatus.loading ||
                                availablePoints < _pointsToRedeem ||
                                availablePoints <= 0 ||
                                _pointsToRedeem <= 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAvailablePointsCard() {
    return SimpleGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Points',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              const Icon(Icons.stars, color: Colors.amber, size: 40),
              const SizedBox(width: 16.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedCounter(
                    value: widget.availablePoints,
                    suffix: ' pts',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Value: ${AppConfig.currencySymbol}${(widget.availablePoints * AppConfig.pesosPerPoint).toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRedemptionForm(BuildContext context) {
    return SimpleGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Redemption Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          DropdownButtonFormField<String>(
            value: _selectedRedemptionType,
            decoration: const InputDecoration(
              labelText: 'Redemption Type',
              labelStyle: TextStyle(color: Colors.white70),
            ),
            dropdownColor: AppTheme.cardDarkColor,
            style: const TextStyle(color: Colors.white),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedRedemptionType = value;
                });
              }
            },
            items:
                _redemptionTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
          ),
          const SizedBox(height: 24.0),
          TextFormField(
            controller: _pointsController,
            decoration: const InputDecoration(
              labelText: 'Points to Redeem',
              labelStyle: TextStyle(color: Colors.white70),
              hintText: 'Enter points',
              hintStyle: TextStyle(color: Colors.white30),
              suffixText: 'points',
              suffixStyle: TextStyle(color: Colors.white70),
            ),
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter points to redeem';
              }

              final points = int.tryParse(value) ?? 0;

              if (points <= 0) {
                return 'Points must be greater than 0';
              }

              if (points > widget.availablePoints) {
                return 'You only have ${widget.availablePoints} points available';
              }

              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRedemptionSummary() {
    final pointsValue = _pointsToRedeem * AppConfig.pesosPerPoint;
    final hasEnoughPoints = _pointsToRedeem <= widget.availablePoints;

    return SimpleGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Redemption Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          _buildSummaryRow('Redemption Type', _selectedRedemptionType),
          const SizedBox(height: 8.0),
          _buildSummaryRow('Points to Redeem', '$_pointsToRedeem'),
          const SizedBox(height: 8.0),
          _buildSummaryRow(
            'Value',
            '${AppConfig.currencySymbol}${pointsValue.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 16.0),
          if (!hasEnoughPoints && _pointsToRedeem > 0)
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 16.0,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'Not enough points. You have ${widget.availablePoints} available.',
                      style: const TextStyle(color: Colors.red, fontSize: 12.0),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14.0),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 14.0),
        ),
      ],
    );
  }

  Widget _buildRedeemButton(bool isDisabled) {
    // Customize the button text based on the reason it's disabled
    final bool hasNoPoints = widget.availablePoints <= 0;
    final String buttonText =
        hasNoPoints ? 'No Points Available' : 'Redeem Points';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isDisabled ? null : _redeemPoints,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          backgroundColor: Colors.amber,
          disabledBackgroundColor: Colors.grey.withOpacity(0.3),
        ),
        child: Text(
          buttonText,
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: isDisabled ? Colors.white38 : Colors.black,
          ),
        ),
      ),
    );
  }

  // New method to build the view history button
  Widget _buildViewHistoryButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RedemptionHistoryScreen(),
            ),
          );
        },
        icon: const Icon(Icons.history),
        label: const Text('View Redemption History'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          side: const BorderSide(color: Colors.white30),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
