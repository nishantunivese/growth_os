import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/domain/auth_provider.dart';
import '../domain/crm_models.dart';
import '../domain/crm_provider.dart';

class AddClientDialog extends ConsumerStatefulWidget {
  const AddClientDialog({super.key});

  @override
  ConsumerState<AddClientDialog> createState() => _AddClientDialogState();
}

class _AddClientDialogState extends ConsumerState<AddClientDialog> {
  final _brandCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _scopeCtrl = TextEditingController();

  LeadStatus _status = LeadStatus.newLead;

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
            const Text(
              'Add Client / Deal Contact',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage sponsors, high-ticket clients, and affiliate partners.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Client / Brand name
            TextField(
              controller: _brandCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(labelText: 'Client or Brand Name *', hintText: 'e.g. Apex Tech'),
            ),
            const SizedBox(height: 12),

            // Contact person
            TextField(
              controller: _contactCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(labelText: 'Contact Person Name', hintText: 'e.g. David Chen'),
            ),
            const SizedBox(height: 12),

            // Deal amount
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(labelText: 'Deal Amount (₹) *', hintText: '50000'),
            ),
            const SizedBox(height: 12),

            // WhatsApp & Phone
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _whatsappCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(labelText: 'WhatsApp Number', hintText: '+919876...'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(labelText: 'Email Address', hintText: 'client@work.com'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Scope / Project details
            TextField(
              controller: _scopeCtrl,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Project Scope / Deliverables',
                hintText: 'e.g. 2 YouTube Shorts integration + link in bio',
              ),
            ),
            const SizedBox(height: 12),

            // Initial Stage Dropdown
            DropdownButtonFormField<LeadStatus>(
              value: _status,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(labelText: 'Initial Lead Status'),
              items: LeadStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.displayName))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _status = val);
              },
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveClient,
                child: const Text('Save Client to CRM', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveClient() {
    if (_brandCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a client or brand name')));
      return;
    }

    final userId = ref.read(authProvider).user?.id ?? 'demo-user-id';
    final now = DateTime.now();

    final client = Client(
      id: 'client-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      clientBrandName: _brandCtrl.text.trim(),
      contactPerson: _contactCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : _whatsappCtrl.text.trim(),
      whatsapp: _whatsappCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      companyName: _brandCtrl.text.trim(),
      projectDetails: _scopeCtrl.text.trim(),
      dealAmount: double.tryParse(_amountCtrl.text.trim()) ?? 0.0,
      status: _status,
      createdAt: now,
    );

    ref.read(crmProvider.notifier).addClient(client);
    Navigator.pop(context);
  }
}

