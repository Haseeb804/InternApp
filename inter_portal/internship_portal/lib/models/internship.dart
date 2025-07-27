class Internship {
  final int internshipId;
  final String title;
  final String description;
  final String status;
  final int createdBy;
  final DateTime createdAt;

  Internship({
    required this.internshipId,
    required this.title,
    required this.description,
    required this.status,
    required this.createdBy,
    required this.createdAt,
  });

  factory Internship.fromJson(Map<String, dynamic> json) {
    return Internship(
      internshipId: json['internship_id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'internship_id': internshipId,
      'title': title,
      'description': description,
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
