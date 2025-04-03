import 'package:equatable/equatable.dart';
import 'package:loyalty_app/core/constants/app_config.dart';

enum PointsTransactionType { purchase, redemption, expired, adjustment, bonus }

enum TransactionStatus { pending, completed, failed, canceled }

class PointsTransaction extends Equatable {
  final String id;
  final String userId;
  final int points;
  final String description;
  final PointsTransactionType type;
  final DateTime date;
  final TransactionStatus status;
  final String? orderId;
  final double? purchaseAmount;
  final String? metaData;

  const PointsTransaction({
    required this.id,
    required this.userId,
    required this.points,
    required this.description,
    required this.type,
    required this.date,
    this.status = TransactionStatus.completed,
    this.orderId,
    this.purchaseAmount,
    this.metaData,
  });

  bool get isEarning {
    return type == PointsTransactionType.purchase ||
        type == PointsTransactionType.bonus ||
        (type == PointsTransactionType.adjustment && points > 0);
  }

  String get formattedDate {
    return '${date.day} ${_getMonth(date.month)} ${date.year} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }

  String get pointsFormatted {
    final sign = isEarning ? '+ ' : '- ';
    return '$sign${points.abs()} pts';
  }

  String get valueFormatted {
    final pointValue = points.abs() * AppConfig.pesosPerPoint;
    final sign = isEarning ? '+ ' : '- ';
    return '$sign${AppConfig.currencySymbol}${pointValue.toStringAsFixed(2)}';
  }

  // Get an icon for the transaction type
  String get transactionIcon {
    switch (type) {
      case PointsTransactionType.purchase:
        return 'shopping_cart';
      case PointsTransactionType.redemption:
        return 'redeem';
      case PointsTransactionType.expired:
        return 'access_time';
      case PointsTransactionType.adjustment:
        return 'settings';
      case PointsTransactionType.bonus:
        return 'stars';
    }
  }

  PointsTransaction copyWith({
    String? id,
    String? userId,
    int? points,
    String? description,
    PointsTransactionType? type,
    DateTime? date,
    TransactionStatus? status,
    String? orderId,
    double? purchaseAmount,
    String? metaData,
  }) {
    return PointsTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      points: points ?? this.points,
      description: description ?? this.description,
      type: type ?? this.type,
      date: date ?? this.date,
      status: status ?? this.status,
      orderId: orderId ?? this.orderId,
      purchaseAmount: purchaseAmount ?? this.purchaseAmount,
      metaData: metaData ?? this.metaData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'points': points,
      'description': description,
      'type': type.toString(),
      'date': date.toIso8601String(),
      'status': status.toString(),
      'orderId': orderId,
      'purchaseAmount': purchaseAmount,
      'metaData': metaData,
    };
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    points,
    description,
    type,
    date,
    status,
    orderId,
    purchaseAmount,
    metaData,
  ];

  // Example points transactions
  static List<PointsTransaction> getMockTransactions() {
    final userId = 'user_1234';
    return [
      PointsTransaction(
        id: '1',
        userId: userId,
        points: 620,
        description: 'Purchase: Spare parts',
        type: PointsTransactionType.purchase,
        date: DateTime.now().subtract(const Duration(days: 5)),
        orderId: 'ORD-20231015-001',
        purchaseAmount: 6200.50,
      ),
      PointsTransaction(
        id: '2',
        userId: userId,
        points: 345,
        description: 'Purchase: Light fixtures',
        type: PointsTransactionType.purchase,
        date: DateTime.now().subtract(const Duration(days: 5, hours: 2)),
        orderId: 'ORD-20231015-002',
        purchaseAmount: 3450.75,
      ),
      PointsTransaction(
        id: '3',
        userId: userId,
        points: 500,
        description: 'Redeemed for discount',
        type: PointsTransactionType.redemption,
        date: DateTime.now().subtract(const Duration(days: 10, hours: 3)),
        orderId: 'RDM-20231010-001',
      ),
      PointsTransaction(
        id: '4',
        userId: userId,
        points: 100,
        description: 'Welcome bonus',
        type: PointsTransactionType.bonus,
        date: DateTime.now().subtract(const Duration(days: 30)),
      ),
      PointsTransaction(
        id: '5',
        userId: userId,
        points: 50,
        description: 'Points adjustment',
        type: PointsTransactionType.adjustment,
        date: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];
  }
}
