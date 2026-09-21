/// Domain models for the Certificates feature.
library;

class CertificateItem {
  const CertificateItem({
    required this.certificateCode,
    required this.courseTitle,
    required this.issuedAt,
    this.verificationUrl,
  });

  final String certificateCode;
  final String courseTitle;
  final DateTime issuedAt;
  final String? verificationUrl;

  factory CertificateItem.fromJson(Map<String, dynamic> json) {
    final verification = json['verification'] as Map<String, dynamic>?;
    return CertificateItem(
      certificateCode: json['certificateCode'] as String? ?? '',
      courseTitle: json['courseTitle'] as String? ?? '',
      issuedAt: DateTime.tryParse(json['issuedAt'] as String? ?? '') ??
          DateTime.now(),
      verificationUrl: verification?['url'] as String?,
    );
  }
}

class CertificateVerificationResult {
  const CertificateVerificationResult({
    required this.verified,
    required this.certificateCode,
    required this.studentName,
    required this.courseName,
    required this.issuedAt,
  });

  final bool verified;
  final String certificateCode;
  final String studentName;
  final String courseName;
  final DateTime issuedAt;

  factory CertificateVerificationResult.fromJson(Map<String, dynamic> json) =>
      CertificateVerificationResult(
        verified: json['verified'] as bool? ?? false,
        certificateCode: json['certificateCode'] as String? ?? '',
        studentName: json['studentName'] as String? ?? '',
        courseName: json['courseName'] as String? ?? '',
        issuedAt: DateTime.tryParse(json['issuedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
