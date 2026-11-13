import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/database/local_db_service.dart';
import '../domain/project_models.dart';

class AddUpdateDialog extends StatefulWidget {
  final String projectId;
  final VoidCallback onSaved;

  const AddUpdateDialog({super.key, required this.projectId, required this.onSaved});

  @override
  State<AddUpdateDialog> createState() => _AddUpdateDialogState();
}

class _AddUpdateDialogState extends State<AddUpdateDialog> {
  final _writtenCtrl = TextEditingController();
  final _resultCtrl = TextEditingController();
  final _lossCtrl = TextEditingController();
  final _learningsCtrl = TextEditingController();
  final _earnedCtrl = TextEditingController();
  final _lostCtrl = TextEditingController();

  bool _isRecording = false;
  int _recordedSeconds = 0;
  final List<String> _screenshots = [];

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
              'Record Project Journey Update',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Track what you did, what worked, what failed, learnings, and cash flow.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Written Update
            TextField(
              controller: _writtenCtrl,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'What did you do today? *',
                hintText: 'e.g. Edited and posted 3 viral hooks on YouTube Shorts & Tenbox...',
              ),
            ),
            const SizedBox(height: 12),

            // Result Achieved
            TextField(
              controller: _resultCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'What Worked / Result Achieved',
                hintText: 'e.g. 10k views in 3 hours, retention jumped +25%',
                prefixIcon: Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
              ),
            ),
            const SizedBox(height: 12),

            // Loss / Problem Encountered
            TextField(
              controller: _lossCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'What Failed / Loss Encountered',
                hintText: 'e.g. Audio was out of sync on second clip',
                prefixIcon: Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
              ),
            ),
            const SizedBox(height: 12),

            // Learnings
            TextField(
              controller: _learningsCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'What Did You Learn?',
                hintText: 'e.g. Check AAC audio bitrate before final render',
                prefixIcon: Icon(Icons.lightbulb_outline, color: AppColors.secondary, size: 20),
              ),
            ),
            const SizedBox(height: 14),

            // Financial impact row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _earnedCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      labelText: 'Money Earned (₹)',
                      hintText: '0',
                      prefixIcon: Icon(Icons.arrow_upward_rounded, color: AppColors.success, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _lostCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      labelText: 'Money Lost/Cost (₹)',
                      hintText: '0',
                      prefixIcon: Icon(Icons.arrow_downward_rounded, color: AppColors.danger, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Voice Recording Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    _isRecording ? Icons.mic : Icons.mic_none_rounded,
                    color: _isRecording ? AppColors.danger : AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isRecording
                          ? 'Recording... ($_recordedSeconds s)'
                          : _recordedSeconds > 0
                              ? 'Voice note saved ($_recordedSeconds s)'
                              : 'Optional Voice Note',
                      style: TextStyle(
                        color: _isRecording ? AppColors.danger : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecording ? AppColors.danger : AppColors.primary.withOpacity(0.2),
                      foregroundColor: _isRecording ? Colors.white : AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    onPressed: () {
                      setState(() {
                        if (!_isRecording) {
                          _isRecording = true;
                          _recordedSeconds = 18; // Simulated recording duration
                        } else {
                          _isRecording = false;
                        }
                      });
                    },
                    child: Text(_isRecording ? 'Stop' : 'Record'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submitUpdate,
                child: const Text('Save Journey Update', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitUpdate() async {
    if (_writtenCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter what you did today')),
      );
      return;
    }

    final update = ProjectUpdate(
      id: 'update-${DateTime.now().millisecondsSinceEpoch}',
      projectId: widget.projectId,
      writtenUpdate: _writtenCtrl.text.trim(),
      resultAchieved: _resultCtrl.text.trim(),
      lossOrProblem: _lossCtrl.text.trim(),
      learnings: _learningsCtrl.text.trim(),
      moneyEarned: double.tryParse(_earnedCtrl.text.trim()) ?? 0.0,
      moneyLost: double.tryParse(_lostCtrl.text.trim()) ?? 0.0,
      screenshotUrls: _screenshots,
      voiceNoteUrl: _recordedSeconds > 0 ? 'local_voice_note.m4a' : null,
      voiceDurationSeconds: _recordedSeconds > 0 ? _recordedSeconds : null,
      createdAt: DateTime.now(),
    );

    await LocalDbService.instance.upsertUpdate(update.toMap());
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }
}

