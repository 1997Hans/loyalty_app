import 'package:equatable/equatable.dart';
import 'package:loyalty_app/core/constants/app_config.dart';

enum TransactionType { purchase, refund, pointsRedemption, pointsAdjustment }

class LoyaltyTransaction extends Equatable {
  final String id;
  final String title;
  final DateTime date;
  final double amount;
  final TransactionType type;
  final bool isPositive;

  const LoyaltyTransaction({
    required this.id,
    required this.title,
    required this.date,
    required this.amount,
    required this.type,
    required this.isPositive,
  });

  String get formattedDate {
    return '${date.day} ${_getMonth(date.month)} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getMonth(int month) {
    switch (month) {
      case 1:
        return 'jan';
      case 2:
        return 'feb';
      case 3:
        return 'mar';
      case 4:
        return 'apr';
      case 5:
        return 'may';
      case 6:
        return 'jun';
      case 7:
        return 'jul';
      case 8:
        return 'aug';
      case 9:
        return 'sep';
      case 10:
        return 'oct';
      case 11:
        return 'nov';
      case 12:
        return 'dec';
      default:
        return '';
    }
  }

  String get amountFormatted {
    final sign = isPositive ? '+ ' : '- ';
    return '$sign${AppConfig.currencySymbol}${amount.toStringAsFixed(2)}';
  }

  @override
  List<Object> get props => [id, title, date, amount, type, isPositive];

  // Example transactions
  static List<LoyaltyTransaction> getMockTransactions() {
    return [
      LoyaltyTransaction(
        id: '1',
        title: 'Spare parts',
        date: DateTime(2023, 10, 15, 10, 15),
        amount: 6200.50,
        type: TransactionType.purchase,
        isPositive: true,
      ),
      LoyaltyTransaction(
        id: '2',
        title: 'Light',
        date: DateTime(2023, 10, 15, 10, 15),
        amount: 3450.75,
        type: TransactionType.purchase,
        isPositive: true,
      ),
      LoyaltyTransaction(
        id: '3',
        title: 'Consulting',
        date: DateTime(2023, 10, 10, 11, 37),
        amount: 35680.00,
        type: TransactionType.refund,
        isPositive: false,
      ),
    ];
  }
}
