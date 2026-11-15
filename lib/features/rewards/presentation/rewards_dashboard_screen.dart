import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../withdrawal/presentation/withdrawal_screen.dart';
import '../domain/reward_provider.dart';

class RewardsDashboardScreen extends ConsumerWidget {
  const RewardsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardState = ref.watch(rewardProvider);
    final balance = rewardState.balance;
    final verifiedCount = rewardState.todayVerifiedCount;
    final isUnlocked = rewardState.isDailyUnlocked;
    final isClaimed = rewardState.isDailyClaimed;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gold Coins & Rewards'),
        backgroundColor: AppColors.cardSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh & Check Reward',
            onPressed: () async {
              final res = await ref.read(rewardProvider.notifier).checkAndClaimDailyReward();
              if (res != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: res.coinsAwardedJustNow ? AppColors.emeraldGreen : AppColors.cardSurface,
                    content: Text(res.message),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: rewardState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.goldCoin))
          : RefreshIndicator(
              onRefresh: () => ref.read(rewardProvider.notifier).loadRewards(),
              color: AppColors.goldCoin,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Balance Banner
                    _buildBalanceCard(context, balance),

                    const SizedBox(height: 20),

                    // Daily Task Completion Progress Card
                    _buildDailyProgressCard(verifiedCount, isUnlocked, isClaimed),

                    const SizedBox(height: 20),

                    // Reward Rule Clarification Box
                    _buildRewardRulesInfo(),

                    const SizedBox(height: 24),

                    // Reward History Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Reward History',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          '${rewardState.transactions.length} payouts',
                          style: TextStyle(fontSize: 12, color: AppColors.textDim),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (rewardState.transactions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.stars_rounded, size: 40, color: AppColors.goldCoin.withOpacity(0.5)),
                            const SizedBox(height: 8),
                            const Text(
                              'No rewards credited yet',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Complete 6 or more qualifying tasks in a single day to earn 10 Gold Coins (₹10).',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: rewardState.transactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final tx = rewardState.transactions[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.goldCoin.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.goldCoin.withOpacity(0.4)),
                                  ),
                                  child: const Icon(Icons.monetization_on_rounded, color: AppColors.goldCoin, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.reason,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Date: ${tx.rewardDate} • ${DateFormat('hh:mm a').format(tx.createdAt)}',
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '+${tx.coins} Coins',
                                      style: const TextStyle(
                                        color: AppColors.goldCoin,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      '₹${tx.coins}',
                                      style: TextStyle(color: AppColors.textDim, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, dynamic balance) {
    final available = balance.availableBalance;
    final totalEarned = balance.totalEarned;
    final pending = balance.pendingRewards;
    final withdrawn = balance.totalWithdrawn;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF172554), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.electricPurpleLight.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.goldCoin.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.monetization_on_rounded, color: AppColors.goldCoin, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'GOLD COIN BALANCE',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.goldCoin, letterSpacing: 1.2),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '1 Coin = ₹1',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$available',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Coins (₹$available)',
                style: TextStyle(fontSize: 18, color: AppColors.goldCoinLight, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 16),

          // 3 Metrics Sub-Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat('Total Earned', '₹$totalEarned', AppColors.emeraldGreen),
              _buildMiniStat('Pending Review', '₹$pending', AppColors.amberWarning),
              _buildMiniStat('Withdrawn', '₹$withdrawn', AppColors.cyberCyan),
            ],
          ),

          const SizedBox(height: 20),

          // Apply for Withdrawal Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WithdrawalScreen()),
                );
              },
              icon: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 18),
              label: const Text(
                'Apply for Withdrawal',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textDim, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildDailyProgressCard(int count, bool isUnlocked, bool isClaimed) {
    final progress = (count / 6).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUnlocked ? AppColors.goldCoin.withOpacity(0.5) : AppColors.cardBorder,
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
                    isUnlocked ? Icons.check_circle_rounded : Icons.military_tech_rounded,
                    color: isUnlocked ? AppColors.emeraldGreen : AppColors.goldCoin,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "DAILY REWARD PROGRESS",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.8),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isUnlocked ? AppColors.emeraldGreen.withOpacity(0.2) : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isClaimed ? 'CLAIMED' : (isUnlocked ? 'READY' : 'IN PROGRESS'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isUnlocked ? AppColors.emeraldGreenLight : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Indicator copy as specified in requirements
          Text(
            "Today's verified work: $count/6",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            isUnlocked
                ? 'Reward unlocked! 10 Gold Coins (₹10) earned for today.'
                : 'Reward unlocked after 6 qualifying tasks.',
            style: TextStyle(
              fontSize: 12,
              color: isUnlocked ? AppColors.goldCoin : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
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

  Widget _buildRewardRulesInfo() {
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
          const Row(
            children: [
              Icon(Icons.rule_rounded, color: AppColors.cyberCyan, size: 18),
              SizedBox(width: 8),
              Text(
                'Reward Conditions',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildBullet('1 Gold Coin = ₹1. Complete 6+ tasks in 1 day for 10 Coins.'),
          _buildBullet('Only admin-approved tasks count toward daily rewards.'),
          _buildBullet('Exactly 5 tasks do not qualify; 6 or more qualifying tasks are required.'),
          _buildBullet('Reward is awarded once per calendar day automatically.'),
          _buildBullet('Withdrawal opens once you reach 500 Gold Coins (₹500).'),
        ],
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.cyberCyan, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
