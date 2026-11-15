import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../domain/task_models.dart';
import '../domain/task_provider.dart';

class AddTaskDialog extends ConsumerStatefulWidget {
  const AddTaskDialog({super.key});

  @override
  ConsumerState<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends ConsumerState<AddTaskDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _platformController = TextEditingController();
  final _categoryController = TextEditingController(text: 'General Work');

  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 1));
  TaskPriority _selectedPriority = TaskPriority.medium;
  bool _isCreating = false;

  final List<String> _commonPlatforms = [
    'Tenbox',
    'Whop',
    'YouTube',
    'Instagram',
    'Telegram',
    'X / Twitter',
    'LinkedIn',
    'Direct Client',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _platformController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _submitTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a work title.')),
      );
      return;
    }

    setState(() => _isCreating = true);

    final success = await ref.read(tasksProvider.notifier).createTask(
      title: title,
      description: _descController.text.trim(),
      platform: _platformController.text.trim(),
      category: _categoryController.text.trim(),
      deadline: _selectedDeadline,
      priority: _selectedPriority,
    );

    setState(() => _isCreating = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.emeraldGreen,
          content: Text('Task created successfully! Submit proof once completed.'),
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      final err = ref.read(tasksProvider).error ?? 'Failed to create task';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.roseDanger, content: Text(err)),
      );
    }
  }

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
        color: AppColors.cardSurface,
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
              'Add New Work / Task',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Qualifying tasks earn Gold Coins once approved with proof.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 18),

            // Work Title
            const Text('Work Title *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. Cut 3 short videos for Tenbox affiliate',
                hintStyle: TextStyle(color: AppColors.textDim, fontSize: 13),
              ),
            ),
            const SizedBox(height: 14),

            // Work Description
            const Text('Work Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 6),
            TextField(
              controller: _descController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Key steps, links, or specific deliverables...',
                hintStyle: TextStyle(color: AppColors.textDim, fontSize: 13),
              ),
            ),
            const SizedBox(height: 14),

            // Platform Name (optional)
            const Text('Platform Name (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 6),
            TextField(
              controller: _platformController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. Tenbox, Whop, YouTube',
                hintStyle: TextStyle(color: AppColors.textDim, fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),

            // Quick Platform Pills
            SizedBox(
              height: 30,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _commonPlatforms.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final p = _commonPlatforms[index];
                  return GestureDetector(
                    onTap: () => setState(() => _platformController.text = p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        p,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Priority & Deadline Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Priority', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<TaskPriority>(
                        value: _selectedPriority,
                        dropdownColor: AppColors.cardSurface,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                        items: TaskPriority.values.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: p.color),
                                ),
                                const SizedBox(width: 8),
                                Text(p.displayName),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPriority = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Deadline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDeadline,
                            firstDate: DateTime.now().subtract(const Duration(days: 1)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _selectedDeadline = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd MMM yyyy').format(_selectedDeadline),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                              const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.electricPurpleLight),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _submitTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _isCreating ? 'Creating Task...' : 'Add Work Task',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
