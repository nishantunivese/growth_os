import 'package:intl/intl.dart';
import '../../../core/database/local_db_service.dart';
import 'reward_models.dart';

class RewardCalculationResult {
  final int todayVerifiedCount;
  final bool isRewardUnlocked;
  final bool coinsAwardedJustNow;
  final int coinsAwarded;
  final String message;

  RewardCalculationResult({
    required this.todayVerifiedCount,
    required this.isRewardUnlocked,
    required this.coinsAwardedJustNow,
    this.coinsAwarded = 0,
    required this.message,
  });
}

class RewardService {
  RewardService._();
  static final RewardService instance = RewardService._();

  /// Calculate and automatically award gold coins if eligible for today
  Future<RewardCalculationResult> evaluateDailyReward(String userId, {String? targetDate}) async {
    final dateStr = targetDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 1. Fetch approved tasks for user
    final allUserTasks = await LocalDbService.instance.getTasks(userId, status: 'Approved');

    // Filter tasks approved on or submitted on target calendar date that are qualifying
    final qualifyingToday = allUserTasks.where((t) {
      final isQualifying = t['is_qualifying'] == 1 || t['is_qualifying'] == true;
      if (!isQualifying) return false;

      final updatedAt = t['updated_at'] as String? ?? '';
      final createdAt = t['created_at'] as String? ?? '';
      final taskDate = updatedAt.isNotEmpty ? updatedAt.substring(0, 10) : createdAt.substring(0, 10);

      return taskDate == dateStr;
    }).toList();

    final verifiedCount = qualifyingToday.length;

    // 2. Check if user already received reward for this calendar date
    final existingTxs = await LocalDbService.query(
      'reward_transactions',
      where: 'user_id = ? AND reward_date = ?',
      whereArgs: [userId, dateStr],
    );

    final alreadyClaimed = existingTxs.isNotEmpty;

    // Rule: More than 5 qualifying tasks (i.e. >= 6) unlocks 10 Gold Coins
    if (verifiedCount < 6) {
      return RewardCalculationResult(
        todayVerifiedCount: verifiedCount,
        isRewardUnlocked: false,
        coinsAwardedJustNow: false,
        coinsAwarded: 0,
        message: "Today's verified work: $verifiedCount/6. Reward unlocked after 6 qualifying tasks.",
      );
    }

    if (alreadyClaimed) {
      return RewardCalculationResult(
        todayVerifiedCount: verifiedCount,
        isRewardUnlocked: true,
        coinsAwardedJustNow: false,
        coinsAwarded: 0,
        message: "Today's verified work: $verifiedCount/6. Daily 10 Gold Coins reward already credited!",
      );
    }

    // Award 10 Gold Coins
    const int coinsToAward = 10;
    final txId = 'rwd_${DateTime.now().microsecondsSinceEpoch}';
    final txData = {
      'id': txId,
      'user_id': userId,
      'coins': coinsToAward,
      'reason': 'Daily Reward: 6+ Verified Tasks ($verifiedCount tasks completed)',
      'reward_date': dateStr,
      'task_count': verifiedCount,
      'created_at': DateTime.now().toIso8601String(),
    };

    final inserted = await LocalDbService.instance.insertRewardTransaction(txData);

    if (inserted) {
      // Update balance
      final currentBalance = await LocalDbService.instance.getCoinBalance(userId);
      final totalEarned = ((currentBalance?['total_earned'] as num?)?.toInt() ?? 0) + coinsToAward;
      final available = ((currentBalance?['available_balance'] as num?)?.toInt() ?? 0) + coinsToAward;
      final pending = (currentBalance?['pending_rewards'] as num?)?.toInt() ?? 0;
      final withdrawn = (currentBalance?['total_withdrawn'] as num?)?.toInt() ?? 0;

      await LocalDbService.instance.upsertCoinBalance({
        'user_id': userId,
        'total_earned': totalEarned,
        'available_balance': available,
        'pending_rewards': pending,
        'total_withdrawn': withdrawn,
        'last_calculated_at': DateTime.now().toIso8601String(),
      });

      // Log user activity
      await LocalDbService.instance.logUserActivity(
        userId,
        'daily_reward_awarded',
        'Awarded 10 Gold Coins for completing $verifiedCount verified tasks on $dateStr',
      );

      return RewardCalculationResult(
        todayVerifiedCount: verifiedCount,
        isRewardUnlocked: true,
        coinsAwardedJustNow: true,
        coinsAwarded: coinsToAward,
        message: "Congratulations! You completed $verifiedCount verified tasks today and earned 10 Gold Coins (₹10)!",
      );
    }

    return RewardCalculationResult(
      todayVerifiedCount: verifiedCount,
      isRewardUnlocked: true,
      coinsAwardedJustNow: false,
      coinsAwarded: 0,
      message: "Today's verified work: $verifiedCount/6.",
    );
  }

  /// Get daily verified progress for display
  Future<Map<String, dynamic>> getDailyProgress(String userId) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final allUserTasks = await LocalDbService.instance.getTasks(userId, status: 'Approved');

    final qualifyingToday = allUserTasks.where((t) {
      final isQualifying = t['is_qualifying'] == 1 || t['is_qualifying'] == true;
      if (!isQualifying) return false;

      final updatedAt = t['updated_at'] as String? ?? '';
      final createdAt = t['created_at'] as String? ?? '';
      final taskDate = updatedAt.isNotEmpty ? updatedAt.substring(0, 10) : createdAt.substring(0, 10);

      return taskDate == dateStr;
    }).toList();

    final existingTxs = await LocalDbService.query(
      'reward_transactions',
      where: 'user_id = ? AND reward_date = ?',
      whereArgs: [userId, dateStr],
    );

    return {
      'count': qualifyingToday.length,
      'isUnlocked': qualifyingToday.length >= 6,
      'claimed': existingTxs.isNotEmpty,
    };
  }
}
