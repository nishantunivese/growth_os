import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/domain/auth_provider.dart';
import '../../finance/domain/finance_models.dart';
import '../../finance/domain/finance_provider.dart';
import '../../finance/presentation/add_transaction_modal.dart';
import '../../rewards/domain/reward_provider.dart';
import '../../rewards/presentation/rewards_dashboard_screen.dart';
import '../../tasks/domain/task_models.dart';
import '../../tasks/domain/task_provider.dart';
import '../../tasks/presentation/add_task_dialog.dart';
import '../../work/domain/project_provider.dart';
import '../../work/presentation/add_project_dialog.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profile = authState.user;
    final currency = profile?.preferredCurrency ?? '₹';

    final tasksState = ref.watch(tasksProvider);
    final projectsAsync = ref.watch(projectsProvider);
    final financeState = ref.watch(financeProvider);
    final rewardState = ref.watch(rewardProvider);

    final isSuspended = profile?.isSuspended ?? false;

    // Check if account is completely fresh (no goals, tasks, projects, earnings)
    final projectsList = projectsAsync.value ?? [];
    final isFreshAccount = tasksState.tasks.isEmpty &&
        projectsList.isEmpty &&
        financeState.incomeEntries.isEmpty &&
        financeState.goals.isEmpty;

    // Computed real metrics from database
    final now = DateTime.now();
    final todayIncomes = financeState.incomeEntries.where((i) {
      return i.date.year == now.year && i.date.month == now.month && i.date.day == now.day;
    });
    final todayEarnings = todayIncomes.fold(0.0, (sum, i) => sum + i.amount);

    final monthIncomes = financeState.incomeEntries.where((i) {
      return i.date.year == now.year && i.date.month == now.month;
    });
    final monthEarnings = monthIncomes.fold(0.0, (sum, i) => sum + i.amount);
    final monthTarget = profile?.monthlyEarningTarget ?? 100000.0;
    final netProfit = financeState.summary.netProfit;

    final completedTasksCount = tasksState.approvedCount;
    final pendingTasksCount = tasksState.pendingCount + tasksState.underReviewCount;
    final activeProjectsCount = projectsList.length;
    final currentStreak = profile?.streakCount ?? 1;

    final availableCoins = rewardState.balance.availableBalance;
    final todayVerifiedCount = rewardState.todayVerifiedCount;
    final isDailyUnlocked = rewardState.isDailyUnlocked;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(tasksProvider.notifier).loadTasks();
            await ref.read(rewardProvider.notifier).loadRewards();
            await ref.read(financeProvider.notifier).loadFinanceData();
          },
          color: AppColors.electricPurple,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // Top App Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'GROWTH OS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  color: AppColors.electricPurpleLight,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Streak Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.amberWarning.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.amberWarning.withOpacity(0.35)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.local_fire_department_rounded, color: AppColors.amberWarning, size: 14),
                                    const SizedBox(width: 3),
                                    Text(
                                      '$currentStreak DAYS',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.amberWarning),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile?.businessName.isNotEmpty == true ? profile!.businessName : (profile?.fullName ?? 'Command Center'),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ],
                      ),

                      // Right Side: Gold Coin Pill (Tap opens Rewards Dashboard)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RewardsDashboardScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.goldCoin.withOpacity(0.15),
                            border: Border.all(color: AppColors.goldCoin.withOpacity(0.4)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.monetization_on_rounded, color: AppColors.goldCoin, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '$availableCoins Coins',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.goldCoin),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Suspension Warning Alert if user is suspended/banned
              if (isSuspended)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.roseDanger.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.roseDanger.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.roseDanger, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile?.isBanned == true ? 'ACCOUNT PERMANENTLY BANNED' : 'ACCOUNT SUSPENDED',
                                  style: const TextStyle(color: AppColors.roseDanger, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  profile?.suspensionReason.isNotEmpty == true
                                      ? profile!.suspensionReason
                                      : 'You cannot submit new work or withdrawals. Existing data is preserved.',
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Daily Verified Work Progress Indicator Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                  child: _buildDailyVerifiedProgressCard(todayVerifiedCount, isDailyUnlocked),
                ),
              ),

              // If Fresh Account: Show empty dashboard with welcome message & 4 options
              if (isFreshAccount) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: _buildFreshAccountWelcomeCard(),
                  ),
                ),
              ] else ...[
                // Today's Focus Card (Recent Tasks)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                    child: _buildTodaysTasksFocusCard(tasksState.tasks),
                  ),
                ),

                // Financial Overview Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: _buildFinancialOverviewCard(currency, monthEarnings, monthTarget, todayEarnings, netProfit),
                  ),
                ),

                // Work Status Row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                    child: _buildWorkStatusRow(completedTasksCount, pendingTasksCount, activeProjectsCount),
                  ),
                ),

                // Earnings Chart
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: _buildEarningsChartCard(currency, financeState.incomeEntries),
                  ),
                ),
              ],

              const SliverToBoxAdapter(
                child: SizedBox(height: 90),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= 1. FRESH ACCOUNT WELCOME CARD =================
  Widget _buildFreshAccountWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.electricPurpleLight.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.electricPurple.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.electricPurple.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: AppColors.electricPurpleLight, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Welcome to Growth OS.',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Your growth journey starts today.',
            style: TextStyle(color: AppColors.emeraldGreenLight, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your account is completely fresh with zero pre-added demo data. Choose an action below to get started:',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
          ),
          const SizedBox(height: 20),

          // Option 1: Create your first goal
          _buildQuickStartOption(
            icon: Icons.track_changes_rounded,
            color: AppColors.cyberCyan,
            title: 'Create your first goal',
            subtitle: 'Set monthly or yearly revenue milestones',
            onTap: () => _openCreateGoalDialog(),
          ),
          const SizedBox(height: 10),

          // Option 2: Add your first work
          _buildQuickStartOption(
            icon: Icons.assignment_add,
            color: AppColors.electricPurpleLight,
            title: 'Add your first work',
            subtitle: 'Log a task, submit proof, and earn Gold Coins',
            onTap: () => _openAddTaskDialog(),
          ),
          const SizedBox(height: 10),

          // Option 3: Create a new project
          _buildQuickStartOption(
            icon: Icons.folder_special_rounded,
            color: AppColors.amberWarning,
            title: 'Create a new project',
            subtitle: 'Build a multi-stage process for Tenbox, Whop, or YouTube',
            onTap: () => _openAddProjectDialog(),
          ),
          const SizedBox(height: 10),

          // Option 4: Track your earnings
          _buildQuickStartOption(
            icon: Icons.currency_rupee_rounded,
            color: AppColors.emeraldGreen,
            title: 'Track your earnings',
            subtitle: 'Record an income or client payment',
            onTap: () => _openAddIncomeModal(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStartOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: AppColors.textDim, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textDim, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  // ================= 2. DAILY VERIFIED WORK PROGRESS =================
  Widget _buildDailyVerifiedProgressCard(int count, bool isUnlocked) {
    final progress = (count / 6).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? AppColors.goldCoin.withOpacity(0.4) : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isUnlocked ? Icons.verified_rounded : Icons.military_tech_rounded,
                    color: isUnlocked ? AppColors.emeraldGreen : AppColors.goldCoin,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Today's verified work: $count/6",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ),
              Text(
                isUnlocked ? '10 Coins Unlocked!' : 'Goal: 6 Tasks',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? AppColors.goldCoin : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isUnlocked
                ? 'Great job! You completed 6+ approved tasks today.'
                : 'Reward unlocked after 6 qualifying tasks.',
            style: TextStyle(
              fontSize: 11.5,
              color: isUnlocked ? AppColors.goldCoinLight : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(
                isUnlocked ? AppColors.emeraldGreen : AppColors.goldCoin,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= 3. TODAY'S TASKS FOCUS =================
  Widget _buildTodaysTasksFocusCard(List<Task> tasks) {
    final recentTasks = tasks.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(18),
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
              const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: AppColors.amberWarning, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "TODAY'S WORK FOCUS",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.8),
                  ),
                ],
              ),
              Text(
                '${tasks.length} total',
                style: TextStyle(fontSize: 12, color: AppColors.textDim, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (recentTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No active tasks yet. Tap "Add Work Task" to schedule your work.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            )
          else
            ...recentTasks.map((t) => _buildFocusItem(t)),
        ],
      ),
    );
  }

  Widget _buildFocusItem(Task task) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Icon(
            task.isApproved ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: task.isApproved ? AppColors.emeraldGreen : AppColors.textDim,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: task.isApproved ? FontWeight.w500 : FontWeight.w600,
                color: task.isApproved ? AppColors.textMuted : Colors.white,
                decoration: task.isApproved ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: task.status.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              task.status.displayName,
              style: TextStyle(color: task.status.color, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ================= 4. FINANCIAL OVERVIEW =================
  Widget _buildFinancialOverviewCard(String currency, double monthEarnings, double monthTarget, double todayEarnings, double netProfit) {
    final progressPct = monthTarget > 0 ? ((monthEarnings / monthTarget) * 100).clamp(0.0, 100.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
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
                'THIS MONTH EARNINGS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.8),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.emeraldGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${progressPct.toStringAsFixed(1)}% of Target',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.emeraldGreenLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$currency ${monthEarnings.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressPct / 100,
              minHeight: 8,
              backgroundColor: AppColors.backgroundElevated,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emeraldGreen),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric('Today', '$currency ${todayEarnings.toStringAsFixed(0)}', AppColors.electricPurpleLight),
              _buildMiniMetric('Net Profit', '$currency ${netProfit.toStringAsFixed(0)}', AppColors.emeraldGreenLight),
              _buildMiniMetric('Target', '$currency ${monthTarget.toStringAsFixed(0)}', AppColors.textMuted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textDim, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  // ================= 5. WORK STATUS ROW =================
  Widget _buildWorkStatusRow(int completed, int pending, int active) {
    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            title: 'Verified',
            count: '$completed',
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.emeraldGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            title: 'Pending',
            count: '$pending',
            icon: Icons.hourglass_top_rounded,
            color: AppColors.amberWarning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            title: 'Projects',
            count: '$active',
            icon: Icons.layers_outlined,
            color: AppColors.cyberCyan,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 11, color: AppColors.textDim, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ================= 6. EARNINGS CHART =================
  Widget _buildEarningsChartCard(String currency, dynamic incomeEntries) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              const Text(
                'Earnings Overview',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              Text(
                'Live Data',
                style: TextStyle(fontSize: 11, color: AppColors.textDim, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 1),
                      FlSpot(1, 3),
                      FlSpot(2, 2),
                      FlSpot(3, 5),
                      FlSpot(4, 4),
                      FlSpot(5, 7),
                      FlSpot(6, 6),
                    ],
                    isCurved: true,
                    color: AppColors.electricPurpleLight,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.electricPurple.withOpacity(0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog helpers
  void _openAddTaskDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTaskDialog(),
    );
  }

  void _openAddProjectDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddProjectDialog(),
    );
  }

  void _openAddIncomeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionModal(),
    );
  }

  void _openCreateGoalDialog() {
    final titleCtrl = TextEditingController(text: 'Monthly Platform Target');
    final targetCtrl = TextEditingController(text: '100000');
    final customPlatCtrl = TextEditingController();
    String selectedPlatform = 'YouTube';

    final platformList = ['YouTube', 'Instagram', 'Freelance', 'Upwork', 'Course Sales', 'All Platforms', 'Custom'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final isCustom = selectedPlatform == 'Custom';

          return AlertDialog(
            backgroundColor: AppColors.cardSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.flag_rounded, color: AppColors.primary, size: 22),
                SizedBox(width: 8),
                Text('Create Your First Goal', style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Goal Title', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(hintText: 'e.g. YouTube AdSense Target'),
                  ),
                  const SizedBox(height: 14),

                  const Text('Platform Name', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: platformList.map((p) {
                      final isSel = selectedPlatform == p;
                      return ChoiceChip(
                        label: Text(p),
                        selected: isSel,
                        onSelected: (val) {
                          if (val) setDialogState(() => selectedPlatform = p);
                        },
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.background,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  if (isCustom) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: customPlatCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(hintText: 'Enter platform name (e.g. TikTok, Substack)'),
                    ),
                  ],
                  const SizedBox(height: 14),

                  const Text('Target Amount (₹)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: targetCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(hintText: '100000', prefixText: '₹ '),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final target = double.tryParse(targetCtrl.text) ?? 100000.0;
                  final title = titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : 'Growth Goal';
                  final plat = isCustom ? customPlatCtrl.text.trim() : selectedPlatform;
                  final platformName = plat.isNotEmpty ? plat : 'All Platforms';

                  final current = ref.read(authProvider).user;
                  if (current != null) {
                    await ref.read(authProvider.notifier).updateProfile(
                      current.copyWith(monthlyEarningTarget: target),
                    );

                    final newGoal = FinancialGoal(
                      id: const Uuid().v4(),
                      userId: current.id,
                      title: title,
                      platformName: platformName,
                      period: GoalPeriod.monthly,
                      targetAmount: target,
                      startDate: DateTime.now(),
                      endDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    await ref.read(financeProvider.notifier).addGoal(newGoal);
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.emeraldGreen,
                      content: Text('Goal "$title" for $platformName created successfully! 🎯'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.electricPurple),
                child: const Text('Save Goal', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}
