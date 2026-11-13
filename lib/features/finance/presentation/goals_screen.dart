import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
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

