import 'dart:convert';

enum ProjectStatus {
  active,
  completed,
  paused,
  backlog,
}

enum PriorityLevel {
  low,
  medium,
  high,
  urgent,
}

class Project {
  final String id;
  final String userId;
  final String name;
  final String platformCategory; // Tenbox, Whop, YouTube, Instagram, Telegram, Course Creation, Website Dev, etc.
  final String description;
  final DateTime startDate;
  final DateTime? deadline;
  final PriorityLevel priority;
  final ProjectStatus status;
  final String expectedResult;
  final double progressPercentage; // Derived from stages
  final String notes;
  final bool reminderEnabled;
  final int reminderIntervalHours;
  final DateTime? lastUpdated;
  final DateTime createdAt;

  Project({
    required this.id,
    required this.userId,
    required this.name,
    required this.platformCategory,
    required this.description,
    required this.startDate,
    this.deadline,
    this.priority = PriorityLevel.medium,
    this.status = ProjectStatus.active,
    this.expectedResult = '',
    this.progressPercentage = 0.0,
    this.notes = '',
    this.reminderEnabled = true,
    this.reminderIntervalHours = 2,
    this.lastUpdated,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'platform_category': platformCategory,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'priority': priority.name,
      'status': status.name,
      'expected_result': expectedResult,
      'progress_percentage': progressPercentage,
      'notes': notes,
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'reminder_interval_hours': reminderIntervalHours,
      'last_updated': lastUpdated?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      name: map['name'] ?? '',
      platformCategory: map['platform_category'] ?? 'General',
      description: map['description'] ?? '',
      startDate: map['start_date'] != null ? DateTime.parse(map['start_date']) : DateTime.now(),
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
      priority: PriorityLevel.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => PriorityLevel.medium,
      ),
      status: ProjectStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ProjectStatus.active,
      ),
      expectedResult: map['expected_result'] ?? '',
      progressPercentage: (map['progress_percentage'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] ?? '',
      reminderEnabled: map['reminder_enabled'] == 1 || map['reminder_enabled'] == true,
      reminderIntervalHours: map['reminder_interval_hours'] ?? 2,
      lastUpdated: map['last_updated'] != null ? DateTime.parse(map['last_updated']) : null,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
    );
  }
}

class ProjectStage {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final int stageOrder;
  final bool isCompleted;
  final double weight; // Stage percentage weight (e.g. 20%)
  final DateTime? completedAt;

  ProjectStage({
    required this.id,
    required this.projectId,
    required this.title,
    this.description = '',
    required this.stageOrder,
    this.isCompleted = false,
    this.weight = 1.0,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'title': title,
      'description': description,
      'stage_order': stageOrder,
      'is_completed': isCompleted ? 1 : 0,
      'weight': weight,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory ProjectStage.fromMap(Map<String, dynamic> map) {
    return ProjectStage(
      id: map['id'] ?? '',
      projectId: map['project_id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      stageOrder: map['stage_order'] ?? 0,
      isCompleted: map['is_completed'] == 1 || map['is_completed'] == true,
      weight: (map['weight'] as num?)?.toDouble() ?? 1.0,
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at']) : null,
    );
  }
}

class ProjectUpdate {
  final String id;
  final String projectId;
  final String? stageId;
  final String writtenUpdate;
  final String resultAchieved;
  final String lossOrProblem;
  final String learnings;
  final double moneyEarned;
  final double moneyLost;
  final List<String> screenshotUrls;
  final String? voiceNoteUrl;
  final int? voiceDurationSeconds;
  final DateTime createdAt;

  ProjectUpdate({
    required this.id,
    required this.projectId,
    this.stageId,
    required this.writtenUpdate,
    this.resultAchieved = '',
    this.lossOrProblem = '',
    this.learnings = '',
    this.moneyEarned = 0.0,
    this.moneyLost = 0.0,
    this.screenshotUrls = const [],
    this.voiceNoteUrl,
    this.voiceDurationSeconds,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'stage_id': stageId,
      'written_update': writtenUpdate,
      'result_achieved': resultAchieved,
      'loss_or_problem': lossOrProblem,
      'learnings': learnings,
      'money_earned': moneyEarned,
      'money_lost': moneyLost,
      'screenshot_urls': jsonEncode(screenshotUrls),
      'voice_note_url': voiceNoteUrl,
      'voice_duration_seconds': voiceDurationSeconds,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ProjectUpdate.fromMap(Map<String, dynamic> map) {
    List<String> screenshots = [];
    if (map['screenshot_urls'] != null) {
      if (map['screenshot_urls'] is String) {
        try {
          final decoded = jsonDecode(map['screenshot_urls']);
          if (decoded is List) screenshots = decoded.map((e) => e.toString()).toList();
        } catch (_) {}
      } else if (map['screenshot_urls'] is List) {
        screenshots = (map['screenshot_urls'] as List).map((e) => e.toString()).toList();
      }
    }

    return ProjectUpdate(
      id: map['id'] ?? '',
      projectId: map['project_id'] ?? '',
      stageId: map['stage_id'],
      writtenUpdate: map['written_update'] ?? '',
      resultAchieved: map['result_achieved'] ?? '',
      lossOrProblem: map['loss_or_problem'] ?? '',
      learnings: map['learnings'] ?? '',
      moneyEarned: (map['money_earned'] as num?)?.toDouble() ?? 0.0,
      moneyLost: (map['money_lost'] as num?)?.toDouble() ?? 0.0,
      screenshotUrls: screenshots,
      voiceNoteUrl: map['voice_note_url'],
      voiceDurationSeconds: map['voice_duration_seconds'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
    );
  }
}

