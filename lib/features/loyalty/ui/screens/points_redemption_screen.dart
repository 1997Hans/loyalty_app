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

              if (state.status == LoyaltyStatus.initial ||
                  state.status == LoyaltyStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              // Show special UI if user has no points
              if (widget.availablePoints <= 0 || state.loyaltyPoints == null) {
                return _buildNoPointsAvailable();
              }

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
                          state.status == LoyaltyStatus.loading,
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

  Widget _buildNoPointsAvailable() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.card_giftcard, color: Colors.amber, size: 80),
          const SizedBox(height: 24),
          const Text(
            'No Points Available',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'You need loyalty points to redeem rewards',
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Points are earned when you make purchases through our WooCommerce store',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              context.read<LoyaltyBloc>().add(LoadPointsTransactions());
            },
            child: const Text('Refresh'),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            icon: const Icon(Icons.settings),
            label: const Text('Go to Profile Settings'),
            onPressed: () {
              // Navigate to tab 3 (Profile/Settings)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WooCommerceSyncScreen(),
                ),
              );
            },
          ),
        ],
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
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white30),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
            dropdownColor: AppTheme.cardDarkColor,
            style: const TextStyle(color: Colors.white),
            items:
                _redemptionTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedRedemptionType = newValue;
                });
              }
            },
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: _pointsController,
            decoration: InputDecoration(
              labelText: 'Points to Redeem',
              labelStyle: const TextStyle(color: Colors.white70),
              border: const OutlineInputBorder(),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white30),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              suffixText: 'pts',
              suffixStyle: const TextStyle(color: Colors.white70),
              helperText: 'Maximum: ${widget.availablePoints} pts',
              helperStyle: const TextStyle(color: Colors.white70),
            ),
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter points amount';
              }
              final points = int.tryParse(value);
              if (points == null) {
                return 'Please enter a valid number';
              }
              if (points <= 0) {
                return 'Points must be greater than 0';
              }
              if (points > widget.availablePoints) {
                return 'Insufficient points';
              }
              return null;
            },
          ),
          const SizedBox(height: 8.0),
          Text(
            'Exchange rate: 1 pt = ${AppConfig.currencySymbol}${AppConfig.pesosPerPoint.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRedemptionSummary() {
    final value = _pointsToRedeem * AppConfig.pesosPerPoint;

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
          _buildSummaryRow('Redemption Type:', _selectedRedemptionType),
          _buildSummaryRow('Points to Redeem:', '$_pointsToRedeem pts'),
          _buildSummaryRow(
            'Value:',
            '${AppConfig.currencySymbol}${value.toStringAsFixed(2)}',
          ),
          _buildSummaryRow(
            'Remaining Points:',
            '${widget.availablePoints - _pointsToRedeem} pts',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedeemButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed:
            isLoading ||
                    _pointsToRedeem <= 0 ||
                    _pointsToRedeem > widget.availablePoints
                ? null
                : _redeemPoints,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          disabledBackgroundColor: Colors.grey,
        ),
        child:
            isLoading
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2.0,
                  ),
                )
                : const Text(
                  'Redeem Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
      ),
    );
  }
}
