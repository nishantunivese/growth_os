import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../domain/crm_models.dart';
import '../domain/crm_provider.dart';
import 'add_client_dialog.dart';
import 'client_detail_screen.dart';

class CrmScreen extends ConsumerStatefulWidget {
  const CrmScreen({super.key});

  @override
  ConsumerState<CrmScreen> createState() => _CrmScreenState();
}

class _CrmScreenState extends ConsumerState<CrmScreen> {
  LeadStatus? _selectedStageFilter;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final crmAsync = ref.watch(crmProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Client & Deal CRM'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary),
            onPressed: () => _openAddClientDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddClientDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Client / Deal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: crmAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (clients) {
          final filtered = clients.where((c) {
            final matchesStage = _selectedStageFilter == null || c.status == _selectedStageFilter;
            final matchesQuery = c.clientBrandName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                c.contactPerson.toLowerCase().contains(_searchQuery.toLowerCase());
            return matchesStage && matchesQuery;
          }).toList();

          final totalPipelineValue = clients.fold(0.0, (sum, c) => sum + c.dealAmount);
          final activeDeals = clients.where((c) => c.status != LeadStatus.closed).length;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Pipeline Value Header Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL PIPELINE VALUE',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '₹${totalPipelineValue.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$activeDeals Active Deals',
                                style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${clients.length} Total Contacts',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Search & Stage Filter Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: TextField(
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: const InputDecoration(
                            hintText: 'Search client, brand, or contact name...',
                            hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 18),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 34,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _selectedStageFilter = null),
                              child: _buildFilterChip('All Stages', _selectedStageFilter == null),
                            ),
                            ...LeadStatus.values.map((stage) {
                              final isSel = _selectedStageFilter == stage;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedStageFilter = stage),
                                child: _buildFilterChip(stage.displayName, isSel),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Clients List
              if (filtered.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text('No clients match the selected stage.', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final client = filtered[index];
                        return _buildClientCard(context, client);
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? AppColors.primary : AppColors.cardBorder),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildClientCard(BuildContext context, Client c) {
    Color stageColor;
    switch (c.status) {
      case LeadStatus.newLead:
        stageColor = Colors.grey;
        break;
      case LeadStatus.contacted:
      case LeadStatus.negotiation:
        stageColor = AppColors.warning;
        break;
      case LeadStatus.dealConfirmed:
      case LeadStatus.workInProgress:
        stageColor = AppColors.primary;
        break;
      case LeadStatus.completed:
        stageColor = AppColors.success;
        break;
      case LeadStatus.paymentPending:
        stageColor = Colors.orange;
        break;
      case LeadStatus.closed:
        stageColor = AppColors.textSecondary;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClientDetailScreen(clientId: c.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Brand name & Deal Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      c.clientBrandName,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '₹${c.dealAmount.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppColors.success, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Contact Person & Company
              Text(
                '${c.contactPerson}  •  ${c.companyName}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 10),

              // Project scope preview
              if (c.projectDetails.isNotEmpty)
                Text(
                  c.projectDetails,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                ),
              const SizedBox(height: 12),

              // Bottom Action Bar: Status Pill & Fast Action Shortcuts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: stageColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: stageColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      c.status.displayName.toUpperCase(),
                      style: TextStyle(color: stageColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),

                  // Quick Action Shortcuts (WhatsApp, Call, Email)
                  Row(
                    children: [
                      if (c.whatsapp.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF25D366)),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Open WhatsApp',
                          onPressed: () => _launchUrl('https://wa.me/${c.whatsapp.replaceAll(RegExp(r'[^0-9]'), '')}'),
                        ),
                      if (c.phone.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.phone_outlined, size: 18, color: AppColors.primary),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Call Client',
                          onPressed: () => _launchUrl('tel:${c.phone}'),
                        ),
                      if (c.email.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.mail_outline_rounded, size: 18, color: AppColors.secondary),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Send Email',
                          onPressed: () => _launchUrl('mailto:${c.email}'),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _openAddClientDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddClientDialog(),
    );
  }
}

