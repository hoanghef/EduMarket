class ReviewItemModel {
  const ReviewItemModel({
    required this.id,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.reviewerName,
    this.status = 'APPROVED',
  });

  final String id;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String reviewerName;
  final String status;

  factory ReviewItemModel.fromJson(Map<String, dynamic> json) {
    return ReviewItemModel(
      id: json['id'] as String? ?? '',
      rating: json['rating'] as int? ?? 5,
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      reviewerName: json['reviewerName'] as String? ?? 'Học viên ẩn danh',
      status: json['status'] as String? ?? 'APPROVED',
    );
  }
}

class MyReviewModel {
  const MyReviewModel({
    required this.id,
    required this.rating,
    this.comment,
    required this.status,
    this.moderatedAt,
    required this.createdAt,
  });

  final String id;
  final int rating;
  final String? comment;
  final String status; // PENDING | APPROVED | REJECTED
  final DateTime? moderatedAt;
  final DateTime createdAt;

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';

  factory MyReviewModel.fromJson(Map<String, dynamic> json) {
    return MyReviewModel(
      id: json['id'] as String? ?? '',
      rating: json['rating'] as int? ?? 5,
      comment: json['comment'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      moderatedAt: json['moderatedAt'] != null
          ? DateTime.tryParse(json['moderatedAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
