class Task {
  final int taskId;
  final int internshipId;
  final String title;
  final String description;
  final DateTime? dueDate;
  final DateTime createdAt;
  final String? submissionPath;
  final String? status;

  Task({
    required this.taskId,
    required this.internshipId,
    required this.title,
    required this.description,
    this.dueDate,
    required this.createdAt,
    this.submissionPath,
    this.status,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      taskId: json['task_id'],
      internshipId: json['internship_id'],
      title: json['title'],
      description: json['description'],
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
      submissionPath: json['submission_path'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'internship_id': internshipId,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'submission_path': submissionPath,
      'status': status,
    };
  }
}
