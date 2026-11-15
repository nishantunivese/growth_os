import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/local_db_service.dart';
import '../../auth/domain/auth_provider.dart';
import '../../rewards/domain/reward_provider.dart';
import 'withdrawal_models.dart';

class WithdrawalState {
  final List<WithdrawalRequest> requests;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  WithdrawalState({
    required this.requests,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  WithdrawalState copyWith({
    List<WithdrawalRequest>? requests,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return WithdrawalState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }

  bool hasSubmittedThisMonth() {
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    return requests.any((r) => r.monthYear == currentMonth && r.status != WithdrawalStatus.rejected);
  }
}

final withdrawalProvider = StateNotifierProvider<WithdrawalNotifier, WithdrawalState>((ref) {
  final user = ref.watch(authProvider).user;
  return WithdrawalNotifier(ref, user?.id ?? '');
});

class WithdrawalNotifier extends StateNotifier<WithdrawalState> {
  final Ref ref;
  final String userId;

  WithdrawalNotifier(this.ref, this.userId) : super(WithdrawalState(requests: [], isLoading: true)) {
    if (userId.isNotEmpty) {
      loadWithdrawals();
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadWithdrawals() async {
    if (userId.isEmpty) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final reqMaps = await LocalDbService.instance.getWithdrawals(userId);
      final list = reqMaps.map((m) => WithdrawalRequest.fromMap(m)).toList();
      state = state.copyWith(requests: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> applyWithdrawal({
    required String fullName,
    required String upiId,
    required int amount,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    final currentUser = ref.read(authProvider).user;
    if (currentUser?.isSuspended == true) {
      state = state.copyWith(
        isLoading: false,
        error: 'Your account is suspended: "${currentUser?.suspensionReason}". You cannot submit withdrawals.',
      );
      return false;
    }

    // 1. Validate UPI ID
    final cleanUpi = upiId.trim();
    if (!cleanUpi.contains('@') || cleanUpi.length < 5) {
      state = state.copyWith(
        isLoading: false,
        error: 'Please enter a valid UPI ID (e.g. yourname@okhdfcbank or user@upi)',
      );
      return false;
    }

    // 2. Validate Amount (Min ₹500)
    if (amount < 500) {
      state = state.copyWith(
        isLoading: false,
        error: 'Minimum withdrawal is 500 Gold Coins (₹500).',
      );
      return false;
    }

    // 3. Check Available Balance
    final balanceMap = await LocalDbService.instance.getCoinBalance(userId);
    final available = (balanceMap?['available_balance'] as num?)?.toInt() ?? 0;
    if (amount > available) {
      state = state.copyWith(
        isLoading: false,
        error: 'Requested amount (₹$amount) exceeds available eligible balance (₹$available).',
      );
      return false;
    }

    // 4. Validate One Application per Calendar Month
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final alreadyThisMonth = state.hasSubmittedThisMonth();
    if (alreadyThisMonth) {
      state = state.copyWith(
        isLoading: false,
        error: 'Policy limit: Only 1 withdrawal application allowed per calendar month ($currentMonth).',
      );
      return false;
    }

    // 5. Reserve Coins in Database to Prevent Double Spending
    final now = DateTime.now();
    final reqId = 'wth_${now.microsecondsSinceEpoch}';

    final totalEarned = (balanceMap?['total_earned'] as num?)?.toInt() ?? 0;
    final pendingRewards = ((balanceMap?['pending_rewards'] as num?)?.toInt() ?? 0) + amount;
    final totalWithdrawn = (balanceMap?['total_withdrawn'] as num?)?.toInt() ?? 0;
    final newAvailable = available - amount;

    await LocalDbService.instance.upsertCoinBalance({
      'user_id': userId,
      'total_earned': totalEarned,
      'available_balance': newAvailable,
      'pending_rewards': pendingRewards,
      'total_withdrawn': totalWithdrawn,
      'last_calculated_at': now.toIso8601String(),
    });

    // 6. Record Withdrawal Request
    final request = WithdrawalRequest(
      id: reqId,
      userId: userId,
      fullName: fullName.trim(),
      upiId: cleanUpi,
      amount: amount,
      coinsReserved: amount,
      monthYear: currentMonth,
      status: WithdrawalStatus.pendingReview,
      notes: notes?.trim(),
      submittedAt: now,
    );

    await LocalDbService.instance.upsertWithdrawal(request.toMap());

    // 7. Log Activity
    await LocalDbService.instance.logUserActivity(
      userId,
      'withdrawal_submitted',
      'Applied for withdrawal of ₹$amount to UPI: $cleanUpi. $amount coins reserved.',
    );

    // Refresh rewards & withdrawals
    ref.read(rewardProvider.notifier).loadRewards();
    await loadWithdrawals();

    state = state.copyWith(
      isLoading: false,
      successMessage: 'Withdrawal request of ₹$amount submitted successfully and sent for review.',
    );
    return true;
  }
}
