// Data models for the public policy and legal information feature.

class PolicySection {
  final String heading;
  final String body;

  const PolicySection({
    required this.heading,
    required this.body,
  });

  factory PolicySection.fromJson(Map<String, dynamic> json) => PolicySection(
        heading: json['heading'] as String? ?? '',
        body: json['body'] as String? ?? '',
      );
}

class PolicyModel {
  final String slug;
  final String title;
  final String updatedAt;
  final List<PolicySection> sections;
  final String? legalNotice;

  const PolicyModel({
    required this.slug,
    required this.title,
    required this.updatedAt,
    required this.sections,
    this.legalNotice,
  });

  factory PolicyModel.fromJson(Map<String, dynamic> json) => PolicyModel(
        slug: json['slug'] as String? ?? '',
        title: json['title'] as String? ?? '',
        updatedAt: json['updatedAt'] as String? ?? '',
        sections: (json['sections'] as List<dynamic>? ?? [])
            .map((e) => PolicySection.fromJson(e as Map<String, dynamic>))
            .toList(),
        legalNotice: json['legalNotice'] as String?,
      );
}

class PolicySummary {
  final String slug;
  final String title;
  final String updatedAt;

  const PolicySummary({
    required this.slug,
    required this.title,
    required this.updatedAt,
  });

  factory PolicySummary.fromJson(Map<String, dynamic> json) => PolicySummary(
        slug: json['slug'] as String? ?? '',
        title: json['title'] as String? ?? '',
        updatedAt: json['updatedAt'] as String? ?? '',
      );
}
