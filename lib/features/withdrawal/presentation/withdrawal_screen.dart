import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/domain/auth_provider.dart';
import '../../rewards/domain/reward_provider.dart';
import '../domain/withdrawal_models.dart';
import '../domain/withdrawal_provider.dart';

class WithdrawalScreen extends ConsumerStatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  ConsumerState<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends ConsumerState<WithdrawalScreen> {
  final _nameController = TextEditingController();
  final _upiController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authProvider).user;
    if (profile != null) {
      _nameController.text = profile.fullName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _upiController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleWithdrawalSubmit(int availableBalance, bool alreadySubmittedThisMonth) async {
    final name = _nameController.text.trim();
    final upi = _upiController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = int.tryParse(amountText) ?? 0;

    if (name.isEmpty) {
      _showError('Please enter your full name as registered on bank / UPI.');
      return;
    }

    if (upi.isEmpty || !upi.contains('@')) {
      _showError('Please enter a valid UPI ID (e.g. mobile@upi, name@okaxis, etc.)');
      return;
    }

    if (amount < 500) {
      _showError('Minimum withdrawal amount is 500 Gold Coins (₹500).');
      return;
    }

    if (amount > availableBalance) {
      _showError('Amount exceeds available eligible balance of ₹$availableBalance.');
      return;
    }

    if (alreadySubmittedThisMonth) {
      final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
      _showError('Policy limit: You can submit only 1 withdrawal application per calendar month ($currentMonth).');
      return;
    }

    final success = await ref.read(withdrawalProvider.notifier).applyWithdrawal(
      fullName: name,
      upiId: upi,
      amount: amount,
      notes: _notesController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.emeraldGreen,
          content: Text('Withdrawal application submitted! Coins reserved for review.'),
        ),
      );
      _amountController.clear();
      _notesController.clear();
    } else if (mounted) {
      final err = ref.read(withdrawalProvider).error ?? 'Submission failed';
      _showError(err);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppColors.roseDanger, content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rewardState = ref.watch(rewardProvider);
    final withdrawalState = ref.watch(withdrawalProvider);
    final availableBalance = rewardState.balance.availableBalance;
    final isEligible = availableBalance >= 500;
    final alreadySubmittedThisMonth = withdrawalState.hasSubmittedThisMonth();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Withdrawal Request'),
        backgroundColor: AppColors.cardSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Eligibility & Balance Card
            _buildEligibilityCard(availableBalance, isEligible, alreadySubmittedThisMonth),

            const SizedBox(height: 20),

            // Mandatory Policy Notice Card
            _buildPolicyNoticeCard(),

            const SizedBox(height: 24),

            // Withdrawal Application Form
            const Text(
              'Application Form',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full Name
                  const Text('Full Name (as on Bank/UPI) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. Rahul Sharma',
                      hintStyle: TextStyle(color: AppColors.textDim, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // UPI ID
                  const Text('UPI ID *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _upiController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. 9876543210@paytm or name@okaxis',
                      hintStyle: TextStyle(color: AppColors.textDim, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Withdrawal Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Withdrawal Amount (₹) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                      Text('Min: ₹500 • Max: ₹$availableBalance', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Enter amount (min 500)',
                      hintStyle: TextStyle(color: AppColors.textDim, fontSize: 13),
                      suffixIcon: TextButton(
                        onPressed: isEligible ? () => setState(() => _amountController.text = availableBalance.toString()) : null,
                        child: const Text('MAX', style: TextStyle(color: AppColors.electricPurpleLight, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Optional Notes
                  const Text('Additional Notes (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Optional bank name, remarks, or contact note...',
                      hintStyle: TextStyle(color: AppColors.textDim, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (!isEligible || alreadySubmittedThisMonth || withdrawalState.isLoading)
                          ? null
                          : () => _handleWithdrawalSubmit(availableBalance, alreadySubmittedThisMonth),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.electricPurple,
                        disabledBackgroundColor: AppColors.cardBorder,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        withdrawalState.isLoading
                            ? 'Submitting...'
                            : (!isEligible
                                ? 'Need Min 500 Coins to Withdraw'
                                : (alreadySubmittedThisMonth ? 'Monthly Limit Reached' : 'Submit Withdrawal Application')),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Withdrawal History Section
            const Text(
              'Withdrawal History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),

            if (withdrawalState.requests.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  'No withdrawal requests submitted yet.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: withdrawalState.requests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final req = withdrawalState.requests[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${req.amount} (${req.amount} Coins)',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: req.status.color.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: req.status.color.withOpacity(0.4)),
                              ),
                              child: Text(
                                req.status.displayName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: req.status.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'UPI: ${req.upiId} • Month: ${req.monthYear}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        Text(
                          'Submitted: ${DateFormat('dd MMM yyyy, hh:mm a').format(req.submittedAt)}',
                          style: TextStyle(color: AppColors.textDim, fontSize: 11),
                        ),

                        // If Rejected, display rejection reason
                        if (req.status == WithdrawalStatus.rejected && req.rejectionReason != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.roseDanger.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.roseDanger.withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.cancel_outlined, color: AppColors.roseDanger, size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Rejection Reason (Coins Refunded to Balance):',
                                        style: TextStyle(color: AppColors.roseDanger, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        req.rejectionReason!,
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // If Paid, display UTR/payment reference
                        if (req.status == WithdrawalStatus.paid && req.paymentRef != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.emeraldGreen.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, color: AppColors.emeraldGreen, size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Paid Reference / UTR: ${req.paymentRef}',
                                    style: const TextStyle(color: AppColors.emeraldGreenLight, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEligibilityCard(int balance, bool isEligible, bool alreadySubmittedThisMonth) {
    String statusText;
    Color statusColor;

    if (!isEligible) {
      statusText = 'Not Eligible (Requires at least 500 Coins)';
      statusColor = AppColors.roseDanger;
    } else if (alreadySubmittedThisMonth) {
      statusText = 'Eligible (Monthly Limit Reached for this Month)';
      statusColor = AppColors.amberWarning;
    } else {
      statusText = 'Eligible for Monthly Withdrawal';
      statusColor = AppColors.emeraldGreen;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ELIGIBLE REWARD BALANCE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹$balance',
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                '($balance Gold Coins)',
                style: TextStyle(fontSize: 14, color: AppColors.goldCoin, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Rule: 1 withdrawal application allowed per calendar month. Minimum ₹500.',
            style: TextStyle(color: AppColors.textDim, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.electricPurpleLight.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.electricPurpleLight, size: 20),
              SizedBox(width: 8),
              Text(
                'IMPORTANT POLICY NOTICE',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Growth OS rewards are subject to verification and quality assessment. Completing ordinary, repetitive, fake or low-value tasks does not guarantee withdrawal approval. Submitted work must demonstrate genuine effort, meaningful value and verifiable results. Growth OS reserves the right to reject suspicious, duplicate, misleading or low-quality submissions after review.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.45),
          ),
        ],
      ),
    );
  }
}
