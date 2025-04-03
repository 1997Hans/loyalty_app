import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loyalty_app/core/common/widgets/simple_glass_card.dart';
import 'package:loyalty_app/core/constants/app_config.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';
import 'package:loyalty_app/core/utils/gradient_background.dart';
import 'package:loyalty_app/features/loyalty/bloc/loyalty_bloc.dart';
import 'package:loyalty_app/features/loyalty/ui/screens/woocommerce_sync_screen.dart';

class PointsRedemptionScreen extends StatefulWidget {
  final int availablePoints;

  const PointsRedemptionScreen({super.key, required this.availablePoints});

  @override
  State<PointsRedemptionScreen> createState() => _PointsRedemptionScreenState();
}

class _PointsRedemptionScreenState extends State<PointsRedemptionScreen> {
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
    showDialog(
      context: context,
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

              // If there are no points available, show a proper message instead of a form with zeros
              if (availablePoints <= 0) {
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SimpleGlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.card_giftcard,
                                  size: 64,
                                  color: Colors.amber,
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'No Points Available',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'You need loyalty points to redeem rewards',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Points are earned when you make purchases through our store',
                                  style: TextStyle(color: Colors.white70),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    context.read<LoyaltyBloc>().add(
                                      LoadPointsTransactions(),
                                    );
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Refresh'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // If we have points, show the redemption form
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAvailablePointsCard(),
                        const SizedBox(height: 24.0),
                        _buildRedemptionForm(context),
                        const SizedBox(height: 24.0),
                        _buildRedemptionSummary(),
                        const SizedBox(height: 32.0),
                        _buildRedeemButton(
                          state.status == LoyaltyStatus.loading ||
                              availablePoints < _pointsToRedeem,
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
                  Text(
                    '${widget.availablePoints} pts',
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
          'Redeem Points',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: isDisabled ? Colors.white38 : Colors.black,
          ),
        ),
      ),
    );
  }
}
