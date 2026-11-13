import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
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
  String _selectedCategory = 'All';
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
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Work & Processes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () => _openAddProjectDialog(context),
          ),
        ],
      ),
      body: projectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
              // Search & Metrics Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: TextField(
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: const InputDecoration(
                            hintText: 'Search projects, tags, outcomes...',
                            hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Category Pills
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
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
                                  color: isSelected ? AppColors.primary : AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.cardBorder,
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
                    ],
                  ),
                ),
              ),

              // Overview Stats Row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      _buildStatBadge('Total', '${projects.length}', Icons.folder_open_rounded, AppColors.primary),
                      const SizedBox(width: 10),
                      _buildStatBadge(
                        'Active',
                        '${projects.where((p) => p.status == ProjectStatus.active).length}',
                        Icons.bolt_rounded,
                        AppColors.success,
                      ),
                      const SizedBox(width: 10),
                      _buildStatBadge(
                        'Completed',
                        '${projects.where((p) => p.status == ProjectStatus.completed).length}',
                        Icons.check_circle_outline_rounded,
                        AppColors.secondary,
                      ),
                    ],
                  ),
                ),
              ),

              // Projects List
              if (filtered.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.layers_clear_outlined, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text(
                          'No projects found',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Start tracking a campaign, funnel, or creator channel by adding your first project.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => _openAddProjectDialog(context),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add Project'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final p = filtered[index];
                        return _buildProjectCard(context, p);
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, Project p) {
    Color badgeColor;
    switch (p.platformCategory.toLowerCase()) {
      case 'tenbox':
        badgeColor = const Color(0xFF6366F1);
        break;
      case 'whop':
        badgeColor = const Color(0xFFFF5252);
        break;
      case 'youtube':
        badgeColor = const Color(0xFFFF0000);
        break;
      case 'instagram':
        badgeColor = const Color(0xFFE1306C);
        break;
      case 'telegram':
        badgeColor = const Color(0xFF0088CC);
        break;
      default:
        badgeColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectDetailScreen(projectId: p.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Category Pill & Priority Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: badgeColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          p.platformCategory,
                          style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: p.priority == PriorityLevel.urgent
                              ? AppColors.danger.withOpacity(0.15)
                              : AppColors.warning.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p.priority.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: p.priority == PriorityLevel.urgent ? AppColors.danger : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${p.progressPercentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                p.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),

              // Description
              Text(
                p.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
              ),
              const SizedBox(height: 14),

              // Animated Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (p.progressPercentage / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: AppColors.cardBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    p.progressPercentage >= 100.0 ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Footer: Expected Result & Deadline
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.flag_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            p.expectedResult.isNotEmpty ? p.expectedResult : 'No target set',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (p.deadline != null) ...[
                    const SizedBox(width: 10),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 14, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text(
                          '${p.deadline!.difference(DateTime.now()).inDays}d left',
                          style: const TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
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

