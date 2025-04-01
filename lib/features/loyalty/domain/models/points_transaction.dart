import 'package:equatable/equatable.dart';
import 'package:loyalty_app/core/constants/app_config.dart';

enum PointsTransactionType {
  earned,
  redeemed,
  expired,
  adjusted,
  bonus,
}

class PointsTransaction extends Equatable {
  final String id;
  final int points;
  final String description;
  final PointsTransactionType type;
  final DateTime date;
  final String? referenceId;
  final double? purchaseAmount;

  const PointsTransaction({
    required this.id,
    required this.points,
    required this.description,
    required this.type,
    required this.date,
    this.referenceId,
    this.purchaseAmount,
  });

  bool get isPositive {
    return type == PointsTransactionType.earned || 
           type == PointsTransactionType.bonus || 
           (type == PointsTransactionType.adjusted && points > 0);
  }

  String get formattedDate {
    return '${date.day} ${_getMonth(date.month)} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getMonth(int month) {
    const months = [
      'jan', 'feb', 'mar', 'apr', 'may', 'jun',
      'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
    ];
    
    return months[month - 1];
  }

  String get pointsFormatted {
    final sign = isPositive ? '+ ' : '- ';
    return '$sign${points.abs()} pts';
  }

  String get valueFormatted {
    final pointValue = points.abs() * AppConfig.pesosPerPoint;
    final sign = isPositive ? '+ ' : '- ';
    return '$sign${AppConfig.currencySymbol}${pointValue.toStringAsFixed(2)}';
  }

  @override
  List<Object?> get props => [id, points, description, type, date, referenceId, purchaseAmount];

  // Example points transactions
  static List<PointsTransaction> getMockTransactions() {
    return [
      PointsTransaction(
        id: '1',
        points: 620,
        description: 'Purchase: Spare parts',
        type: PointsTransactionType.earned,
        date: DateTime.now().subtract(const Duration(days: 5)),
        referenceId: 'ORD-20231015-001',
        purchaseAmount: 6200.50,
      ),
      PointsTransaction(
        id: '2',
        points: 345,
        description: 'Purchase: Light fixtures',
        type: PointsTransactionType.earned,
        date: DateTime.now().subtract(const Duration(days: 5, hours: 2)),
        referenceId: 'ORD-20231015-002',
        purchaseAmount: 3450.75,
      ),
      PointsTransaction(
        id: '3',
        points: 500,
        description: 'Redeemed for discount',
        type: PointsTransactionType.redeemed,
        date: DateTime.now().subtract(const Duration(days: 10, hours: 3)),
        referenceId: 'RDM-20231010-001',
      ),
      PointsTransaction(
        id: '4',
        points: 100,
        description: 'Welcome bonus',
        type: PointsTransactionType.bonus,
        date: DateTime.now().subtract(const Duration(days: 30)),
      ),
      PointsTransaction(
        id: '5',
        points: 50,
        description: 'Points adjustment',
        type: PointsTransactionType.adjusted,
        date: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];
  }
} 