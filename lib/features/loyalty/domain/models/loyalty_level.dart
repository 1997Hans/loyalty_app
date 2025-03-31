import 'package:equatable/equatable.dart';

enum LoyaltyTier { platinum, ruby, gold, silver }

class LoyaltyLevel extends Equatable {
  final LoyaltyTier tier;
  final String label;
  final int goodsPercentage;
  final int servicesPercentage;
  final DateTime? startDate;
  final String? accountNumber;

  const LoyaltyLevel({
    required this.tier,
    required this.label,
    required this.goodsPercentage,
    required this.servicesPercentage,
    this.startDate,
    this.accountNumber,
  });

  static LoyaltyLevel platinum() {
    return const LoyaltyLevel(
      tier: LoyaltyTier.platinum,
      label: 'Platinum',
      goodsPercentage: 10,
      servicesPercentage: 15,
    );
  }

  static LoyaltyLevel ruby() {
    return const LoyaltyLevel(
      tier: LoyaltyTier.ruby,
      label: 'Ruby',
      goodsPercentage: 15,
      servicesPercentage: 20,
    );
  }

  @override
  List<Object?> get props => [
    tier,
    label,
    goodsPercentage,
    servicesPercentage,
    startDate,
    accountNumber,
  ];
}
