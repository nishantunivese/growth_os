import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/database/local_db_service.dart';
import '../domain/crm_models.dart';
import '../domain/crm_provider.dart';

class ClientDetailScreen extends ConsumerStatefulWidget {
  final String clientId;
  const ClientDetailScreen({super.key, required this.clientId});

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> {
  List<ClientInteraction> _interactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInteractions();
  }

  Future<void> _loadInteractions() async {
    setState(() => _isLoading = true);
    final maps = await LocalDbService.instance.getInteractions(widget.clientId);
    List<ClientInteraction> list = maps.map((m) => ClientInteraction.fromMap(m)).toList();

    if (list.isEmpty) {
      final now = DateTime.now();
      list = [
        ClientInteraction(
          id: 'int-001',
          clientId: widget.clientId,
          interactionType: 'Call',
          notes: 'Discussed sponsorship scope. Agreed on 1 integrated video + 1 dedicated story.',
          date: now.subtract(const Duration(days: 2)),
        ),
        ClientInteraction(
          id: 'int-002',
          clientId: widget.clientId,
          interactionType: 'WhatsApp',
          notes: 'Client confirmed budget of agreed amount and requested invoice copy.',
          date: now.subtract(const Duration(hours: 18)),
        ),
      ];
      for (var item in list) {
        await LocalDbService.instance.upsertInteraction(item.toMap());
      }
    }

    setState(() {
      _interactions = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(crmProvider).value ?? [];
    final client = clients.firstWhere(
      (c) => c.id == widget.clientId,
      orElse: () => Client(
        id: widget.clientId,
        userId: '',
        clientBrandName: 'Client Detail',
        createdAt: DateTime.now(),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(client.clientBrandName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: () => _confirmDelete(context, client),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addInteractionDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
        label: const Text('Log Interaction', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          // Deal Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.clientBrandName,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${client.contactPerson}  •  ${client.companyName}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                    Text(
                      '₹${client.dealAmount.toStringAsFixed(0)}',
                      style: const TextStyle(color: AppColors.success, fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.cardBorder, height: 1),
                const SizedBox(height: 14),

                // Quick Communication Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionShortcut(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'WhatsApp',
                      color: const Color(0xFF25D366),
                      onTap: () => _launch('https://wa.me/${client.whatsapp.replaceAll(RegExp(r'[^0-9]'), '')}'),
                    ),
                    _buildActionShortcut(
                      icon: Icons.phone_outlined,
                      label: 'Call',
                      color: AppColors.primary,
                      onTap: () => _launch('tel:${client.phone}'),
                    ),
                    _buildActionShortcut(
                      icon: Icons.mail_outline_rounded,
                      label: 'Email',
                      color: AppColors.secondary,
                      onTap: () => _launch('mailto:${client.email}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Status & Stage Pipeline Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pipeline Deal Stage', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                DropdownButtonFormField<LeadStatus>(
                  value: client.status,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                  items: LeadStatus.values.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s.displayName));
                  }).toList(),
                  onChanged: (newStatus) {
                    if (newStatus != null) {
                      ref.read(crmProvider.notifier).updateClientStatus(client.id, newStatus);
                    }
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Payment Status: ${client.paymentStatus}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                    if (client.workDeadline != null)
                      Text(
                        'Deadline: ${client.workDeadline!.day}/${client.workDeadline!.month}',
                        style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Interaction History
          const Text(
            'Interaction & Follow-Up History',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          if (_interactions.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Center(
                child: Text('No interaction logs yet. Click "+ Log Interaction" below.', style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            ..._interactions.map((intx) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            intx.interactionType.toUpperCase(),
                            style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          '${intx.date.day}/${intx.date.month}  ${intx.date.hour}:${intx.date.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      intx.notes,
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildActionShortcut({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _addInteractionDialog() {
    final noteCtrl = TextEditingController();
    String type = 'Call';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Log Interaction', style: TextStyle(color: Colors.white, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(labelText: 'Channel / Type'),
                items: ['Call', 'WhatsApp', 'Email', 'Meeting', 'Proposal Sent'].map((t) {
                  return DropdownMenuItem(value: t, child: Text(t));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => type = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Discussion Notes & Next Steps',
                  hintText: 'What did the client say? Next follow-up date?',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (noteCtrl.text.trim().isEmpty) return;
                final newIntx = ClientInteraction(
                  id: 'int-${DateTime.now().millisecondsSinceEpoch}',
                  clientId: widget.clientId,
                  interactionType: type,
                  notes: noteCtrl.text.trim(),
                  date: DateTime.now(),
                );
                await LocalDbService.instance.upsertInteraction(newIntx.toMap());
                Navigator.pop(ctx);
                _loadInteractions();
              },
              child: const Text('Save Note'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Client c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Client?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text('Permanently delete ${c.clientBrandName}?', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(crmProvider.notifier).deleteClient(c.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _launch(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

