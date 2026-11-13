import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/local_db_service.dart';
import '../../../core/network/supabase_config.dart';
import '../../auth/domain/auth_provider.dart';
import 'finance_models.dart';

class FinanceState {
  final List<FinancialGoal> goals;
  final List<IncomeEntry> incomeEntries;
  final List<ExpenseEntry> expenseEntries;
  final FinancialSummary summary;
  final bool isLoading;

  FinanceState({
    required this.goals,
    required this.incomeEntries,
    required this.expenseEntries,
    required this.summary,
    this.isLoading = false,
  });

  FinanceState copyWith({
    List<FinancialGoal>? goals,
    List<IncomeEntry>? incomeEntries,
    List<ExpenseEntry>? expenseEntries,
    FinancialSummary? summary,
    bool? isLoading,
  }) {
    return FinanceState(
      goals: goals ?? this.goals,
      incomeEntries: incomeEntries ?? this.incomeEntries,
      expenseEntries: expenseEntries ?? this.expenseEntries,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final financeProvider = StateNotifierProvider<FinanceNotifier, FinanceState>((ref) {
  final user = ref.watch(authProvider).user;
  return FinanceNotifier(ref, user?.id ?? 'demo-user-id');
});

class FinanceNotifier extends StateNotifier<FinanceState> {
  final Ref ref;
  final String userId;

  FinanceNotifier(this.ref, this.userId)
      : super(FinanceState(
          goals: [],
          incomeEntries: [],
          expenseEntries: [],
          summary: FinancialSummary(
            grossRevenue: 0,
            totalExpenses: 0,
            totalRefunds: 0,
            netProfit: 0,
            todayEarnings: 0,
            thisWeekEarnings: 0,
            thisMonthEarnings: 0,
            bestEarningSource: 'None',
            platformBreakdown: {},
          ),
          isLoading: true,
        )) {
    loadFinanceData();
  }

  Future<void> loadFinanceData() async {
    state = state.copyWith(isLoading: true);

    try {
      final incomeMaps = await LocalDbService.instance.getIncome();
      final expenseMaps = await LocalDbService.instance.getExpenses();

      List<IncomeEntry> incomes = incomeMaps.map((m) => IncomeEntry.fromMap(m)).toList();
      List<ExpenseEntry> expenses = expenseMaps.map((m) => ExpenseEntry.fromMap(m)).toList();

      // Seed initial realistic entrepreneurial data if empty
      if (incomes.isEmpty) {
        final now = DateTime.now();
        incomes = [
          IncomeEntry(
            id: 'inc-001',
            userId: userId,
            amount: 24500.0,
            date: now.subtract(const Duration(days: 1)),
            platformSource: 'Tenbox',
            incomeCategory: 'Affiliate Payout',
            description: 'Weekly payout for clipping viral hooks',
            paymentStatus: 'Received',
          ),
          IncomeEntry(
            id: 'inc-002',
            userId: userId,
            amount: 18000.0,
            date: now.subtract(const Duration(days: 3)),
            platformSource: 'Whop',
            incomeCategory: 'Membership Subscriptions',
            description: 'Growth OS Mastermind community tier',
            paymentStatus: 'Received',
          ),
          IncomeEntry(
            id: 'inc-003',
            userId: userId,
            amount: 15000.0,
            date: now.subtract(const Duration(days: 6)),
            platformSource: 'Course sales',
            incomeCategory: 'Digital Product',
            description: 'AI Video Monetization Blueprint 2.0',
            paymentStatus: 'Received',
          ),
          IncomeEntry(
            id: 'inc-004',
            userId: userId,
            amount: 9800.0,
            date: now.subtract(const Duration(days: 11)),
            platformSource: 'YouTube',
            incomeCategory: 'AdSense',
            description: 'Monthly ad revenue from Shorts & long form',
            paymentStatus: 'Received',
          ),
        ];
        for (var inc in incomes) {
          await LocalDbService.instance.upsertIncome(inc.toMap());
        }
      }

      if (expenses.isEmpty) {
        final now = DateTime.now();
        expenses = [
          ExpenseEntry(
            id: 'exp-001',
            userId: userId,
            amount: 3200.0,
            date: now.subtract(const Duration(days: 2)),
            category: 'Software',
            description: 'Midjourney & ElevenLabs API subscriptions',
          ),
          ExpenseEntry(
            id: 'exp-002',
            userId: userId,
            amount: 5000.0,
            date: now.subtract(const Duration(days: 5)),
            category: 'Ads',
            description: 'Meta Ads test campaign for course funnel',
          ),
          ExpenseEntry(
            id: 'exp-003',
            userId: userId,
            amount: 1200.0,
            date: now.subtract(const Duration(days: 7)),
            category: 'Refund',
            description: 'Customer requested accidental double purchase refund',
            isRefund: true,
          ),
        ];
        for (var exp in expenses) {
          await LocalDbService.instance.upsertExpense(exp.toMap());
        }
      }

      // Default monthly and yearly goals
      final now = DateTime.now();
      final goals = [
        FinancialGoal(
          id: 'goal-month-1',
          userId: userId,
          title: 'Monthly Earning Target',
          period: GoalPeriod.monthly,
          targetAmount: 100000.0,
          currentAmount: incomes.fold(0.0, (sum, item) => sum + item.amount),
          startDate: DateTime(now.year, now.month, 1),
          endDate: DateTime(now.year, now.month + 1, 0),
        ),
        FinancialGoal(
          id: 'goal-year-1',
          userId: userId,
          title: 'Annual Scale Goal',
          period: GoalPeriod.yearly,
          targetAmount: 1200000.0,
          currentAmount: incomes.fold(0.0, (sum, item) => sum + item.amount),
          startDate: DateTime(now.year, 1, 1),
          endDate: DateTime(now.year, 12, 31),
        ),
      ];

      final summary = _calculateSummary(incomes, expenses);

      state = FinanceState(
        goals: goals,
        incomeEntries: incomes,
        expenseEntries: expenses,
        summary: summary,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  FinancialSummary _calculateSummary(List<IncomeEntry> incomes, List<ExpenseEntry> expenses) {
    double grossRevenue = 0;
    double totalExpenses = 0;
    double totalRefunds = 0;
    double todayEarnings = 0;
    double thisWeekEarnings = 0;
    double thisMonthEarnings = 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    final Map<String, double> platformBreakdown = {};

    for (var inc in incomes) {
      grossRevenue += inc.amount;
      platformBreakdown[inc.platformSource] = (platformBreakdown[inc.platformSource] ?? 0.0) + inc.amount;

      if (inc.date.isAfter(today) || inc.date.isAtSameMomentAs(today)) {
        todayEarnings += inc.amount;
      }
      if (inc.date.isAfter(weekStart)) {
        thisWeekEarnings += inc.amount;
      }
      if (inc.date.isAfter(monthStart)) {
        thisMonthEarnings += inc.amount;
      }
    }

    for (var exp in expenses) {
      if (exp.isRefund) {
        totalRefunds += exp.amount;
      } else {
        totalExpenses += exp.amount;
      }
    }

    final netProfit = grossRevenue - totalExpenses - totalRefunds;

    String bestSource = 'None';
    double maxSourceAmount = 0;
    platformBreakdown.forEach((source, amount) {
      if (amount > maxSourceAmount) {
        maxSourceAmount = amount;
        bestSource = source;
      }
    });

    return FinancialSummary(
      grossRevenue: grossRevenue,
      totalExpenses: totalExpenses,
      totalRefunds: totalRefunds,
      netProfit: netProfit,
      todayEarnings: todayEarnings,
      thisWeekEarnings: thisWeekEarnings,
      thisMonthEarnings: thisMonthEarnings,
      bestEarningSource: bestSource,
      platformBreakdown: platformBreakdown,
    );
  }

  Future<void> addIncome(IncomeEntry entry) async {
    await LocalDbService.instance.upsertIncome(entry.toMap());
    final updated = [entry, ...state.incomeEntries];
    final summary = _calculateSummary(updated, state.expenseEntries);
    state = state.copyWith(incomeEntries: updated, summary: summary);

    if (SupabaseConfig.isConfigured) {
      try {
        await SupabaseConfig.client.from('income_entries').insert(entry.toMap());
      } catch (_) {
        await LocalDbService.instance.addToSyncQueue(
          table: 'income_entries',
          operation: 'INSERT',
          payload: entry.toMap(),
        );
      }
    }
  }

  Future<void> addExpense(ExpenseEntry entry) async {
    await LocalDbService.instance.upsertExpense(entry.toMap());
    final updated = [entry, ...state.expenseEntries];
    final summary = _calculateSummary(state.incomeEntries, updated);
    state = state.copyWith(expenseEntries: updated, summary: summary);

    if (SupabaseConfig.isConfigured) {
      try {
        await SupabaseConfig.client.from('expense_entries').insert(entry.toMap());
      } catch (_) {
        await LocalDbService.instance.addToSyncQueue(
          table: 'expense_entries',
          operation: 'INSERT',
          payload: entry.toMap(),
        );
      }
    }
  }
}

