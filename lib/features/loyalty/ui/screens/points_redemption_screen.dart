import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loyalty_app/core/common/widgets/simple_glass_card.dart';
import 'package:loyalty_app/core/constants/app_config.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';
import 'package:loyalty_app/core/utils/gradient_background.dart';
import 'package:loyalty_app/features/loyalty/domain/blocs/loyalty_bloc.dart';

class PointsRedemptionScreen extends StatefulWidget {
  final int availablePoints;

  const PointsRedemptionScreen({
    super.key,
    required this.availablePoints,
  });

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
      final description = 'Redeemed for $_selectedRedemptionType';
      
      // Dispatch redemption event
      BlocProvider.of<LoyaltyBloc>(context).add(
        RedeemLoyaltyPoints(
          points: _pointsToRedeem,
          description: description,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoyaltyBloc, LoyaltyState>(
      listener: (context, state) {
        if (state is PointsRedemptionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully redeemed ${state.pointsRedeemed} points for ${AppConfig.currencySymbol}${state.value.toStringAsFixed(2)}',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else if (state is LoyaltyError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Redeem Points'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: GradientBackground(
            child: SingleChildScrollView(
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
                      _buildRedeemButton(state is LoyaltyLoading),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
                    '${widget.availablePoints} pts',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Value: ${AppConfig.currencySymbol}${(widget.availablePoints * AppConfig.pesosPerPoint).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
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
            items: _redemptionTypes.map((String type) {
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
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
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
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
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
        onPressed: isLoading || _pointsToRedeem <= 0 || _pointsToRedeem > widget.availablePoints
            ? null
            : _redeemPoints,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          disabledBackgroundColor: Colors.grey,
        ),
        child: isLoading
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
} 