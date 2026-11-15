import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../domain/task_models.dart';
import '../domain/task_provider.dart';

class ProofSubmissionScreen extends ConsumerStatefulWidget {
  final Task task;

  const ProofSubmissionScreen({super.key, required this.task});

  @override
  ConsumerState<ProofSubmissionScreen> createState() => _ProofSubmissionScreenState();
}

class _ProofSubmissionScreenState extends ConsumerState<ProofSubmissionScreen> {
  final _textProofController = TextEditingController();
  String? _screenshotPath;
  String _selectedOption = 'both'; // 'screenshot', 'text', 'both'
  bool _isSubmitting = false;
  List<TaskProof> _proofHistory = [];
  List<TaskReview> _reviewHistory = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final notifier = ref.read(tasksProvider.notifier);
    final proofs = await notifier.getProofsForTask(widget.task.id);
    final reviews = await notifier.getReviewsForTask(widget.task.id);
    if (mounted) {
      setState(() {
        _proofHistory = proofs;
        _reviewHistory = reviews;
      });
    }
  }

  @override
  void dispose() {
    _textProofController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) {
        final pathLower = picked.path.toLowerCase();
        // Validate supported formats: JPG, JPEG, PNG, WEBP
        if (pathLower.endsWith('.jpg') ||
            pathLower.endsWith('.jpeg') ||
            pathLower.endsWith('.png') ||
            pathLower.endsWith('.webp')) {
          setState(() {
            _screenshotPath = picked.path;
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: AppColors.roseDanger,
                content: Text('Supported formats: JPG, JPEG, PNG, WEBP only.'),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.roseDanger,
            content: Text('Failed to pick screenshot: $e'),
          ),
        );
      }
    }
  }

  Future<void> _submitProof() async {
    final text = _textProofController.text.trim();

    if (_selectedOption == 'screenshot' && _screenshotPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a screenshot proof to upload.')),
      );
      return;
    }

    if (_selectedOption == 'text' && text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe how you completed this work in text.')),
      );
      return;
    }

    if (_selectedOption == 'both') {
      if (_screenshotPath == null && text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please provide either screenshot, text explanation, or both.')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    final success = await ref.read(tasksProvider.notifier).submitProof(
      taskId: widget.task.id,
      proofType: _selectedOption,
      screenshotPath: _screenshotPath,
      textProof: text.isNotEmpty ? text : null,
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.emeraldGreen,
          content: Text('Work proof submitted successfully! Sent for verification.'),
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      final err = ref.read(tasksProvider).error ?? 'Failed to submit proof';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.roseDanger, content: Text(err)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Submit Work Proof'),
        backgroundColor: AppColors.cardSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: widget.task.status.color.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: widget.task.status.color.withOpacity(0.4)),
                        ),
                        child: Text(
                          widget.task.status.displayName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: widget.task.status.color,
                          ),
                        ),
                      ),
                      Text(
                        'Priority: ${widget.task.priority.displayName}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.task.priority.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.task.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  if (widget.task.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.task.description,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                  if (widget.task.rejectionReason != null && widget.task.rejectionReason!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.roseDanger.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.roseDanger.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.roseDanger, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Previous Rejection Reason:',
                                  style: TextStyle(
                                    color: AppColors.roseDanger,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.task.rejectionReason!,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Select Proof Mode',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),

            // Proof Mode Tabs
            Row(
              children: [
                _buildModeTab('both', 'Screenshot & Text', Icons.layers_outlined),
                const SizedBox(width: 8),
                _buildModeTab('screenshot', 'Screenshot Only', Icons.image_outlined),
                const SizedBox(width: 8),
                _buildModeTab('text', 'Text Only', Icons.text_snippet_outlined),
              ],
            ),

            const SizedBox(height: 20),

            // Screenshot Upload Section
            if (_selectedOption == 'screenshot' || _selectedOption == 'both') ...[
              const Text(
                'Upload Screenshot Proof (JPG, PNG, WEBP)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              if (_screenshotPath == null)
                GestureDetector(
                  onTap: _pickScreenshot,
                  child: Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder, style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_outlined, size: 36, color: AppColors.electricPurpleLight),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap to select screenshot from gallery',
                          style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Supports JPG, JPEG, PNG, WEBP',
                          style: TextStyle(fontSize: 11, color: AppColors.textDim),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.electricPurple),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.file(
                        File(_screenshotPath!),
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _screenshotPath = null),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
            ],

            // Text Proof Section
            if (_selectedOption == 'text' || _selectedOption == 'both') ...[
              const Text(
                'Work Completion Description & Process',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _textProofController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Describe how the work was completed, tools used, results achieved, or provide output URLs...',
                  hintStyle: TextStyle(color: AppColors.textDim, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.cardSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.electricPurple),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitProof,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white),
                label: Text(
                  _isSubmitting ? 'Submitting Proof...' : 'Submit Work Proof',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            // Proof Submission History
            if (_proofHistory.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Text(
                'Submission History',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _proofHistory.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final p = _proofHistory[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Submitted: ${p.submittedDate} at ${p.submittedTime}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              p.proofType.toUpperCase(),
                              style: TextStyle(fontSize: 10, color: AppColors.cyberCyan, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (p.textProof != null && p.textProof!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            p.textProof!,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(String mode, String label, IconData icon) {
    final isSelected = _selectedOption == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedOption = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.electricPurple : AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.electricPurpleLight : AppColors.cardBorder,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.textSecondary),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
