import 'package:equatable/equatable.dart';

/// Model representing a WooCommerce order
class WooCommerceOrder extends Equatable {
  /// Unique order ID
  final int id;

  /// Order number (may be different from ID)
  final String orderNumber;

  /// Customer ID
  final int customerId;

  /// Total order amount
  final double total;

  /// Order status (e.g., "pending", "processing", "completed")
  final String status;

  /// Date when the order was created
  final DateTime dateCreated;

  /// Date when the order was last modified
  final DateTime dateModified;

  /// Currency used for the order
  final String currency;

  /// Payment method used
  final String paymentMethod;

  /// Customer note or additional info
  final String customerNote;

  /// Constructor
  const WooCommerceOrder({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.total,
    required this.status,
    required this.dateCreated,
    required this.dateModified,
    required this.currency,
    required this.paymentMethod,
    this.customerNote = '',
  });

  /// Create a WooCommerceOrder from JSON
  factory WooCommerceOrder.fromJson(Map<String, dynamic> json) {
    return WooCommerceOrder(
      id: json['id'] as int? ?? 0,
      orderNumber: json['number']?.toString() ?? '',
      customerId: json['customer_id'] as int? ?? 0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? '',
      dateCreated:
          DateTime.tryParse(json['date_created']?.toString() ?? '') ??
          DateTime.now(),
      dateModified:
          DateTime.tryParse(json['date_modified']?.toString() ?? '') ??
          DateTime.now(),
      currency: json['currency']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? '',
      customerNote: json['customer_note']?.toString() ?? '',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': orderNumber,
      'customer_id': customerId,
      'total': total.toString(),
      'status': status,
      'date_created': dateCreated.toIso8601String(),
      'date_modified': dateModified.toIso8601String(),
      'currency': currency,
      'payment_method': paymentMethod,
      'customer_note': customerNote,
    };
  }

  @override
  List<Object?> get props => [
    id,
    orderNumber,
    customerId,
    total,
    status,
    dateCreated,
    dateModified,
    currency,
    paymentMethod,
    customerNote,
  ];
}
