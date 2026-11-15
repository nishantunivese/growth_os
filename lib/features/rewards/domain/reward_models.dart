class GoldCoinBalance {
  final String userId;
  final int totalEarned;
  final int availableBalance;
  final int pendingRewards;
  final int totalWithdrawn;
  final DateTime lastCalculatedAt;

  GoldCoinBalance({
    required this.userId,
    this.totalEarned = 0,
    this.availableBalance = 0,
    this.pendingRewards = 0,
    this.totalWithdrawn = 0,
    required this.lastCalculatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'total_earned': totalEarned,
      'available_balance': availableBalance,
      'pending_rewards': pendingRewards,
      'total_withdrawn': totalWithdrawn,
      'last_calculated_at': lastCalculatedAt.toIso8601String(),
    };
  }

  factory GoldCoinBalance.fromMap(Map<String, dynamic> map) {
    return GoldCoinBalance(
      userId: map['user_id'] as String? ?? '',
      totalEarned: (map['total_earned'] as num?)?.toInt() ?? 0,
      availableBalance: (map['available_balance'] as num?)?.toInt() ?? 0,
      pendingRewards: (map['pending_rewards'] as num?)?.toInt() ?? 0,
      totalWithdrawn: (map['total_withdrawn'] as num?)?.toInt() ?? 0,
      lastCalculatedAt: DateTime.tryParse(map['last_calculated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  GoldCoinBalance copyWith({
    int? totalEarned,
    int? availableBalance,
    int? pendingRewards,
    int? totalWithdrawn,
    DateTime? lastCalculatedAt,
  }) {
    return GoldCoinBalance(
      userId: userId,
      totalEarned: totalEarned ?? this.totalEarned,
      availableBalance: availableBalance ?? this.availableBalance,
      pendingRewards: pendingRewards ?? this.pendingRewards,
      totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
      lastCalculatedAt: lastCalculatedAt ?? this.lastCalculatedAt,
    );
  }
}

class RewardTransaction {
  final String id;
  final String userId;
  final int coins;
  final String reason;
  final String rewardDate; // YYYY-MM-DD
  final int taskCount;
  final DateTime createdAt;

  RewardTransaction({
    required this.id,
    required this.userId,
    required this.coins,
    required this.reason,
    required this.rewardDate,
    required this.taskCount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'coins': coins,
      'reason': reason,
      'reward_date': rewardDate,
      'task_count': taskCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory RewardTransaction.fromMap(Map<String, dynamic> map) {
    return RewardTransaction(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? '',
      coins: (map['coins'] as num?)?.toInt() ?? 0,
      reason: map['reason'] as String? ?? '',
      rewardDate: map['reward_date'] as String? ?? '',
      taskCount: (map['task_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
