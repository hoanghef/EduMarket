import '../../courses/models/catalog_models.dart';

class CartItemModel {
  final String id;
  final String cartId;
  final String courseId;
  final CourseModel course;
  final DateTime createdAt;

  CartItemModel({
    required this.id,
    required this.cartId,
    required this.courseId,
    required this.course,
    required this.createdAt,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'],
      cartId: json['cartId'],
      courseId: json['courseId'],
      course: CourseModel.fromJson(json['course']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class CartModel {
  final String id;
  final String userId;
  final List<CartItemModel> items;

  CartModel({
    required this.id,
    required this.userId,
    required this.items,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      id: json['id'],
      userId: json['userId'],
      items: (json['items'] as List?)
              ?.map((item) => CartItemModel.fromJson(item))
              .toList() ??
          [],
    );
  }

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.course.effectivePrice);
}
