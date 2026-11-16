import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../admin/domain/admin_provider.dart';
import '../../admin/presentation/admin_panel_screen.dart';
import '../../ai_assistant/presentation/growth_intelligence_screen.dart';
import '../../auth/domain/auth_provider.dart';
import '../../auth/presentation/welcome_screen.dart';
import '../../rewards/presentation/rewards_dashboard_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _biometricEnabled = true;
  bool _smartRemindersEnabled = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Account & Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.primary),
            tooltip: 'Super-Admin Panel (Protected)',
            onPressed: () => _promptAdminLogin(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          // 1. Profile Identity Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(
                    (user?.fullName.isNotEmpty == true ? user!.fullName[0] : 'G').toUpperCase(),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user?.fullName.isNotEmpty == true ? user!.fullName : 'Growth Entrepreneur',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, size: 16, color: AppColors.primary),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.businessName.isNotEmpty == true ? user!.businessName : 'Digital Media OS',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          user?.primaryBusinessCategory ?? 'Content & Digital Courses',
                          style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Social Channels Connected
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Connected Channels', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildSocialTile(Icons.play_circle_fill, 'YouTube', user?.youtubeChannel ?? '@youtube_growth', Colors.redAccent),
                _buildSocialTile(Icons.camera_alt_rounded, 'Instagram', user?.instagramUsername ?? '@creator_brand', Colors.pinkAccent),
                _buildSocialTile(Icons.send_rounded, 'Telegram', user?.telegramChannel ?? '@growth_community', Colors.lightBlueAccent),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. System & Security Settings
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Security & Automation', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Biometric Fingerprint Lock', style: TextStyle(color: Colors.white, fontSize: 13)),
                  subtitle: const Text('Require fingerprint to open financial records', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  value: _biometricEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _biometricEnabled = val),
                ),
                const Divider(color: AppColors.cardBorder, height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Smart Cadence Reminders', style: TextStyle(color: Colors.white, fontSize: 13)),
                  subtitle: const Text('Notify daily for goals, work proof & earnings', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  value: _smartRemindersEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (val) async {
                    setState(() => _smartRemindersEnabled = val);
                    if (val) {
                      await NotificationService.instance.requestPermissions();
                    }
                  },
                ),
                if (_smartRemindersEnabled) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () async {
                        await NotificationService.instance.requestPermissions();
                        await NotificationService.instance.sendTestReminder();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.success,
                              content: Text('Test reminder sent! Check your notification bar. 🔔'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.notifications_active_rounded, size: 16, color: AppColors.primary),
                      label: const Text('Send Test Reminder Notification', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. AI & Administrative Shortcuts
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.cardBorder)),
            tileColor: AppColors.surface,
            leading: const Icon(Icons.monetization_on_rounded, color: AppColors.goldCoin),
            title: const Text('Gold Coins & Rewards Dashboard', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('View verified tasks, daily coin progress & withdraw funds', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsDashboardScreen()));
            },
          ),
          const SizedBox(height: 10),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.cardBorder)),
            tileColor: AppColors.surface,
            leading: const Icon(Icons.auto_awesome, color: AppColors.primary),
            title: const Text('Growth Intelligence Copilot', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Configure API keys and model parameters', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GrowthIntelligenceScreen()));
            },
          ),
          const SizedBox(height: 10),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.cardBorder)),
            tileColor: AppColors.surface,
            leading: const Icon(Icons.admin_panel_settings, color: AppColors.secondary),
            title: const Row(
              children: [
                Text('Owner Super-Admin Center', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                SizedBox(width: 6),
                Icon(Icons.lock_rounded, size: 14, color: AppColors.goldCoin),
              ],
            ),
            subtitle: const Text('Password-protected: User moderation & task verification', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: () => _promptAdminLogin(context),
          ),
          const SizedBox(height: 24),

          // 5. Sign Out Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger),
                foregroundColor: AppColors.danger,
              ),
              onPressed: () async {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign Out of GROWTH OS', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialTile(IconData icon, String platform, String handle, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text('$platform: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Text(handle, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _promptAdminLogin(BuildContext context) {
    final adminIdCtrl = TextEditingController();
    final adminPassCtrl = TextEditingController();
    bool obscure = true;
    bool isLoading = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.cardBorder),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Admin Verification',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This console is restricted to the platform owner. Enter your Admin ID & Password to access.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: adminIdCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Admin ID / Email',
                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      prefixIcon: const Icon(Icons.person_outline, size: 18),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: adminPassCtrl,
                    obscureText: obscure,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Admin Password',
                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      prefixIcon: const Icon(Icons.lock_outline, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () => setDialogState(() => obscure = !obscure),
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  if (errorMsg != null) ...[
                    const SizedBox(height: 10),
                    Text(errorMsg!, style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          final id = adminIdCtrl.text.trim();
                          final pass = adminPassCtrl.text;
                          if (id.isEmpty || pass.isEmpty) {
                            setDialogState(() => errorMsg = 'Please enter both Admin ID and Password');
                            return;
                          }
                          setDialogState(() {
                            isLoading = true;
                            errorMsg = null;
                          });
                          final success = await ref.read(adminProvider.notifier).authenticateAdmin(id, pass);
                          if (success) {
                            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                            if (context.mounted) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen()));
                            }
                          } else {
                            setDialogState(() {
                              isLoading = false;
                              errorMsg = 'Access Denied: Incorrect Admin ID or Password';
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Verify & Enter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

