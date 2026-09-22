import '../../courses/models/catalog_models.dart';

class WishlistItemModel {
  const WishlistItemModel({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.createdAt,
    required this.course,
  });

  final String id;
  final String userId;
  final String courseId;
  final DateTime createdAt;
  final CourseModel course;

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    return WishlistItemModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      course: CourseModel.fromJson(json['course'] as Map<String, dynamic>? ?? {}),
    );
  }
}
