import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../tasks/domain/task_models.dart';
import '../../withdrawal/domain/withdrawal_models.dart';
import '../domain/admin_provider.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login form controllers (strictly unpopulated for security)
  final _adminUserCtrl = TextEditingController();
  final _adminPassCtrl = TextEditingController();
  bool _obscurePass = true;

  // User search
  String _userSearchQuery = '';

  // Task filter
  String _taskFilter = 'All'; // All, Proof Submitted, Approved, Rejected

  // Withdrawal filter
  String _withdrawalFilter = 'All'; // All, Pending Review, Approved, Paid, Rejected

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _adminUserCtrl.dispose();
    _adminPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleAdminLogin() async {
    final user = _adminUserCtrl.text.trim();
    final pass = _adminPassCtrl.text;

    final success = await ref.read(adminProvider.notifier).authenticateAdmin(user, pass);
    if (!success && mounted) {
      final err = ref.read(adminProvider).error ?? 'Authentication failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.roseDanger, content: Text(err)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);

    if (!adminState.isAuthenticated) {
      return _buildAdminLoginScreen(adminState.isLoading);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Command Console'),
        backgroundColor: AppColors.cardSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Telemetry',
            onPressed: () => ref.read(adminProvider.notifier).loadAllAdminData(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.roseDanger),
            tooltip: 'Lock Session',
            onPressed: () => ref.read(adminProvider.notifier).logout(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.electricPurpleLight,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Task Verification'),
            Tab(text: 'Withdrawals'),
            Tab(text: 'Users'),
            Tab(text: 'Audit Logs'),
          ],
        ),
      ),
      body: adminState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.electricPurple))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(adminState.stats),
                _buildTaskVerificationTab(adminState.tasks, adminState.proofs),
                _buildWithdrawalTab(adminState.withdrawals),
                _buildUserManagementTab(adminState.users),
                _buildAuditLogsTab(adminState.auditLogs, adminState.activityLogs),
              ],
            ),
    );
  }

  // ================= ADMIN LOGIN SCREEN =================
  Widget _buildAdminLoginScreen(bool isLoading) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Super-Admin Authorization'),
        backgroundColor: AppColors.cardSurface,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.electricPurple.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, size: 44, color: AppColors.electricPurpleLight),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Growth OS Executive Admin',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Access verification queue, user moderation, reward allocations and withdrawal controls.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 24),

                // Username / Email
                TextField(
                  controller: _adminUserCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Admin Username / Email',
                    labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                TextField(
                  controller: _adminPassCtrl,
                  obscureText: _obscurePass,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Master Security Key / Password',
                    labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleAdminLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electricPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      isLoading ? 'Verifying Credentials...' : 'Authenticate Super-Admin',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
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

  // ================= 1. OVERVIEW TAB =================
  Widget _buildOverviewTab(AdminStats stats) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'System Telemetry & Metrics',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),

        // Grid of metric cards
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: [
            _buildStatCard('Total Registered Users', '${stats.totalRegisteredUsers}', Icons.people_outline_rounded, AppColors.electricPurpleLight),
            _buildStatCard('Active Users', '${stats.activeUsers}', Icons.check_circle_outline_rounded, AppColors.emeraldGreen),
            _buildStatCard('Banned / Suspended', '${stats.bannedUsers}', Icons.block_rounded, AppColors.roseDanger),
            _buildStatCard('Total Tasks Created', '${stats.totalSubmittedTasks}', Icons.task_alt_rounded, AppColors.cyberCyan),
            _buildStatCard('Awaiting Verification', '${stats.tasksAwaitingVerification}', Icons.pending_actions_rounded, AppColors.amberWarning),
            _buildStatCard('Approved Tasks', '${stats.approvedTasks}', Icons.verified_rounded, AppColors.emeraldGreen),
            _buildStatCard('Rejected Tasks', '${stats.rejectedTasks}', Icons.highlight_off_rounded, AppColors.roseDanger),
            _buildStatCard('Gold Coins Issued', '${stats.totalGoldCoinsIssued} (₹${stats.totalGoldCoinsIssued})', Icons.monetization_on_rounded, AppColors.goldCoin),
            _buildStatCard('Withdrawal Requests', '${stats.totalWithdrawalRequests}', Icons.account_balance_wallet_rounded, AppColors.cyberCyan),
            _buildStatCard('Pending Withdrawals', '${stats.pendingWithdrawals}', Icons.hourglass_top_rounded, AppColors.amberWarning),
            _buildStatCard('Total Paid Out', '₹${stats.totalAmountPaid}', Icons.payments_rounded, AppColors.emeraldGreen),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            val,
            style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  // ================= 2. TASK VERIFICATION TAB =================
  Widget _buildTaskVerificationTab(List<Task> tasks, List<TaskProof> proofs) {
    final filtered = tasks.where((t) {
      if (_taskFilter == 'Proof Submitted') {
        return t.status == TaskStatus.proofSubmitted || t.status == TaskStatus.underReview;
      } else if (_taskFilter == 'Approved') {
        return t.status == TaskStatus.approved;
      } else if (_taskFilter == 'Rejected') {
        return t.status == TaskStatus.rejected;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              _buildFilterChip('All', _taskFilter, (val) => setState(() => _taskFilter = val)),
              const SizedBox(width: 8),
              _buildFilterChip('Proof Submitted', _taskFilter, (val) => setState(() => _taskFilter = val)),
              const SizedBox(width: 8),
              _buildFilterChip('Approved', _taskFilter, (val) => setState(() => _taskFilter = val)),
              const SizedBox(width: 8),
              _buildFilterChip('Rejected', _taskFilter, (val) => setState(() => _taskFilter = val)),
            ],
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text('No tasks in this category.', style: TextStyle(color: AppColors.textSecondary)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final t = filtered[index];
                    final taskProofs = proofs.where((p) => p.taskId == t.id).toList();
                    final latestProof = taskProofs.isNotEmpty ? taskProofs.first : null;

                    return Container(
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
                                  color: t.status.color.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  t.status.displayName.toUpperCase(),
                                  style: TextStyle(color: t.status.color, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                'User: ${t.userId.length > 12 ? t.userId.substring(0, 12) : t.userId}',
                                style: TextStyle(color: AppColors.textDim, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          if (t.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(t.description, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            'Platform: ${t.platform.isNotEmpty ? t.platform : "General"} • Priority: ${t.priority.displayName}',
                            style: TextStyle(color: AppColors.textDim, fontSize: 11),
                          ),

                          // Proof Content Preview
                          if (latestProof != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Proof (${latestProof.proofType}) - ${latestProof.submittedDate} ${latestProof.submittedTime}',
                                        style: const TextStyle(color: AppColors.cyberCyan, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  if (latestProof.textProof != null && latestProof.textProof!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      latestProof.textProof!,
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ],
                                  if (latestProof.screenshotPath != null && latestProof.screenshotPath!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () => _openImageDialog(context, latestProof.screenshotPath!),
                                      child: Container(
                                        height: 120,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.black45,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: Image.file(
                                          File(latestProof.screenshotPath!),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Center(
                                            child: Text('Image file saved locally', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text('Tap image to view full screen', style: TextStyle(color: AppColors.textDim, fontSize: 10)),
                                  ],
                                ],
                              ),
                            ),
                          ],

                          // Rejection reason if already rejected
                          if (t.rejectionReason != null && t.rejectionReason!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('Rejection reason: ${t.rejectionReason}', style: const TextStyle(color: AppColors.roseDanger, fontSize: 11)),
                          ],

                          // Action Buttons for Verification
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _handleApproveTask(t.id),
                                  icon: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                                  label: const Text('Approve Work', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.emeraldGreen),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _handleRejectTaskDialog(t.id),
                                  icon: const Icon(Icons.close_rounded, color: AppColors.roseDanger, size: 16),
                                  label: const Text('Reject', style: TextStyle(color: AppColors.roseDanger, fontSize: 12)),
                                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.roseDanger)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openImageDialog(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(File(path)),
            ),
            const SizedBox(height: 12),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApproveTask(String taskId) async {
    final success = await ref.read(adminProvider.notifier).approveTask(taskId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppColors.emeraldGreen, content: Text('Task approved! Daily reward calculation evaluated.')),
      );
    }
  }

  void _handleRejectTaskDialog(String taskId) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text('Reject Work Proof', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter reason for rejection (required for user visibility):',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'e.g. Screenshot does not match task description, low quality, duplicate...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonCtrl.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx);
              await ref.read(adminProvider.notifier).rejectTask(taskId, reason);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.roseDanger),
            child: const Text('Confirm Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ================= 3. WITHDRAWALS TAB =================
  Widget _buildWithdrawalTab(List<WithdrawalRequest> withdrawals) {
    final filtered = withdrawals.where((w) {
      if (_withdrawalFilter != 'All') {
        return w.status.displayName == _withdrawalFilter;
      }
      return true;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              _buildFilterChip('All', _withdrawalFilter, (val) => setState(() => _withdrawalFilter = val)),
              const SizedBox(width: 8),
              _buildFilterChip('Pending Review', _withdrawalFilter, (val) => setState(() => _withdrawalFilter = val)),
              const SizedBox(width: 8),
              _buildFilterChip('Approved', _withdrawalFilter, (val) => setState(() => _withdrawalFilter = val)),
              const SizedBox(width: 8),
              _buildFilterChip('Paid', _withdrawalFilter, (val) => setState(() => _withdrawalFilter = val)),
            ],
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text('No withdrawal requests found.', style: TextStyle(color: AppColors.textSecondary)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final w = filtered[index];
                    return Container(
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
                              Text(
                                '₹${w.amount} (${w.amount} Coins)',
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: w.status.color.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  w.status.displayName.toUpperCase(),
                                  style: TextStyle(color: w.status.color, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Beneficiary: ${w.fullName} • UPI: ${w.upiId}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('User ID: ${w.userId}', style: TextStyle(color: AppColors.textDim, fontSize: 11)),
                          Text('Submitted: ${DateFormat('dd MMM yyyy, hh:mm a').format(w.submittedAt)} (Month: ${w.monthYear})', style: TextStyle(color: AppColors.textDim, fontSize: 11)),

                          if (w.rejectionReason != null) ...[
                            const SizedBox(height: 6),
                            Text('Rejection reason: ${w.rejectionReason}', style: const TextStyle(color: AppColors.roseDanger, fontSize: 11)),
                          ],
                          if (w.paymentRef != null) ...[
                            const SizedBox(height: 6),
                            Text('Payment Ref / UTR: ${w.paymentRef}', style: const TextStyle(color: AppColors.emeraldGreenLight, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],

                          const SizedBox(height: 14),

                          // Admin Actions: Approve, Reject (refunds coins), Mark as Paid
                          Row(
                            children: [
                              if (w.status == WithdrawalStatus.pendingReview) ...[
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => ref.read(adminProvider.notifier).approveWithdrawal(w.id),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.emeraldGreen),
                                    child: const Text('Approve', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _handleRejectWithdrawalDialog(w.id),
                                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.roseDanger)),
                                    child: const Text('Reject & Refund', style: TextStyle(color: AppColors.roseDanger, fontSize: 11)),
                                  ),
                                ),
                              ] else if (w.status == WithdrawalStatus.approved) ...[
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _handleMarkPaidDialog(w.id),
                                    icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                                    label: const Text('Mark as Paid (Enter UTR)', style: TextStyle(color: Colors.white, fontSize: 12)),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.electricPurple),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _handleRejectWithdrawalDialog(String reqId) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text('Reject Withdrawal Request', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reserved coins will be refunded immediately back to user. Please enter rejection reason:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(hintText: 'e.g. Invalid UPI ID, suspicious activity...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final r = reasonCtrl.text.trim();
              if (r.isEmpty) return;
              Navigator.pop(ctx);
              await ref.read(adminProvider.notifier).rejectWithdrawal(reqId, r);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.roseDanger),
            child: const Text('Confirm Reject & Refund', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleMarkPaidDialog(String reqId) {
    final utrCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text('Mark Withdrawal as Paid', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Bank Transaction Reference ID / UTR Number:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: utrCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(hintText: 'e.g. UTR249817293847'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final utr = utrCtrl.text.trim();
              if (utr.isEmpty) return;
              Navigator.pop(ctx);
              await ref.read(adminProvider.notifier).markWithdrawalPaid(reqId, utr);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emeraldGreen),
            child: const Text('Confirm Paid', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ================= 4. USERS TAB =================
  Widget _buildUserManagementTab(List<Map<String, dynamic>> users) {
    final filtered = users.where((u) {
      final name = (u['full_name'] as String? ?? '').toLowerCase();
      final email = (u['email'] as String? ?? '').toLowerCase();
      final id = (u['id'] as String? ?? '').toLowerCase();
      final query = _userSearchQuery.toLowerCase();
      return name.contains(query) || email.contains(query) || id.contains(query);
    }).toList();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            style: const TextStyle(color: Colors.white, fontSize: 13),
            onChanged: (val) => setState(() => _userSearchQuery = val),
            decoration: const InputDecoration(
              hintText: 'Search user by name, email, or user ID...',
              prefixIcon: Icon(Icons.search_rounded, size: 20),
            ),
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text('No users match search.', style: TextStyle(color: AppColors.textSecondary)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final u = filtered[index];
                    final userId = u['id'] as String;
                    final name = u['full_name'] as String? ?? 'User';
                    final email = u['email'] as String? ?? 'No email';
                    final status = u['status'] as String? ?? 'active';
                    final isSuspended = status == 'suspended' || status == 'banned';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSuspended ? AppColors.roseDanger.withOpacity(0.5) : AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSuspended ? AppColors.roseDanger.withOpacity(0.2) : AppColors.emeraldGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: isSuspended ? AppColors.roseDanger : AppColors.emeraldGreen,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Email: $email • ID: $userId', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          if (u['suspension_reason'] != null && (u['suspension_reason'] as String).isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Suspension reason: ${u['suspension_reason']}', style: const TextStyle(color: AppColors.roseDanger, fontSize: 11)),
                          ],

                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (!isSuspended) ...[
                                ElevatedButton(
                                  onPressed: () => _handleSuspendDialog(userId, name, isPermanentBan: false),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.amberWarning),
                                  child: const Text('Suspend', style: TextStyle(color: Colors.white, fontSize: 11)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _handleSuspendDialog(userId, name, isPermanentBan: true),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.roseDanger),
                                  child: const Text('Ban', style: TextStyle(color: Colors.white, fontSize: 11)),
                                ),
                              ] else ...[
                                ElevatedButton(
                                  onPressed: () => ref.read(adminProvider.notifier).unbanUser(userId),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.emeraldGreen),
                                  child: const Text('Unban / Restore', style: TextStyle(color: Colors.white, fontSize: 11)),
                                ),
                              ],
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () => _handleAddNoteDialog(userId, name),
                                child: const Text('Admin Note', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _handleSuspendDialog(String userId, String name, {required bool isPermanentBan}) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: Text(isPermanentBan ? 'Permanently Ban $name' : 'Suspend $name', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select or write suspension reason. User will not be able to submit tasks or withdrawals:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(hintText: 'e.g. Low quality submissions, duplicate proofs...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final r = reasonCtrl.text.trim();
              if (r.isEmpty) return;
              Navigator.pop(ctx);
              await ref.read(adminProvider.notifier).suspendUser(userId, r, isPermanentBan: isPermanentBan);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.roseDanger),
            child: Text(isPermanentBan ? 'Confirm Ban' : 'Confirm Suspend', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleAddNoteDialog(String userId, String name) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: Text('Admin Note for $name', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: noteCtrl,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: const InputDecoration(hintText: 'Internal note visible only to admins...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final n = noteCtrl.text.trim();
              if (n.isEmpty) return;
              Navigator.pop(ctx);
              await ref.read(adminProvider.notifier).addAdminNote(userId, n);
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  // ================= 5. AUDIT LOGS TAB =================
  Widget _buildAuditLogsTab(List<Map<String, dynamic>> auditLogs, List<Map<String, dynamic>> activityLogs) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Admin Audit Log', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        if (auditLogs.isEmpty)
          Text('No admin audit records yet.', style: TextStyle(color: AppColors.textDim))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: auditLogs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final a = auditLogs[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(a['action'] as String? ?? 'action', style: const TextStyle(color: AppColors.electricPurpleLight, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text(a['created_at'] != null ? DateFormat('dd MMM, hh:mm a').format(DateTime.parse(a['created_at'])) : '', style: TextStyle(color: AppColors.textDim, fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(a['detail'] as String? ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              );
            },
          ),

        const SizedBox(height: 24),
        const Text('User Activity Stream', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        if (activityLogs.isEmpty)
          Text('No user activity recorded yet.', style: TextStyle(color: AppColors.textDim))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activityLogs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final act = activityLogs[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(act['action'] as String? ?? '', style: const TextStyle(color: AppColors.cyberCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text(act['created_at'] != null ? DateFormat('dd MMM, hh:mm a').format(DateTime.parse(act['created_at'])) : '', style: TextStyle(color: AppColors.textDim, fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(act['detail'] as String? ?? '', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String currentVal, Function(String) onSelect) {
    final isSelected = label == currentVal;
    return GestureDetector(
      onTap: () => onSelect(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.electricPurple : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.electricPurpleLight : AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
