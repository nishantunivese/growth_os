import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/local_db_service.dart';
import '../../auth/domain/auth_provider.dart';
import 'reward_models.dart';
import 'reward_service.dart';

class RewardState {
  final GoldCoinBalance balance;
  final List<RewardTransaction> transactions;
  final int todayVerifiedCount;
  final bool isDailyUnlocked;
  final bool isDailyClaimed;
  final bool isLoading;
  final String? message;

  RewardState({
    required this.balance,
    required this.transactions,
    this.todayVerifiedCount = 0,
    this.isDailyUnlocked = false,
    this.isDailyClaimed = false,
    this.isLoading = false,
    this.message,
  });

  RewardState copyWith({
    GoldCoinBalance? balance,
    List<RewardTransaction>? transactions,
    int? todayVerifiedCount,
    bool? isDailyUnlocked,
    bool? isDailyClaimed,
    bool? isLoading,
    String? message,
  }) {
    return RewardState(
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      todayVerifiedCount: todayVerifiedCount ?? this.todayVerifiedCount,
      isDailyUnlocked: isDailyUnlocked ?? this.isDailyUnlocked,
      isDailyClaimed: isDailyClaimed ?? this.isDailyClaimed,
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
    );
  }
}

final rewardProvider = StateNotifierProvider<RewardNotifier, RewardState>((ref) {
  final user = ref.watch(authProvider).user;
  return RewardNotifier(ref, user?.id ?? '');
});

class RewardNotifier extends StateNotifier<RewardState> {
  final Ref ref;
  final String userId;

  RewardNotifier(this.ref, this.userId)
      : super(RewardState(
          balance: GoldCoinBalance(userId: userId, lastCalculatedAt: DateTime.now()),
          transactions: [],
          isLoading: true,
        )) {
    if (userId.isNotEmpty) {
      loadRewards();
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadRewards() async {
    if (userId.isEmpty) return;
    state = state.copyWith(isLoading: true);

    try {
      final balanceMap = await LocalDbService.instance.getCoinBalance(userId);
      final balance = balanceMap != null
          ? GoldCoinBalance.fromMap(balanceMap)
          : GoldCoinBalance(userId: userId, lastCalculatedAt: DateTime.now());

      final txMaps = await LocalDbService.instance.getRewardTransactions(userId);
      final txs = txMaps.map((m) => RewardTransaction.fromMap(m)).toList();

      final progress = await RewardService.instance.getDailyProgress(userId);

      state = state.copyWith(
        balance: balance,
        transactions: txs,
        todayVerifiedCount: progress['count'] as int? ?? 0,
        isDailyUnlocked: progress['isUnlocked'] as bool? ?? false,
        isDailyClaimed: progress['claimed'] as bool? ?? false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<RewardCalculationResult?> checkAndClaimDailyReward() async {
    if (userId.isEmpty) return null;
    final res = await RewardService.instance.evaluateDailyReward(userId);
    await loadRewards();
    return res;
  }
}
