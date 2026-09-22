class AdminDashboardMetrics {
  const AdminDashboardMetrics({
    required this.totalRevenue,
    required this.orderCount,
    required this.customerCount,
    required this.courseCount,
    required this.recentOrders,
    required this.bestSellingCourses,
    required this.monthlyRevenue,
  });

  final double totalRevenue;
  final int orderCount;
  final int customerCount;
  final int courseCount;
  final List<AdminRecentOrder> recentOrders;
  final List<AdminBestSellingCourse> bestSellingCourses;
  final List<AdminMonthlyRevenue> monthlyRevenue;

  factory AdminDashboardMetrics.fromJson(Map<String, dynamic> json) {
    return AdminDashboardMetrics(
      totalRevenue:
          double.tryParse(json['totalRevenue']?.toString() ?? '0') ?? 0.0,
      orderCount: json['orderCount'] as int? ?? 0,
      customerCount: json['customerCount'] as int? ?? 0,
      courseCount: json['courseCount'] as int? ?? 0,
      recentOrders: (json['recentOrders'] as List<dynamic>? ?? [])
          .map((e) => AdminRecentOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
      bestSellingCourses: (json['bestSellingCourses'] as List<dynamic>? ?? [])
          .map(
              (e) => AdminBestSellingCourse.fromJson(e as Map<String, dynamic>))
          .toList(),
      monthlyRevenue: (json['monthlyRevenue'] as List<dynamic>? ?? [])
          .map((e) => AdminMonthlyRevenue.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AdminRecentOrder {
  const AdminRecentOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.customerName,
    required this.customerEmail,
    required this.paymentMethod,
    required this.paymentStatus,
  });

  final String id;
  final String orderNumber;
  final String status;
  final double totalAmount;
  final DateTime createdAt;
  final String customerName;
  final String customerEmail;
  final String paymentMethod;
  final String paymentStatus;

  factory AdminRecentOrder.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final payment = json['payment'] as Map<String, dynamic>? ?? {};
    return AdminRecentOrder(
      id: json['id'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      status: json['status'] as String? ?? '',
      totalAmount:
          double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      customerName: user['fullName'] as String? ?? 'Khách hàng',
      customerEmail: user['email'] as String? ?? '',
      paymentMethod: payment['method'] as String? ?? 'COD',
      paymentStatus: payment['status'] as String? ?? 'PENDING',
    );
  }
}

class AdminBestSellingCourse {
  const AdminBestSellingCourse({
    required this.id,
    required this.title,
    required this.enrollmentCount,
    required this.price,
    required this.ratingAverage,
  });

  final String id;
  final String title;
  final int enrollmentCount;
  final double price;
  final double ratingAverage;

  factory AdminBestSellingCourse.fromJson(Map<String, dynamic> json) {
    return AdminBestSellingCourse(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      enrollmentCount: json['enrollmentCount'] as int? ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      ratingAverage:
          double.tryParse(json['ratingAverage']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class AdminMonthlyRevenue {
  const AdminMonthlyRevenue({
    required this.month,
    required this.revenue,
  });

  final String month;
  final double revenue;

  factory AdminMonthlyRevenue.fromJson(Map<String, dynamic> json) {
    return AdminMonthlyRevenue(
      month: json['month'] as String? ?? '',
      revenue: double.tryParse(json['revenue']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class AdminOrderModel {
  const AdminOrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.discountAmount,
    required this.totalAmount,
    required this.createdAt,
    required this.customerName,
    required this.customerEmail,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.itemCount,
  });

  final String id;
  final String orderNumber;
  final String status;
  final double subtotal;
  final double discountAmount;
  final double totalAmount;
  final DateTime createdAt;
  final String customerName;
  final String customerEmail;
  final String paymentMethod;
  final String paymentStatus;
  final int itemCount;

  factory AdminOrderModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final payment = json['payment'] as Map<String, dynamic>? ?? {};
    final items = json['items'] as List<dynamic>? ?? [];
    return AdminOrderModel(
      id: json['id'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      status: json['status'] as String? ?? '',
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      discountAmount:
          double.tryParse(json['discountAmount']?.toString() ?? '0') ?? 0.0,
      totalAmount:
          double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      customerName: user['fullName'] as String? ?? 'Khách hàng',
      customerEmail: user['email'] as String? ?? '',
      paymentMethod: payment['method'] as String? ?? 'COD',
      paymentStatus: payment['status'] as String? ?? 'PENDING',
      itemCount: items.length,
    );
  }
}

class AdminUserModel {
  const AdminUserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.orderCount,
    required this.entitlementCount,
  });

  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final int orderCount;
  final int entitlementCount;

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    final counts = json['_count'] as Map<String, dynamic>? ?? {};
    return AdminUserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'CUSTOMER',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      orderCount: counts['orders'] as int? ?? 0,
      entitlementCount: counts['entitlements'] as int? ?? 0,
    );
  }
}

class AdminReviewModel {
  const AdminReviewModel({
    required this.id,
    required this.rating,
    this.comment,
    required this.status,
    required this.createdAt,
    required this.customerName,
    required this.customerEmail,
    required this.courseTitle,
    required this.courseSlug,
  });

  final String id;
  final int rating;
  final String? comment;
  final String status;
  final DateTime createdAt;
  final String customerName;
  final String customerEmail;
  final String courseTitle;
  final String courseSlug;

  factory AdminReviewModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final course = json['course'] as Map<String, dynamic>? ?? {};
    return AdminReviewModel(
      id: json['id'] as String? ?? '',
      rating: json['rating'] as int? ?? 5,
      comment: json['comment'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      customerName: user['fullName'] as String? ?? 'Khách hàng',
      customerEmail: user['email'] as String? ?? '',
      courseTitle: course['title'] as String? ?? 'Khóa học',
      courseSlug: course['slug'] as String? ?? '',
    );
  }
}

class AdminCouponModel {
  const AdminCouponModel({
    required this.id,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.minimumOrderAmount,
    this.maximumDiscountAmount,
    this.usageLimit,
    required this.usageCount,
    required this.perUserLimit,
    required this.startsAt,
    required this.endsAt,
    required this.isActive,
  });

  final String id;
  final String code;
  final String? description;
  final String discountType;
  final double discountValue;
  final double? minimumOrderAmount;
  final double? maximumDiscountAmount;
  final int? usageLimit;
  final int usageCount;
  final int perUserLimit;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool isActive;

  factory AdminCouponModel.fromJson(Map<String, dynamic> json) {
    return AdminCouponModel(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      description: json['description'] as String?,
      discountType: json['discountType'] as String? ?? 'PERCENTAGE',
      discountValue:
          double.tryParse(json['discountValue']?.toString() ?? '0') ?? 0.0,
      minimumOrderAmount: json['minimumOrderAmount'] != null
          ? double.tryParse(json['minimumOrderAmount'].toString())
          : null,
      maximumDiscountAmount: json['maximumDiscountAmount'] != null
          ? double.tryParse(json['maximumDiscountAmount'].toString())
          : null,
      usageLimit: json['usageLimit'] as int?,
      usageCount: json['usageCount'] as int? ?? 0,
      perUserLimit: json['perUserLimit'] as int? ?? 1,
      startsAt: json['startsAt'] != null
          ? DateTime.tryParse(json['startsAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endsAt: json['endsAt'] != null
          ? DateTime.tryParse(json['endsAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class AdminEntitlementModel {
  const AdminEntitlementModel({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.orderId,
    required this.status,
    required this.grantedAt,
    this.revokedAt,
    this.revokeReason,
    required this.customerName,
    required this.customerEmail,
    required this.courseTitle,
    required this.courseSlug,
    required this.orderNumber,
  });

  final String id;
  final String userId;
  final String courseId;
  final String orderId;
  final String status;
  final DateTime grantedAt;
  final DateTime? revokedAt;
  final String? revokeReason;
  final String customerName;
  final String customerEmail;
  final String courseTitle;
  final String courseSlug;
  final String orderNumber;

  factory AdminEntitlementModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final course = json['course'] as Map<String, dynamic>? ?? {};
    final order = json['order'] as Map<String, dynamic>? ?? {};
    return AdminEntitlementModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      grantedAt: json['grantedAt'] != null
          ? DateTime.tryParse(json['grantedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      revokedAt: json['revokedAt'] != null
          ? DateTime.tryParse(json['revokedAt'].toString())
          : null,
      revokeReason: json['revokeReason'] as String?,
      customerName: user['fullName'] as String? ?? 'Khách hàng',
      customerEmail: user['email'] as String? ?? '',
      courseTitle: course['title'] as String? ?? 'Khóa học',
      courseSlug: course['slug'] as String? ?? '',
      orderNumber: order['orderNumber'] as String? ?? '',
    );
  }
}

class AdminRevenueReportModel {
  const AdminRevenueReportModel({
    required this.totalRevenue,
    required this.totalDiscount,
    required this.totalSubtotal,
    required this.paidOrdersCount,
    required this.codRevenue,
    required this.codCount,
    required this.vnpayRevenue,
    required this.vnpayCount,
  });

  final double totalRevenue;
  final double totalDiscount;
  final double totalSubtotal;
  final int paidOrdersCount;
  final double codRevenue;
  final int codCount;
  final double vnpayRevenue;
  final int vnpayCount;

  factory AdminRevenueReportModel.fromJson(Map<String, dynamic> json) {
    final cod = json['cod'] as Map<String, dynamic>? ?? {};
    final vnpay = json['vnpay'] as Map<String, dynamic>? ?? {};
    return AdminRevenueReportModel(
      totalRevenue:
          double.tryParse(json['totalRevenue']?.toString() ?? '0') ?? 0.0,
      totalDiscount:
          double.tryParse(json['totalDiscount']?.toString() ?? '0') ?? 0.0,
      totalSubtotal:
          double.tryParse(json['totalSubtotal']?.toString() ?? '0') ?? 0.0,
      paidOrdersCount: json['paidOrdersCount'] as int? ?? 0,
      codRevenue: double.tryParse(cod['revenue']?.toString() ?? '0') ?? 0.0,
      codCount: cod['count'] as int? ?? 0,
      vnpayRevenue:
          double.tryParse(vnpay['revenue']?.toString() ?? '0') ?? 0.0,
      vnpayCount: vnpay['count'] as int? ?? 0,
    );
  }
}
