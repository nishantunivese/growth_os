import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/database/local_db_service.dart';
import '../domain/project_models.dart';
import '../domain/project_provider.dart';
import 'add_update_dialog.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ProjectStage> _stages = [];
  List<ProjectUpdate> _updates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProjectData();
  }

  Future<void> _loadProjectData() async {
    setState(() => _isLoading = true);
    final stagesData = await LocalDbService.instance.getStages(widget.projectId);
    final updatesData = await LocalDbService.instance.getUpdates(widget.projectId);

    // If no updates in DB yet, inject default demo journey updates for rich experience
    List<ProjectUpdate> parsedUpdates = updatesData.map((m) => ProjectUpdate.fromMap(m)).toList();
    if (parsedUpdates.isEmpty) {
      final now = DateTime.now();
      parsedUpdates = [
        ProjectUpdate(
          id: 'demo-update-1',
          projectId: widget.projectId,
          writtenUpdate: 'Completed initial account setup, set payout to Wise account, and analyzed 10 viral clipping guidelines.',
          resultAchieved: 'Account approved in 2 hours with priority tier.',
          lossOrProblem: 'First 2 videos got low render bitrate due to bad encoder settings.',
          learnings: 'Use H.264 high-profile NVENC with 15Mbps bitrate for crystal clean captions.',
          moneyEarned: 1250.0,
          moneyLost: 0.0,
          screenshotUrls: [],
          voiceNoteUrl: null,
          voiceDurationSeconds: 42,
          createdAt: now.subtract(const Duration(days: 4)),
        ),
        ProjectUpdate(
          id: 'demo-update-2',
          projectId: widget.projectId,
          writtenUpdate: 'Uploaded 5 clips on TikTok & Shorts. First clip hit 85,000 views within 18 hours!',
          resultAchieved: '85k views, 340 affiliate clicks, \$45 in commissions.',
          lossOrProblem: 'One video copyright claimed by background music track.',
          learnings: 'Always pitch-shift background audio by +1.5% and lower volume to -22dB.',
          moneyEarned: 3800.0,
          moneyLost: 150.0,
          screenshotUrls: [],
          voiceNoteUrl: null,
          voiceDurationSeconds: 65,
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ];
      for (var u in parsedUpdates) {
        await LocalDbService.instance.upsertUpdate(u.toMap());
      }
    }

    setState(() {
      _stages = stagesData.map((m) => ProjectStage.fromMap(m)).toList();
      _updates = parsedUpdates;
      _isLoading = false;
    });
  }

  Future<void> _toggleStage(ProjectStage stage) async {
    final updated = ProjectStage(
      id: stage.id,
      projectId: stage.projectId,
      title: stage.title,
      description: stage.description,
      stageOrder: stage.stageOrder,
      isCompleted: !stage.isCompleted,
      weight: stage.weight,
      completedAt: !stage.isCompleted ? DateTime.now() : null,
    );

    await LocalDbService.instance.upsertStage(updated.toMap());

    // Recalculate project progress based on weights
    final newStages = _stages.map((s) => s.id == stage.id ? updated : s).toList();
    double totalWeight = 0;
    double completedWeight = 0;
    for (var s in newStages) {
      totalWeight += s.weight;
      if (s.isCompleted) completedWeight += s.weight;
    }
    final newProgress = totalWeight > 0 ? (completedWeight / totalWeight) * 100.0 : 0.0;

    await ref.read(projectsProvider.notifier).updateProjectProgress(widget.projectId, newProgress);

    setState(() {
      _stages = newStages;
    });
  }

  void _addNewStageDialog() {
    final titleCtrl = TextEditingController();
    final weightCtrl = TextEditingController(text: '15');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add Process Stage', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(labelText: 'Stage Title', hintText: 'e.g. Campaign Optimization'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: weightCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(labelText: 'Weight Percentage (%)', hintText: 'e.g. 20'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              final newStage = ProjectStage(
                id: 'stage-${DateTime.now().millisecondsSinceEpoch}',
                projectId: widget.projectId,
                title: titleCtrl.text.trim(),
                stageOrder: _stages.length,
                isCompleted: false,
                weight: double.tryParse(weightCtrl.text.trim()) ?? 15.0,
              );
              await LocalDbService.instance.upsertStage(newStage.toMap());
              Navigator.pop(ctx);
              _loadProjectData();
            },
            child: const Text('Save Stage'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider).value ?? [];
    final project = projects.firstWhere(
      (p) => p.id == widget.projectId,
      orElse: () => Project(
        id: widget.projectId,
        userId: '',
        name: 'Project Details',
        platformCategory: 'General',
        description: '',
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
            tooltip: 'Delete Project',
            onPressed: () => _confirmDeleteProject(context, project),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: 'Process Stages (${_stages.length})'),
            Tab(text: 'Journey Timeline (${_updates.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AddUpdateDialog(
              projectId: widget.projectId,
              onSaved: _loadProjectData,
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white, size: 20),
        label: const Text('Submit Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStagesTab(project),
                _buildJourneyTimelineTab(),
              ],
            ),
    );
  }

  Widget _buildStagesTab(Project project) {
    final completedCount = _stages.where((s) => s.isCompleted).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Header Progress Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Overall Progress: ${project.progressPercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$completedCount of ${_stages.length} Completed',
                    style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (project.progressPercentage / 100).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppColors.cardBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    project.progressPercentage >= 100.0 ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Progress updates strictly based on weighted stage completion.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addNewStageDialog,
                    icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                    label: const Text('Add Stage', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Stages List
        ..._stages.asMap().entries.map((entry) {
          final index = entry.key;
          final stage = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: stage.isCompleted ? AppColors.success.withOpacity(0.3) : AppColors.cardBorder,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              leading: GestureDetector(
                onTap: () => _toggleStage(stage),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: stage.isCompleted ? AppColors.success : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: stage.isCompleted ? AppColors.success : AppColors.textSecondary,
                      width: 1.5,
                    ),
                  ),
                  child: stage.isCompleted
                      ? const Icon(Icons.check, size: 20, color: Colors.white)
                      : Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
              ),
              title: Text(
                stage.title,
                style: TextStyle(
                  color: stage.isCompleted ? AppColors.textSecondary : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: stage.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Text(
                'Weight: ${stage.weight.toStringAsFixed(0)}%  •  ${stage.isCompleted ? "Completed" : "Pending action"}',
                style: TextStyle(
                  color: stage.isCompleted ? AppColors.success : AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textSecondary),
                onPressed: () async {
                  await LocalDbService.instance.deleteStage(stage.id);
                  _loadProjectData();
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildJourneyTimelineTab() {
    if (_updates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timeline_rounded, size: 54, color: AppColors.textSecondary.withOpacity(0.4)),
              const SizedBox(height: 16),
              const Text(
                'No Journey Updates Yet',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Record what worked, screenshots, voice notes, earnings, and losses to visualize your path to success.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: _updates.length,
      itemBuilder: (context, index) {
        final update = _updates[index];
        final isLast = index == _updates.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline vertical ruler
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppColors.cardBorder,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Update Content Card
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timestamp & Earnings pill
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${update.createdAt.day}/${update.createdAt.month}/${update.createdAt.year}  •  ${update.createdAt.hour}:${update.createdAt.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                          Row(
                            children: [
                              if (update.moneyEarned > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '+₹${update.moneyEarned.toStringAsFixed(0)}',
                                    style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              if (update.moneyLost > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '-₹${update.moneyLost.toStringAsFixed(0)}',
                                    style: const TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Written Update text
                      Text(
                        update.writtenUpdate,
                        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                      ),
                      const SizedBox(height: 12),

                      // What worked / Result
                      if (update.resultAchieved.isNotEmpty) ...[
                        _buildOutcomeTile(
                          icon: Icons.check_circle_rounded,
                          title: 'Result Achieved / What Worked:',
                          body: update.resultAchieved,
                          color: AppColors.success,
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Loss / Problem
                      if (update.lossOrProblem.isNotEmpty) ...[
                        _buildOutcomeTile(
                          icon: Icons.warning_rounded,
                          title: 'Loss / Problem Encountered:',
                          body: update.lossOrProblem,
                          color: AppColors.danger,
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Learnings
                      if (update.learnings.isNotEmpty) ...[
                        _buildOutcomeTile(
                          icon: Icons.lightbulb_rounded,
                          title: 'What Was Learned:',
                          body: update.learnings,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Voice Note indicator if present
                      if (update.voiceDurationSeconds != null && update.voiceDurationSeconds! > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.mic_rounded, color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Voice Note recorded (${update.voiceDurationSeconds}s)',
                                style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 22),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOutcomeTile({required IconData icon, required String title, required String body, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3)),
        ],
      ),
    );
  }

  void _confirmDeleteProject(BuildContext context, Project p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Project?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          'Are you sure you want to permanently delete "${p.name}" and all its stages, timeline logs, and earnings history?',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(projectsProvider.notifier).deleteProject(p.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

