import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/local_db_service.dart';
import '../../../core/network/supabase_config.dart';
import '../../auth/domain/auth_provider.dart';
import 'project_models.dart';

final projectsProvider = StateNotifierProvider<ProjectsNotifier, AsyncValue<List<Project>>>((ref) {
  final user = ref.watch(authProvider).user;
  return ProjectsNotifier(ref, user?.id ?? 'demo-user-id');
});

class ProjectsNotifier extends StateNotifier<AsyncValue<List<Project>>> {
  final Ref ref;
  final String userId;

  ProjectsNotifier(this.ref, this.userId) : super(const AsyncValue.loading()) {
    loadProjects();
  }

  Future<void> loadProjects() async {
    state = const AsyncValue.loading();
    try {
      final localMaps = await LocalDbService.instance.getProjects();
      if (localMaps.isNotEmpty) {
        final list = localMaps.map((m) => Project.fromMap(m)).toList();
        state = AsyncValue.data(list);
      } else {
        // Initialize with default template projects if completely empty
        final initialProjects = _getDefaultProjects();
        for (var p in initialProjects) {
          await LocalDbService.instance.upsertProject(p.toMap());
          // Add default stages for each
          _createDefaultStagesForProject(p.id, p.platformCategory);
        }
        state = AsyncValue.data(initialProjects);
      }

      // Sync with Supabase if online
      if (SupabaseConfig.isConfigured) {
        try {
          final res = await SupabaseConfig.client
              .from('projects')
              .select()
              .eq('user_id', userId)
              .order('created_at', ascending: false);

          if (res.isNotEmpty) {
            final remoteProjects = (res as List).map((m) => Project.fromMap(m)).toList();
            for (var p in remoteProjects) {
              await LocalDbService.instance.upsertProject(p.toMap());
            }
            state = AsyncValue.data(remoteProjects);
          }
        } catch (_) {}
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  List<Project> _getDefaultProjects() {
    final now = DateTime.now();
    return [
      Project(
        id: 'proj-tenbox-001',
        userId: userId,
        name: 'Tenbox Clipping & Monetization',
        platformCategory: 'Tenbox',
        description: 'Clipping high-retention podcast moments to generate affiliate & ad revenue on Tenbox campaigns.',
        startDate: now.subtract(const Duration(days: 12)),
        deadline: now.add(const Duration(days: 18)),
        priority: PriorityLevel.high,
        status: ProjectStatus.active,
        expectedResult: '₹65,000 monthly target from 5 campaign approvals',
        progressPercentage: 66.7,
        notes: 'Target 3 uploads per day, test Hormozi-style captions.',
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      Project(
        id: 'proj-whop-002',
        userId: userId,
        name: 'Whop Membership Funnel',
        platformCategory: 'Whop',
        description: 'Building exclusive growth mastermind community on Whop with subscription tier.',
        startDate: now.subtract(const Duration(days: 8)),
        deadline: now.add(const Duration(days: 22)),
        priority: PriorityLevel.urgent,
        status: ProjectStatus.active,
        expectedResult: '50 paying members at \$29/month',
        progressPercentage: 50.0,
        notes: 'Landing page live, next step is onboarding automation.',
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      Project(
        id: 'proj-yt-003',
        userId: userId,
        name: 'YouTube Shorts Scale 100K',
        platformCategory: 'YouTube',
        description: 'Publishing 2 Shorts daily focused on AI automation, finance, and productivity workflows.',
        startDate: now.subtract(const Duration(days: 20)),
        deadline: now.add(const Duration(days: 40)),
        priority: PriorityLevel.medium,
        status: ProjectStatus.active,
        expectedResult: '100,000 subscribers and partner program qualification',
        progressPercentage: 35.0,
        notes: 'Audio normalization and bold color grading improved retention +18%.',
        createdAt: now.subtract(const Duration(days: 20)),
      ),
    ];
  }

  Future<void> _createDefaultStagesForProject(String projId, String category) async {
    List<String> titles;
    if (category == 'Tenbox') {
      titles = [
        'Account Creation & Verification',
        'Campaign Selection & Guidelines Study',
        'Clipping High Hook Videos',
        'Publishing Videos with Meta Tags',
        'Views & Engagement Generated',
        'Earnings Approved & Received'
      ];
    } else {
      titles = [
        'Research & Audience Validation',
        'Asset Creation & Scripting',
        'Production & Content Assembly',
        'Launch & Distribution',
        'Conversion & Feedback Collection',
        'Monetization & Scaling'
      ];
    }

    final weight = 100.0 / titles.length;
    for (int i = 0; i < titles.length; i++) {
      final stage = ProjectStage(
        id: 'stage-$projId-$i',
        projectId: projId,
        title: titles[i],
        stageOrder: i,
        isCompleted: i < 2, // 2 completed by default for demo
        weight: weight,
      );
      await LocalDbService.instance.upsertStage(stage.toMap());
    }
  }

  Future<void> addProject(Project project) async {
    try {
      await LocalDbService.instance.upsertProject(project.toMap());
      await _createDefaultStagesForProject(project.id, project.platformCategory);
      
      final current = state.value ?? [];
      state = AsyncValue.data([project, ...current]);

      if (SupabaseConfig.isConfigured) {
        try {
          await SupabaseConfig.client.from('projects').insert(project.toMap());
        } catch (_) {
          await LocalDbService.instance.addToSyncQueue(
            table: 'projects',
            operation: 'INSERT',
            payload: project.toMap(),
          );
        }
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProjectProgress(String projectId, double progress) async {
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((p) {
        if (p.id == projectId) {
          final updated = Project(
            id: p.id,
            userId: p.userId,
            name: p.name,
            platformCategory: p.platformCategory,
            description: p.description,
            startDate: p.startDate,
            deadline: p.deadline,
            priority: p.priority,
            status: progress >= 100.0 ? ProjectStatus.completed : p.status,
            expectedResult: p.expectedResult,
            progressPercentage: progress,
            notes: p.notes,
            reminderEnabled: p.reminderEnabled,
            reminderIntervalHours: p.reminderIntervalHours,
            lastUpdated: DateTime.now(),
            createdAt: p.createdAt,
          );
          LocalDbService.instance.upsertProject(updated.toMap());
          return updated;
        }
        return p;
      }).toList(),
    );
  }

  Future<void> deleteProject(String projectId) async {
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((p) => p.id != projectId).toList());
    await LocalDbService.instance.deleteProject(projectId);
    if (SupabaseConfig.isConfigured) {
      try {
        await SupabaseConfig.client.from('projects').delete().eq('id', projectId);
      } catch (_) {}
    }
  }
}

