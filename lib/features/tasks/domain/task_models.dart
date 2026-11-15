import 'package:flutter/material.dart';

enum TaskPriority { low, medium, high, urgent }

enum TaskStatus {
  pending,
  inProgress,
  proofSubmitted,
  underReview,
  approved,
  rejected,
}

extension TaskStatusExtension on TaskStatus {
  String get displayName {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.proofSubmitted:
        return 'Proof Submitted';
      case TaskStatus.underReview:
        return 'Under Review';
      case TaskStatus.approved:
        return 'Approved';
      case TaskStatus.rejected:
        return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case TaskStatus.pending:
        return const Color(0xFF94A3B8); // Slate / Muted
      case TaskStatus.inProgress:
        return const Color(0xFF38BDF8); // Cyan
      case TaskStatus.proofSubmitted:
        return const Color(0xFF818CF8); // Indigo
      case TaskStatus.underReview:
        return const Color(0xFFF59E0B); // Amber
      case TaskStatus.approved:
        return const Color(0xFF10B981); // Emerald Green
      case TaskStatus.rejected:
        return const Color(0xFFF43F5E); // Rose Danger
    }
  }

  static TaskStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'in progress':
      case 'inprogress':
        return TaskStatus.inProgress;
      case 'proof submitted':
      case 'proofsubmitted':
        return TaskStatus.proofSubmitted;
      case 'under review':
      case 'underreview':
        return TaskStatus.underReview;
      case 'approved':
        return TaskStatus.approved;
      case 'rejected':
        return TaskStatus.rejected;
      case 'pending':
      default:
        return TaskStatus.pending;
    }
  }
}

extension TaskPriorityExtension on TaskPriority {
  String get displayName {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low:
        return const Color(0xFF64748B);
      case TaskPriority.medium:
        return const Color(0xFF38BDF8);
      case TaskPriority.high:
        return const Color(0xFFF59E0B);
      case TaskPriority.urgent:
        return const Color(0xFFF43F5E);
    }
  }

  static TaskPriority fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'low':
        return TaskPriority.low;
      case 'high':
        return TaskPriority.high;
      case 'urgent':
        return TaskPriority.urgent;
      case 'medium':
      default:
        return TaskPriority.medium;
    }
  }
}

class Task {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String platform; // optional (Tenbox, Whop, YouTube, Instagram, etc.)
  final String projectId;
  final String category;
  final DateTime deadline;
  final TaskPriority priority;
  final TaskStatus status;
  final bool isQualifying;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.platform = '',
    this.projectId = '',
    this.category = 'General Work',
    required this.deadline,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.isQualifying = true,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isApproved => status == TaskStatus.approved;
  bool get canSubmitProof =>
      status == TaskStatus.pending ||
      status == TaskStatus.inProgress ||
      status == TaskStatus.rejected;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'platform': platform,
      'project_id': projectId,
      'category': category,
      'deadline': deadline.toIso8601String(),
      'priority': priority.displayName,
      'status': status.displayName,
      'is_qualifying': isQualifying ? 1 : 0,
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? '',
      title: map['title'] as String? ?? 'Untitled Task',
      description: map['description'] as String? ?? '',
      platform: map['platform'] as String? ?? '',
      projectId: map['project_id'] as String? ?? '',
      category: map['category'] as String? ?? 'General Work',
      deadline: DateTime.tryParse(map['deadline'] as String? ?? '') ?? DateTime.now().add(const Duration(days: 1)),
      priority: TaskPriorityExtension.fromString(map['priority'] as String?),
      status: TaskStatusExtension.fromString(map['status'] as String?),
      isQualifying: map['is_qualifying'] == 1 || map['is_qualifying'] == true,
      rejectionReason: map['rejection_reason'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Task copyWith({
    String? title,
    String? description,
    String? platform,
    String? projectId,
    String? category,
    DateTime? deadline,
    TaskPriority? priority,
    TaskStatus? status,
    bool? isQualifying,
    String? rejectionReason,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      platform: platform ?? this.platform,
      projectId: projectId ?? this.projectId,
      category: category ?? this.category,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      isQualifying: isQualifying ?? this.isQualifying,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class TaskProof {
  final String id;
  final String taskId;
  final String userId;
  final String proofType; // 'screenshot', 'text', 'both'
  final String? screenshotPath;
  final String? textProof;
  final String submittedDate; // YYYY-MM-DD
  final String submittedTime; // HH:mm:ss
  final DateTime submittedAt;

  TaskProof({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.proofType,
    this.screenshotPath,
    this.textProof,
    required this.submittedDate,
    required this.submittedTime,
    required this.submittedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'user_id': userId,
      'proof_type': proofType,
      'screenshot_path': screenshotPath,
      'text_proof': textProof,
      'submitted_date': submittedDate,
      'submitted_time': submittedTime,
      'submitted_at': submittedAt.toIso8601String(),
    };
  }

  factory TaskProof.fromMap(Map<String, dynamic> map) {
    return TaskProof(
      id: map['id'] as String,
      taskId: map['task_id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      proofType: map['proof_type'] as String? ?? 'text',
      screenshotPath: map['screenshot_path'] as String?,
      textProof: map['text_proof'] as String?,
      submittedDate: map['submitted_date'] as String? ?? '',
      submittedTime: map['submitted_time'] as String? ?? '',
      submittedAt: DateTime.tryParse(map['submitted_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class TaskReview {
  final String id;
  final String taskId;
  final String userId;
  final String reviewedBy;
  final String status; // 'Approved', 'Rejected'
  final String? rejectionReason;
  final DateTime reviewedAt;

  TaskReview({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.reviewedBy,
    required this.status,
    this.rejectionReason,
    required this.reviewedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'user_id': userId,
      'reviewed_by': reviewedBy,
      'status': status,
      'rejection_reason': rejectionReason,
      'reviewed_at': reviewedAt.toIso8601String(),
    };
  }

  factory TaskReview.fromMap(Map<String, dynamic> map) {
    return TaskReview(
      id: map['id'] as String,
      taskId: map['task_id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      reviewedBy: map['reviewed_by'] as String? ?? '',
      status: map['status'] as String? ?? 'Approved',
      rejectionReason: map['rejection_reason'] as String?,
      reviewedAt: DateTime.tryParse(map['reviewed_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
