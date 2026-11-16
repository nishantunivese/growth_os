import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/report_export_service.dart';
import '../../auth/domain/auth_provider.dart';
import '../domain/finance_models.dart';
import '../domain/finance_provider.dart';
import 'add_transaction_modal.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  String _ledgerFilter = 'All'; // All, Income, Expense

  @override
  Widget build(BuildContext context) {
    final financeState = ref.watch(financeProvider);
    final profile = ref.watch(authProvider).user;
    final summary = financeState.summary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cash Flow & Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.secondary),
            tooltip: 'Export PDF Statement',
            onPressed: () {
              ReportExportService.exportPdfReport(
                context: context,
                incomes: financeState.incomeEntries,
                expenses: financeState.expenseEntries,
                summary: summary,
                businessName: profile?.businessName ?? 'Growth OS Business',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: AppColors.primary),
            tooltip: 'Export CSV Ledger',
            onPressed: () {
              final csv = ReportExportService.generateCsvReport(
                incomes: financeState.incomeEntries,
                expenses: financeState.expenseEntries,
                summary: summary,
                userName: profile?.fullName ?? 'Entrepreneur',
              );
              Share.share(csv, subject: 'Growth OS Financial Ledger');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AddTransactionModal(),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: financeState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Executive Cash Flow Summary Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: _buildExecutiveCashFlowCard(summary),
                  ),
                ),

                // 2. Financial Target Rings (Monthly & Yearly)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Milestone Goal Rings',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildGoalRingCard(
                                title: 'Monthly Target',
                                target: 100000,
                                current: summary.thisMonthEarnings,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGoalRingCard(
                                title: 'Annual Target',
                                target: 1200000,
                                current: summary.grossRevenue,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 2B. Platform & Custom Goals Section (with Platform Name support)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: _buildPlatformGoalsSection(financeState),
                  ),
                ),

                // 3. Platform Distribution
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: _buildPlatformBreakdownCard(summary),
                  ),
                ),

                // 4. Ledger Filter Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transaction Ledger',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: ['All', 'Income', 'Expense'].map((f) {
                            final isSel = _ledgerFilter == f;
                            return GestureDetector(
                              onTap: () => setState(() => _ledgerFilter = f),
                              child: Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSel ? AppColors.primary : AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isSel ? AppColors.primary : AppColors.cardBorder),
                                ),
                                child: Text(
                                  f,
                                  style: TextStyle(
                                    color: isSel ? Colors.white : AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                // 5. Detailed Transactions List
                _buildLedgerList(financeState),
              ],
            ),
    );
  }

  Widget _buildExecutiveCashFlowCard(FinancialSummary summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            AppColors.primary.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'NET REALIZED PROFIT',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      'Top: ${summary.bestEarningSource}',
                      style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${summary.netProfit.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          const SizedBox(height: 18),
          const Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 14),

          // 3 Column Grid: Gross, Expenses, Refunds
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric('Gross Revenue', '₹${summary.grossRevenue.toStringAsFixed(0)}', AppColors.primary),
              _buildMiniMetric('Expenses', '₹${summary.totalExpenses.toStringAsFixed(0)}', AppColors.danger),
              _buildMiniMetric('Refunds', '₹${summary.totalRefunds.toStringAsFixed(0)}', AppColors.warning),
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
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildGoalRingCard({
    required String title,
    required double target,
    required double current,
    required Color color,
  }) {
    final pct = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final pctInt = (pct * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text('$pctInt%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '₹${current.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            'of ₹${target.toStringAsFixed(0)}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: AppColors.cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformGoalsSection(FinanceState financeState) {
    final goals = financeState.goals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Platform Goals',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                if (goals.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                    ),
                    child: Text(
                      '${goals.length}',
                      style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            TextButton.icon(
              onPressed: () => _showAddGoalModal(context),
              icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.primary),
              label: const Text('Add Goal', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (goals.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                const Icon(Icons.flag_outlined, color: AppColors.primary, size: 36),
                const SizedBox(height: 8),
                const Text(
                  'No Platform Goals Yet',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Set target earnings for YouTube, Instagram, Freelancing, Upwork, or Courses.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _showAddGoalModal(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Create Your First Goal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: goals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final goal = goals[i];
              return _buildPlatformGoalCard(goal);
            },
          ),
      ],
    );
  }

  Widget _buildPlatformGoalCard(FinancialGoal goal) {
    final pct = (goal.progressPercentage / 100.0).clamp(0.0, 1.0);
    final isDone = goal.isCompleted || pct >= 1.0;

    // Platform theme coloring and badge
    Color platformColor = AppColors.primary;
    IconData platformIcon = Icons.public;
    final platLower = goal.platformName.toLowerCase();
    if (platLower.contains('youtube')) {
      platformColor = const Color(0xFFFF0000);
      platformIcon = Icons.smart_display;
    } else if (platLower.contains('instagram')) {
      platformColor = const Color(0xFFE1306C);
      platformIcon = Icons.camera_alt;
    } else if (platLower.contains('freelance') || platLower.contains('upwork')) {
      platformColor = const Color(0xFF14A800);
      platformIcon = Icons.work_outline;
    } else if (platLower.contains('course') || platLower.contains('education')) {
      platformColor = const Color(0xFF9C27B0);
      platformIcon = Icons.school_outlined;
    } else if (platLower.contains('client') || platLower.contains('agency')) {
      platformColor = const Color(0xFF00ACC1);
      platformIcon = Icons.business_center_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? AppColors.success.withOpacity(0.5) : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Platform badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: platformColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: platformColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(platformIcon, size: 13, color: platformColor),
                    const SizedBox(width: 4),
                    Text(
                      goal.platformName,
                      style: TextStyle(
                        color: platformColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Period chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  goal.period.name.toUpperCase(),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              if (isDone)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success, size: 12),
                      SizedBox(width: 3),
                      Text('Achieved!', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text('Delete Goal?', style: TextStyle(color: Colors.white)),
                      content: Text('Are you sure you want to delete "${goal.title}"?', style: const TextStyle(color: AppColors.textSecondary)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref.read(financeProvider.notifier).deleteGoal(goal.id);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            goal.title,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${goal.currentAmount.toStringAsFixed(0)} / ₹${goal.targetAmount.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text(
                '${goal.progressPercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isDone ? AppColors.success : platformColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(isDone ? AppColors.success : platformColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isDone
                ? 'Goal Target reached! Outstanding work! 🎉'
                : '₹${goal.remainingAmount.toStringAsFixed(0)} remaining to reach target',
            style: TextStyle(
              color: isDone ? AppColors.success : AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddGoalModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final customPlatformCtrl = TextEditingController();
    String selectedPlatform = 'YouTube';
    GoalPeriod selectedPeriod = GoalPeriod.monthly;
    DateTime selectedEndDate = DateTime.now().add(const Duration(days: 30));

    final platforms = [
      'YouTube',
      'Instagram',
      'Freelance',
      'Upwork',
      'Course Sales',
      'Client Projects',
      'All Platforms',
      'Custom',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isCustom = selectedPlatform == 'Custom';

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add New Financial Goal',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Goal Title
                    const Text('Goal Title', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g. YouTube AdSense Target, Course Launch',
                        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        filled: true,
                        fillColor: AppColors.cardSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Platform Name Option
                    const Text('Platform Name', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: platforms.map((p) {
                        final isSel = selectedPlatform == p;
                        return ChoiceChip(
                          label: Text(p),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) setModalState(() => selectedPlatform = p);
                          },
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.cardSurface,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    if (isCustom) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: customPlatformCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Enter Custom Platform Name (e.g. TikTok, Substack)',
                          hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          filled: true,
                          fillColor: AppColors.cardSurface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Target Amount
                    const Text('Target Amount (₹)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g. 50000',
                        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        prefixText: '₹ ',
                        prefixStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        filled: true,
                        fillColor: AppColors.cardSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Goal Period & Target Date
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Period', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.cardSurface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<GoalPeriod>(
                                    value: selectedPeriod,
                                    dropdownColor: AppColors.cardSurface,
                                    isExpanded: true,
                                    items: GoalPeriod.values.map((gp) {
                                      return DropdownMenuItem(
                                        value: gp,
                                        child: Text(
                                          gp.name[0].toUpperCase() + gp.name.substring(1),
                                          style: const TextStyle(color: Colors.white, fontSize: 13),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => selectedPeriod = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Target Date', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: modalCtx,
                                    initialDate: selectedEndDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 1825)),
                                  );
                                  if (picked != null) {
                                    setModalState(() => selectedEndDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardSurface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('dd MMM yyyy').format(selectedEndDate),
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                      const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final title = titleCtrl.text.trim();
                          final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                          final plat = isCustom ? customPlatformCtrl.text.trim() : selectedPlatform;

                          if (title.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a goal title')),
                            );
                            return;
                          }
                          if (amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid target amount')),
                            );
                            return;
                          }

                          final authState = ref.read(authProvider);
                          final userId = authState.user?.id ?? 'user_${DateTime.now().millisecondsSinceEpoch}';

                          final newGoal = FinancialGoal(
                            id: const Uuid().v4(),
                            userId: userId,
                            title: title,
                            platformName: plat.isNotEmpty ? plat : 'All Platforms',
                            period: selectedPeriod,
                            targetAmount: amount,
                            startDate: DateTime.now(),
                            endDate: selectedEndDate,
                          );

                          await ref.read(financeProvider.notifier).addGoal(newGoal);
                          if (modalCtx.mounted) Navigator.pop(modalCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.success,
                              content: Text('Goal "$title" created for $plat! 🎯'),
                            ),
                          );
                        },
                        child: const Text(
                          'Save Financial Goal',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlatformBreakdownCard(FinancialSummary summary) {
    if (summary.platformBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue by Platform & Channel',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          ...summary.platformBreakdown.entries.map((e) {
            final pct = summary.grossRevenue > 0 ? (e.value / summary.grossRevenue) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      Text('₹${e.value.toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(0)}%)',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 4,
                      backgroundColor: AppColors.cardBorder,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLedgerList(FinanceState state) {
    final List<Map<String, dynamic>> combined = [];

    if (_ledgerFilter == 'All' || _ledgerFilter == 'Income') {
      for (var inc in state.incomeEntries) {
        combined.add({
          'isIncome': true,
          'title': inc.platformSource,
          'subtitle': inc.description,
          'amount': inc.amount,
          'date': inc.date,
          'status': inc.paymentStatus,
        });
      }
    }

    if (_ledgerFilter == 'All' || _ledgerFilter == 'Expense') {
      for (var exp in state.expenseEntries) {
        combined.add({
          'isIncome': false,
          'title': exp.isRefund ? 'Refund: ${exp.category}' : exp.category,
          'subtitle': exp.description,
          'amount': exp.amount,
          'date': exp.date,
          'status': 'Paid',
        });
      }
    }

    combined.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    if (combined.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No transactions recorded for this filter.', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final tx = combined[index];
            final isInc = tx['isIncome'] as bool;
            final date = tx['date'] as DateTime;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isInc ? AppColors.success.withOpacity(0.12) : AppColors.danger.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isInc ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    color: isInc ? AppColors.success : AppColors.danger,
                    size: 18,
                  ),
                ),
                title: Text(
                  tx['title'],
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${tx['subtitle']}  •  ${date.day}/${date.month}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                trailing: Text(
                  '${isInc ? '+' : '-'}₹${(tx['amount'] as double).toStringAsFixed(0)}',
                  style: TextStyle(
                    color: isInc ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          },
          childCount: combined.length,
        ),
      ),
    );
  }
}

