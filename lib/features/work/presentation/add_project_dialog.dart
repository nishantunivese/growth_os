import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/domain/auth_provider.dart';
import '../domain/project_models.dart';
import '../domain/project_provider.dart';

class AddProjectDialog extends ConsumerStatefulWidget {
  const AddProjectDialog({super.key});

  @override
  ConsumerState<AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends ConsumerState<AddProjectDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  String _selectedCategory = 'Tenbox';
  PriorityLevel _priority = PriorityLevel.medium;
  int _reminderHours = 2;
  int _daysDuration = 30;

  final List<String> _platforms = [
    'Tenbox',
    'Whop',
    'YouTube',
    'Instagram',
    'Telegram',
    'Course Creation',
    'Website Dev',
    'Brand Sponsorship',
    'Other Business',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add New Project / Campaign',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Setup your process pipeline, milestone targets, and smart notifications.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 18),

            // Project Name
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Project / Campaign Name *',
                hintText: 'e.g. Tenbox Clipping Campaign Q4',
              ),
            ),
            const SizedBox(height: 14),

            // Platform Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(labelText: 'Platform / Channel Category'),
              items: _platforms.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 14),

            // Expected Result
            TextField(
              controller: _targetCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Expected Result / Success Metric',
                hintText: 'e.g. 100k views & ₹50,000 revenue',
              ),
            ),
            const SizedBox(height: 14),

            // Description
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Brief Description & Strategy',
                hintText: 'Key steps, hooks, or notes...',
              ),
            ),
            const SizedBox(height: 14),

            // Priority Selector
            const Text('Priority Level', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              children: PriorityLevel.values.map((lvl) {
                final isSelected = _priority == lvl;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.cardBorder,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () => setState(() => _priority = lvl),
                      child: Text(
                        lvl.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Reminder Interval
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Smart Reminder Frequency', style: TextStyle(color: Colors.white, fontSize: 13)),
                DropdownButton<int>(
                  value: _reminderHours,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 2, child: Text('Every 2 hours')),
                    DropdownMenuItem(value: 4, child: Text('Every 4 hours')),
                    DropdownMenuItem(value: 6, child: Text('Every 6 hours')),
                    DropdownMenuItem(value: 12, child: Text('Every 12 hours')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _reminderHours = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveProject,
                child: const Text('Create Project & Auto-Generate Stages', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveProject() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a project name')),
      );
      return;
    }

    final userId = ref.read(authProvider).user?.id ?? 'demo-user-id';
    final now = DateTime.now();

    final project = Project(
      id: 'proj-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      name: _nameCtrl.text.trim(),
      platformCategory: _selectedCategory,
      description: _descCtrl.text.trim(),
      startDate: now,
      deadline: now.add(Duration(days: _daysDuration)),
      priority: _priority,
      status: ProjectStatus.active,
      expectedResult: _targetCtrl.text.trim(),
      progressPercentage: 0.0,
      reminderEnabled: true,
      reminderIntervalHours: _reminderHours,
      createdAt: now,
    );

    ref.read(projectsProvider.notifier).addProject(project);
    Navigator.pop(context);
  }
}

