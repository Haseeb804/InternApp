class InternshipApplication {
  final int applicationId;
  final int internshipId;
  final int interneeId;
  final String status;
  final DateTime appliedAt;
  final String? interneeName;
  final String? interneeEmail;
  final String? internshipTitle;

  InternshipApplication({
    required this.applicationId,
    required this.internshipId,
    required this.interneeId,
    required this.status,
    required this.appliedAt,
    this.interneeName,
    this.interneeEmail,
    this.internshipTitle,
  });

  factory InternshipApplication.fromJson(Map<String, dynamic> json) {
    return InternshipApplication(
      applicationId: json['application_id'],
      internshipId: json['internship_id'],
      interneeId: json['internee_id'],
      status: json['status'],
      appliedAt: DateTime.parse(json['applied_at']),
      interneeName: json['internee_name'],
      interneeEmail: json['internee_email'],
      internshipTitle: json['internship_title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'application_id': applicationId,
      'internship_id': internshipId,
      'internee_id': interneeId,
      'status': status,
      'applied_at': appliedAt.toIso8601String(),
      'internee_name': interneeName,
      'internee_email': interneeEmail,
      'internship_title': internshipTitle,
    };
  }
}
