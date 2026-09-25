double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

class PaymentModel {
  final String id;
  final String method;
  final String status;
  final double amount;
  final String? transactionId;
  final DateTime? paidAt;

  PaymentModel({
    required this.id,
    required this.method,
    required this.status,
    required this.amount,
    this.transactionId,
    this.paidAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? '',
      method: json['method'] ?? 'COD',
      status: json['status'] ?? 'PENDING',
      amount: _toDouble(json['amount']),
      transactionId: json['transactionId'],
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
    );
  }
}

class OrderItemModel {
  final String id;
  final String courseId;
  final String courseTitleSnapshot;
  final String courseSlugSnapshot;
  final double unitPrice;
  final double discountedUnitPrice;

  OrderItemModel({
    required this.id,
    required this.courseId,
    required this.courseTitleSnapshot,
    required this.courseSlugSnapshot,
    required this.unitPrice,
    required this.discountedUnitPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] ?? '',
      courseId: json['courseId'] ?? '',
      courseTitleSnapshot: json['courseTitleSnapshot'] ?? '',
      courseSlugSnapshot: json['courseSlugSnapshot'] ?? '',
      unitPrice: _toDouble(json['unitPrice']),
      discountedUnitPrice: _toDouble(json['discountedUnitPrice']),
    );
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String status;
  final double subtotal;
  final double discountAmount;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime? paidAt;
  final PaymentModel? payment;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.discountAmount,
    required this.totalAmount,
    required this.createdAt,
    this.paidAt,
    this.payment,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      status: json['status'] ?? 'PENDING',
      subtotal: _toDouble(json['subtotal']),
      discountAmount: _toDouble(json['discountAmount']),
      totalAmount: _toDouble(json['totalAmount']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      payment: json['payment'] != null
          ? PaymentModel.fromJson(json['payment'])
          : null,
      items: (json['items'] as List?)
              ?.map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
