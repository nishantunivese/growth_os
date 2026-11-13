import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/domain/auth_provider.dart';
import '../domain/finance_models.dart';
import '../domain/finance_provider.dart';

class AddTransactionModal extends ConsumerStatefulWidget {
  const AddTransactionModal({super.key});

  @override
  ConsumerState<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends ConsumerState<AddTransactionModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Income fields
  final _incomeAmountCtrl = TextEditingController();
  final _incomeDescCtrl = TextEditingController();
  String _incomeSource = 'Tenbox';
  String _paymentStatus = 'Received';

  // Expense fields
  final _expenseAmountCtrl = TextEditingController();
  final _expenseDescCtrl = TextEditingController();
  String _expenseCategory = 'Software';
  bool _isRefund = false;

  final List<String> _incomeSources = [
    'Tenbox',
    'Whop',
    'Course sales',
    'Paid group',
    'YouTube',
    'Affiliate commissions',
    'Brand collaborations',
    'Client projects',
    'Other income',
  ];

  final List<String> _expenseCategories = [
    'Software',
    'Ads & Marketing',
    'Freelancers & Editors',
    'Equipment & Tech',
    'Refund',
    'Operational & Fees',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: const [
                  Tab(text: '+ Record Income'),
                  Tab(text: '- Record Expense / Refund'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 380,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildIncomeForm(),
                  _buildExpenseForm(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _incomeAmountCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            labelText: 'Received Amount (₹) *',
            hintText: '5000',
            prefixIcon: Icon(Icons.currency_rupee, color: AppColors.success),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _incomeSource,
          dropdownColor: AppColors.surface,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: const InputDecoration(labelText: 'Platform / Source'),
          items: _incomeSources.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _incomeSource = val);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _incomeDescCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: const InputDecoration(
            labelText: 'Description / Campaign name',
            hintText: 'e.g. Tenbox payout for 5 viral short clips',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Payment Status', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            DropdownButton<String>(
              value: _paymentStatus,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'Received', child: Text('Received')),
                DropdownMenuItem(value: 'Pending', child: Text('Pending Payout')),
                DropdownMenuItem(value: 'Processing', child: Text('Processing')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _paymentStatus = val);
              },
            ),
          ],
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _saveIncome,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Save Income Entry', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _expenseAmountCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            labelText: 'Cost / Expense Amount (₹) *',
            hintText: '1500',
            prefixIcon: Icon(Icons.currency_rupee, color: AppColors.danger),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _expenseCategory,
          dropdownColor: AppColors.surface,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: const InputDecoration(labelText: 'Expense Category'),
          items: _expenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _expenseCategory = val;
                if (val == 'Refund') _isRefund = true;
              });
            }
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _expenseDescCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: const InputDecoration(
            labelText: 'Description / Purpose',
            hintText: 'e.g. Canva Pro & ElevenLabs voices',
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Mark as Refund', style: TextStyle(color: Colors.white, fontSize: 13)),
          subtitle: const Text('Separates customer refunds from operational expenses', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          value: _isRefund,
          activeColor: AppColors.danger,
          onChanged: (val) => setState(() => _isRefund = val),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _saveExpense,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Save Expense / Refund', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  void _saveIncome() {
    final amount = double.tryParse(_incomeAmountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid income amount')));
      return;
    }

    final userId = ref.read(authProvider).user?.id ?? 'demo-user-id';
    final entry = IncomeEntry(
      id: 'inc-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      amount: amount,
      date: DateTime.now(),
      platformSource: _incomeSource,
      description: _incomeDescCtrl.text.trim().isNotEmpty ? _incomeDescCtrl.text.trim() : 'Income via $_incomeSource',
      paymentStatus: _paymentStatus,
    );

    ref.read(financeProvider.notifier).addIncome(entry);
    Navigator.pop(context);
  }

  void _saveExpense() {
    final amount = double.tryParse(_expenseAmountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid expense amount')));
      return;
    }

    final userId = ref.read(authProvider).user?.id ?? 'demo-user-id';
    final entry = ExpenseEntry(
      id: 'exp-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      amount: amount,
      date: DateTime.now(),
      category: _expenseCategory,
      description: _expenseDescCtrl.text.trim().isNotEmpty ? _expenseDescCtrl.text.trim() : 'Expense for $_expenseCategory',
      isRefund: _isRefund,
    );

    ref.read(financeProvider.notifier).addExpense(entry);
    Navigator.pop(context);
  }
}

