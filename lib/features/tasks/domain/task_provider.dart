import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/local_db_service.dart';
import '../../auth/domain/auth_provider.dart';
import 'task_models.dart';

class TasksState {
  final List<Task> tasks;
  final bool isLoading;
  final String? error;

  TasksState({
    required this.tasks,
    this.isLoading = false,
    this.error,
  });

  TasksState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? error,
  }) {
    return TasksState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get approvedCount => tasks.where((t) => t.status == TaskStatus.approved).length;
  int get pendingCount => tasks.where((t) => t.status == TaskStatus.pending || t.status == TaskStatus.inProgress).length;
  int get underReviewCount => tasks.where((t) => t.status == TaskStatus.proofSubmitted || t.status == TaskStatus.underReview).length;
}

final tasksProvider = StateNotifierProvider<TasksNotifier, TasksState>((ref) {
  final user = ref.watch(authProvider).user;
  return TasksNotifier(ref, user?.id ?? '');
});

class TasksNotifier extends StateNotifier<TasksState> {
  final Ref ref;
  final String userId;

  TasksNotifier(this.ref, this.userId) : super(TasksState(tasks: [], isLoading: true)) {
    if (userId.isNotEmpty) {
      loadTasks();
    } else {
      state = TasksState(tasks: [], isLoading: false);
    }
  }

  Future<void> loadTasks() async {
    if (userId.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final taskMaps = await LocalDbService.instance.getTasks(userId);
      final tasks = taskMaps.map((m) => Task.fromMap(m)).toList();
      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createTask({
    required String title,
    String description = '',
    String platform = '',
    String category = 'General Work',
    required DateTime deadline,
    TaskPriority priority = TaskPriority.medium,
  }) async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser?.isSuspended == true) {
      state = state.copyWith(error: 'Your account is currently suspended. You cannot submit new work.');
      return false;
    }

    final now = DateTime.now();
    final newTask = Task(
      id: 'task_${now.microsecondsSinceEpoch}',
      userId: userId,
      title: title.trim(),
      description: description.trim(),
      platform: platform.trim(),
      category: category.trim(),
      deadline: deadline,
      priority: priority,
      status: TaskStatus.pending,
      isQualifying: true,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await LocalDbService.instance.upsertTask(newTask.toMap());
      await LocalDbService.instance.logUserActivity(
        userId,
        'create_task',
        'Created task: "${newTask.title}" [${newTask.priority.displayName}]',
      );
      await loadTasks();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to create task: $e');
      return false;
    }
  }

  Future<bool> submitProof({
    required String taskId,
    required String proofType, // 'screenshot', 'text', 'both'
    String? screenshotPath,
    String? textProof,
  }) async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser?.isSuspended == true) {
      state = state.copyWith(error: 'Suspended accounts cannot submit proofs.');
      return false;
    }

    final now = DateTime.now();
    final proofId = 'proof_${now.microsecondsSinceEpoch}';
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final timeStr = DateFormat('HH:mm:ss').format(now);

    final proof = TaskProof(
      id: proofId,
      taskId: taskId,
      userId: userId,
      proofType: proofType,
      screenshotPath: screenshotPath,
      textProof: textProof,
      submittedDate: dateStr,
      submittedTime: timeStr,
      submittedAt: now,
    );

    try {
      await LocalDbService.instance.upsertTaskProof(proof.toMap());

      // Update task status to Proof Submitted
      final index = state.tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        final currentTask = state.tasks[index];
        final updatedTask = currentTask.copyWith(
          status: TaskStatus.proofSubmitted,
          rejectionReason: null, // Clear any previous rejection
          updatedAt: now,
        );
        await LocalDbService.instance.upsertTask(updatedTask.toMap());
      }

      await LocalDbService.instance.logUserActivity(
        userId,
        'submit_proof',
        'Submitted $proofType proof for task ID $taskId',
      );

      await loadTasks();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to submit proof: $e');
      return false;
    }
  }

  Future<List<TaskProof>> getProofsForTask(String taskId) async {
    try {
      final maps = await LocalDbService.instance.getTaskProofs(taskId);
      return maps.map((m) => TaskProof.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<TaskReview>> getReviewsForTask(String taskId) async {
    try {
      final maps = await LocalDbService.instance.getTaskReviews(taskId);
      return maps.map((m) => TaskReview.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> deleteTask(String taskId) async {
    await LocalDbService.instance.deleteTask(taskId);
    await loadTasks();
  }
}
