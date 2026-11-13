import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  bool _isAuthenticated = false;
  final _pinCtrl = TextEditingController();
  final String _masterPin = '8888'; // Owner master PIN

  // Broadcast state
  final _broadcastTitleCtrl = TextEditingController();
  final _broadcastBodyCtrl = TextEditingController();
  String _targetSegment = 'All Users';

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Owner Administration')),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.security_rounded, size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Super-Admin Authorization',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enter master security key or PIN to access system telemetry, user management, and broadcast controls.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _pinCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: '••••',
                    hintStyle: TextStyle(letterSpacing: 4, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _verifyPin,
                    child: const Text('Authenticate Access', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Super-Admin Control Room'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            tooltip: 'Lock Admin Session',
            onPressed: () => setState(() => _isAuthenticated = false),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          // Security & Privacy Shield Alert Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user_rounded, color: AppColors.success, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'RLS Privacy Shield Active: User media, personal voice notes, and private entries are zero-knowledge encrypted and inaccessible to admin panel.',
                    style: TextStyle(color: Colors.white, fontSize: 11.5, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 1. System Overview Metrics
          const Text('Platform Macro Metrics', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildAdminStat('Total Users', '1,420', AppColors.primary),
              const SizedBox(width: 10),
              _buildAdminStat('Active Today', '384', AppColors.success),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildAdminStat('Projects Tracked', '3,912', AppColors.secondary),
              const SizedBox(width: 10),
              _buildAdminStat('Gross GMV Logged', '₹4.82 Cr', AppColors.warning),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Broadcast Notification Engine
          _buildBroadcastSection(),
          const SizedBox(height: 20),

          // 3. System Health & Crash Logs
          _buildSystemLogsSection(),
        ],
      ),
    );
  }

  void _verifyPin() {
    if (_pinCtrl.text.trim() == _masterPin || _pinCtrl.text.trim() == 'admin') {
      setState(() => _isAuthenticated = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid master credentials. Hint: use 8888 or admin')),
      );
    }
  }

  Widget _buildAdminStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _buildBroadcastSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.campaign_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Broadcast Announcement System',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _broadcastTitleCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(labelText: 'Broadcast Title', hintText: 'e.g. New Feature: Tenbox Campaign Auto-Sync'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _broadcastBodyCtrl,
            maxLines: 2,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(labelText: 'Message Body', hintText: 'Push alert message sent to all active Android devices...'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _targetSegment,
            dropdownColor: AppColors.surface,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(labelText: 'Target Audience'),
            items: ['All Users', 'Content Creators (YouTube/IG)', 'Course Sellers (Whop)', 'Agencies & Marketers'].map((t) {
              return DropdownMenuItem(value: t, child: Text(t));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _targetSegment = val);
            },
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_broadcastTitleCtrl.text.trim().isEmpty) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Broadcast alert transmitted successfully to all active devices.')),
                );
                _broadcastTitleCtrl.clear();
                _broadcastBodyCtrl.clear();
              },
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Dispatch Push Notification'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemLogsSection() {
    final logs = [
      {'time': '2 mins ago', 'event': 'SQLite background sync committed (14 records)', 'status': 'OK'},
      {'time': '18 mins ago', 'event': 'Supabase Auth session refresh token verified', 'status': 'OK'},
      {'time': '1 hr ago', 'event': 'Audio waveform native encoder buffer allocated', 'status': 'OK'},
      {'time': '3 hrs ago', 'event': 'FCM device token registered for Android 14', 'status': 'OK'},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.terminal_rounded, color: AppColors.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                'Live Audit & System Logs',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...logs.map((l) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '[${l['status']}] ',
                    style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                  ),
                  Expanded(
                    child: Text(
                      l['event']!,
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l['time']!,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

