import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../tasks/domain/task_models.dart';
import '../../tasks/domain/task_provider.dart';
import '../../tasks/presentation/add_task_dialog.dart';
import '../../tasks/presentation/proof_submission_screen.dart';
import '../domain/project_models.dart';
import '../domain/project_provider.dart';
import 'project_detail_screen.dart';
import 'add_project_dialog.dart';

class WorkScreen extends ConsumerStatefulWidget {
  const WorkScreen({super.key});

  @override
  ConsumerState<WorkScreen> createState() => _WorkScreenState();
}

class _WorkScreenState extends ConsumerState<WorkScreen> {
  String _activeTab = 'tasks'; // 'tasks' or 'projects'
  String _selectedCategory = 'All';
  String _taskStatusFilter = 'All'; // All, Pending, Proof Submitted, Approved, Rejected
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Tenbox',
    'Whop',
    'YouTube',
    'Instagram',
    'Telegram',
    'Course Creation',
    'Website Dev'
  ];

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksProvider);
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Work & Processes'),
        backgroundColor: AppColors.cardSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.electricPurpleLight),
            tooltip: _activeTab == 'tasks' ? 'Add Task' : 'Add Project',
            onPressed: () {
              if (_activeTab == 'tasks') {
                _openAddTaskDialog(context);
              } else {
                _openAddProjectDialog(context);
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_activeTab == 'tasks') {
            _openAddTaskDialog(context);
          } else {
            _openAddProjectDialog(context);
          }
        },
        backgroundColor: AppColors.electricPurple,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          _activeTab == 'tasks' ? 'Add Work Task' : 'New Project',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Segmented Navigation: Tasks vs Projects
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSegmentButton(
                    'tasks',
                    'Tasks & Proofs',
                    Icons.task_alt_rounded,
                    tasksState.tasks.length,
                  ),
                ),
                Expanded(
                  child: _buildSegmentButton(
                    'projects',
                    'Projects & Stages',
                    Icons.account_tree_outlined,
                    projectsAsync.value?.length ?? 0,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 13),
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: 'Search tasks, projects, platforms...',
                  hintStyle: TextStyle(color: AppColors.textDim, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.textDim, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Main Content
          Expanded(
            child: _activeTab == 'tasks'
                ? _buildTasksView(tasksState)
                : _buildProjectsView(projectsAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String tab, String title, IconData icon, int count) {
    final isSelected = _activeTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.electricPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white24 : AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textDim,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TASKS & PROOFS VIEW =================
  Widget _buildTasksView(TasksState state) {
    final filtered = state.tasks.where((t) {
      final matchesStatus = _taskStatusFilter == 'All' ||
          t.status.displayName.toLowerCase() == _taskStatusFilter.toLowerCase() ||
          (_taskStatusFilter == 'Proof Submitted' &&
              (t.status == TaskStatus.proofSubmitted || t.status == TaskStatus.underReview));
      final matchesSearch = t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.platform.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(tasksProvider.notifier).loadTasks(),
      color: AppColors.electricPurple,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // Filter Chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildTaskFilterChip('All'),
                  _buildTaskFilterChip('Pending'),
                  _buildTaskFilterChip('Proof Submitted'),
                  _buildTaskFilterChip('Approved'),
                  _buildTaskFilterChip('Rejected'),
                ],
              ),
            ),
          ),

          // Task Count Indicator
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filtered.length} Tasks (${state.approvedCount} Approved)',
                    style: TextStyle(color: AppColors.textDim, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '6 approved tasks = 10 Gold Coins',
                    style: TextStyle(color: AppColors.goldCoin, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_turned_in_outlined, size: 48, color: AppColors.textDim),
                      const SizedBox(height: 12),
                      const Text(
                        'No tasks in this view',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap "Add Work Task" to create your first work deliverable and submit proof.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = filtered[index];
                    return _buildTaskCard(task);
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskFilterChip(String label) {
    final isSelected = _taskStatusFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _taskStatusFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.electricPurple : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.electricPurpleLight : AppColors.cardBorder),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final deadlineFormatted = DateFormat('dd MMM yyyy').format(task.deadline);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: task.isApproved ? AppColors.emeraldGreen.withOpacity(0.4) : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status & Priority Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: task.status.color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: task.status.color.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (task.isApproved) ...[
                      const Icon(Icons.verified_rounded, size: 12, color: AppColors.emeraldGreen),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      task.status.displayName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: task.status.color,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: task.priority.color),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    task.priority.displayName,
                    style: TextStyle(color: task.priority.color, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            task.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),

          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            ),
          ],
          const SizedBox(height: 10),

          // Platform & Deadline Row
          Row(
            children: [
              if (task.platform.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    task.platform,
                    style: const TextStyle(fontSize: 11, color: AppColors.cyberCyan, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textDim),
              const SizedBox(width: 4),
              Text(
                'Deadline: $deadlineFormatted',
                style: TextStyle(color: AppColors.textDim, fontSize: 11),
              ),
            ],
          ),

          // Rejection reason if any
          if (task.rejectionReason != null && task.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.roseDanger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.roseDanger.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.roseDanger, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Rejection reason: ${task.rejectionReason}',
                      style: const TextStyle(color: AppColors.roseDanger, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action Button: Submit Work Proof
          const SizedBox(height: 14),
          if (task.canSubmitProof) ...[
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProofSubmissionScreen(task: task),
                    ),
                  );
                },
                icon: const Icon(Icons.upload_file_rounded, size: 16, color: Colors.white),
                label: Text(
                  task.status == TaskStatus.rejected ? 'Resubmit Work Proof' : 'Submit Work Proof',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: task.status == TaskStatus.rejected ? AppColors.roseDanger : AppColors.electricPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ] else if (task.status == TaskStatus.proofSubmitted || task.status == TaskStatus.underReview) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.amberWarning.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_top_rounded, size: 14, color: AppColors.amberWarning),
                  SizedBox(width: 6),
                  Text(
                    'Proof Submitted • Under Verification',
                    style: TextStyle(color: AppColors.amberWarning, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ] else if (task.isApproved) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.emeraldGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.emeraldGreen.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_rounded, size: 16, color: AppColors.emeraldGreen),
                  SizedBox(width: 6),
                  Text(
                    'Verified Completed Work (Qualifies for Gold Coins)',
                    style: TextStyle(color: AppColors.emeraldGreenLight, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ================= PROJECTS & STAGES VIEW =================
  Widget _buildProjectsView(AsyncValue<List<Project>> projectsAsync) {
    return projectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.electricPurple)),
      error: (err, _) => Center(child: Text('Error loading projects: $err', style: const TextStyle(color: Colors.red))),
      data: (projects) {
        final filtered = projects.where((p) {
          final matchesCat = _selectedCategory == 'All' || p.platformCategory.toLowerCase() == _selectedCategory.toLowerCase();
          final matchesQuery = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.description.toLowerCase().contains(_searchQuery.toLowerCase());
          return matchesCat && matchesQuery;
        }).toList();

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Category Pills
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = cat == _selectedCategory;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.electricPurple : AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.electricPurpleLight : AppColors.cardBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open_rounded, size: 48, color: AppColors.textDim),
                        const SizedBox(height: 12),
                        const Text(
                          'No projects created yet',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap "New Project" to create your first multi-stage project tracker.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final p = filtered[index];
                      return _buildProjectCard(p);
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildProjectCard(Project p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProjectDetailScreen(projectId: p.id)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.platformCategory.toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.cyberCyan),
                      ),
                    ),
                    Text(
                      '${p.progressPercentage.toInt()}% Complete',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.emeraldGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(p.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                if (p.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(p.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (p.progressPercentage / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.background,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      p.progressPercentage >= 100.0 ? AppColors.emeraldGreen : AppColors.electricPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openAddTaskDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTaskDialog(),
    );
  }

  void _openAddProjectDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddProjectDialog(),
    );
  }
}
