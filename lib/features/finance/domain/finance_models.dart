enum GoalPeriod {
  daily,
  weekly,
  monthly,
  yearly,
  custom,
}

class FinancialGoal {
  final String id;
  final String userId;
  final String title;
  final GoalPeriod period;
  final double targetAmount;
  final double currentAmount;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCompleted;

  FinancialGoal({
    required this.id,
    required this.userId,
    required this.title,
    required this.period,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.startDate,
    required this.endDate,
    this.isCompleted = false,
  });

  double get progressPercentage => targetAmount > 0 ? (currentAmount / targetAmount) * 100.0 : 0.0;
  double get remainingAmount => (targetAmount - currentAmount).clamp(0.0, double.infinity);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'period': period.name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory FinancialGoal.fromMap(Map<String, dynamic> map) {
    return FinancialGoal(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      title: map['title'] ?? '',
      period: GoalPeriod.values.firstWhere(
        (e) => e.name == map['period'],
        orElse: () => GoalPeriod.monthly,
      ),
      targetAmount: (map['target_amount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (map['current_amount'] as num?)?.toDouble() ?? 0.0,
      startDate: map['start_date'] != null ? DateTime.parse(map['start_date']) : DateTime.now(),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : DateTime.now().add(const Duration(days: 30)),
      isCompleted: map['is_completed'] == 1 || map['is_completed'] == true,
    );
  }
}

class IncomeEntry {
  final String id;
  final String userId;
  final double amount;
  final DateTime date;
  final String platformSource; // Tenbox, Whop, Course sales, Paid group, YouTube, Affiliate, Brand, Client, Other
  final String incomeCategory;
  final String description;
  final String paymentStatus; // Received, Pending, Processing
  final String? paymentScreenshotUrl;
  final String notes;

  IncomeEntry({
    required this.id,
    required this.userId,
    required this.amount,
    required this.date,
    required this.platformSource,
    this.incomeCategory = 'Business',
    this.description = '',
    this.paymentStatus = 'Received',
    this.paymentScreenshotUrl,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'date': date.toIso8601String(),
      'platform_source': platformSource,
      'income_category': incomeCategory,
      'description': description,
      'payment_status': paymentStatus,
      'payment_screenshot_url': paymentScreenshotUrl,
      'notes': notes,
    };
  }

  factory IncomeEntry.fromMap(Map<String, dynamic> map) {
    return IncomeEntry(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      platformSource: map['platform_source'] ?? 'General',
      incomeCategory: map['income_category'] ?? 'Business',
      description: map['description'] ?? '',
      paymentStatus: map['payment_status'] ?? 'Received',
      paymentScreenshotUrl: map['payment_screenshot_url'],
      notes: map['notes'] ?? '',
    );
  }
}

class ExpenseEntry {
  final String id;
  final String userId;
  final double amount;
  final DateTime date;
  final String category; // Software, Ads, Equipment, Freelancer, Refund, Operational
  final String description;
  final bool isRefund;
  final String notes;

  ExpenseEntry({
    required this.id,
    required this.userId,
    required this.amount,
    required this.date,
    required this.category,
    this.description = '',
    this.isRefund = false,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'description': description,
      'is_refund': isRefund ? 1 : 0,
      'notes': notes,
    };
  }

  factory ExpenseEntry.fromMap(Map<String, dynamic> map) {
    return ExpenseEntry(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      category: map['category'] ?? 'General',
      description: map['description'] ?? '',
      isRefund: map['is_refund'] == 1 || map['is_refund'] == true,
      notes: map['notes'] ?? '',
    );
  }
}

class FinancialSummary {
  final double grossRevenue;
  final double totalExpenses;
  final double totalRefunds;
  final double netProfit;
  final double todayEarnings;
  final double thisWeekEarnings;
  final double thisMonthEarnings;
  final String bestEarningSource;
  final Map<String, double> platformBreakdown;

  FinancialSummary({
    required this.grossRevenue,
    required this.totalExpenses,
    required this.totalRefunds,
    required this.netProfit,
    required this.todayEarnings,
    required this.thisWeekEarnings,
    required this.thisMonthEarnings,
    required this.bestEarningSource,
    required this.platformBreakdown,
  });
}

