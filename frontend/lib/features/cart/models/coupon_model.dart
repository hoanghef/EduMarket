class ValidatedCouponModel {
  const ValidatedCouponModel({
    required this.code,
    required this.discountType,
    required this.subtotal,
    required this.discountAmount,
    required this.totalAmount,
  });

  final String code;
  final String discountType;
  final double subtotal;
  final double discountAmount;
  final double totalAmount;

  factory ValidatedCouponModel.fromJson(Map<String, dynamic> json) {
    final coupon = json['coupon'] as Map<String, dynamic>? ?? {};
    return ValidatedCouponModel(
      code: coupon['code'] as String? ?? '',
      discountType: coupon['discountType'] as String? ?? 'PERCENTAGE',
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      discountAmount:
          double.tryParse(json['discountAmount']?.toString() ?? '0') ?? 0.0,
      totalAmount:
          double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0,
    );
  }
}
