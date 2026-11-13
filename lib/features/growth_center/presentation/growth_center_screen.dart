import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../domain/growth_models.dart';
import '../domain/growth_provider.dart';

class GrowthCenterScreen extends ConsumerStatefulWidget {
  const GrowthCenterScreen({super.key});

  @override
  ConsumerState<GrowthCenterScreen> createState() => _GrowthCenterScreenState();
}

class _GrowthCenterScreenState extends ConsumerState<GrowthCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(growthCenterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Creator Growth Center'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Content Calendar'),
            Tab(text: 'Audience Tracker'),
            Tab(text: 'Course Funnel'),
            Tab(text: 'Lead Manager'),
            Tab(text: 'Campaign ROI'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContentCalendarTab(state),
          _buildAudienceTrackerTab(state),
          _buildCourseFunnelTab(state),
          _buildLeadManagerTab(state),
          _buildCampaignRoiTab(state),
        ],
      ),
    );
  }

  // FEATURE 1: Content Calendar
  Widget _buildContentCalendarTab(GrowthCenterState state) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Planned Content Pipeline',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
              onPressed: _addContentDialog,
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...state.contentItems.map((item) {
          Color platformColor;
          switch (item.platform.toLowerCase()) {
            case 'youtube':
              platformColor = Colors.redAccent;
              break;
            case 'instagram':
              platformColor = Colors.pinkAccent;
              break;
            case 'telegram':
              platformColor = Colors.lightBlueAccent;
              break;
            default:
              platformColor = AppColors.primary;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: platformColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: platformColor.withOpacity(0.4)),
                          ),
                          child: Text(
                            '${item.platform} • ${item.contentType}',
                            style: TextStyle(color: platformColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    DropdownButton<ContentStatus>(
                      value: item.status,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                      underline: const SizedBox(),
                      items: ContentStatus.values.map((st) {
                        return DropdownMenuItem(value: st, child: Text(st.name.toUpperCase()));
                      }).toList(),
                      onChanged: (newSt) {
                        if (newSt != null) {
                          ref.read(growthCenterProvider.notifier).updateContentStatus(item.id, newSt);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                if (item.scriptNotes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.scriptNotes,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Planned: ${item.plannedDate.day}/${item.plannedDate.month}/${item.plannedDate.year}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // FEATURE 2: Audience Tracker
  Widget _buildAudienceTrackerTab(GrowthCenterState state) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        const Text(
          'Channel Follower & View Tracker',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Track actual organic audience growth across all social platforms.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 14),
        ...state.audienceMetrics.map((aud) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      aud.platform,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () => _openUpdateMetricDialog(aud),
                      icon: const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                      label: const Text('Update', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${aud.count}',
                      style: const TextStyle(color: AppColors.primary, fontSize: 26, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 8),
                    const Text('Followers / Subscribers', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildAudienceStat('Total Views', '${aud.totalViews}'),
                    if (aud.watchHours > 0) ...[
                      const SizedBox(width: 14),
                      _buildAudienceStat('Watch Hours', '${aud.watchHours} hrs'),
                    ],
                  ],
                ),
                if (aud.growthNotes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Recent catalyst: ${aud.growthNotes}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAudienceStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // FEATURE 3: Course Sales Funnel
  Widget _buildCourseFunnelTab(GrowthCenterState state) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        const Text(
          'Digital Course & Mentorship Funnels',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Monitor conversion leakage across each stage: Audience → Lead → Checkout → Paid.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 14),
        ...state.funnels.map((funnel) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        funnel.productName,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '₹${funnel.totalRevenue.toStringAsFixed(0)}',
                      style: const TextStyle(color: AppColors.success, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                Text(
                  'Price: ₹${funnel.productPrice.toStringAsFixed(0)} • Conversion: ${funnel.conversionRate.toStringAsFixed(1)}%',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),

                // Visual Funnel Stages
                _buildFunnelStageTile('1. Landing Page Visitors', funnel.visitors, 1.0, AppColors.primary),
                _buildFunnelStageTile('2. Leads Captured', funnel.leads, funnel.visitors > 0 ? funnel.leads / funnel.visitors : 0.0, AppColors.secondary),
                _buildFunnelStageTile('3. Checkout Page Visits', funnel.checkoutVisits, funnel.visitors > 0 ? funnel.checkoutVisits / funnel.visitors : 0.0, AppColors.warning),
                _buildFunnelStageTile('4. Paid Customers', funnel.sales, funnel.visitors > 0 ? funnel.sales / funnel.visitors : 0.0, AppColors.success),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFunnelStageTile(String label, int count, double widthPct, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: widthPct.clamp(0.05, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // FEATURE 4: Lead Manager
  Widget _buildLeadManagerTab(GrowthCenterState state) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Social & DM Leads',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.person_add_alt, color: AppColors.primary),
              onPressed: _addLeadDialog,
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...state.leads.map((lead) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                    Text(
                      lead.name,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        lead.stage.name.toUpperCase(),
                        style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${lead.platformSource}  •  ${lead.contactInfo}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                if (lead.interestedProduct.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Product: ${lead.interestedProduct}',
                    style: const TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
                if (lead.notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    lead.notes,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  // FEATURE 5: Campaign Analytics
  Widget _buildCampaignRoiTab(GrowthCenterState state) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        const Text(
          'Campaign Performance & ROI Leaderboard',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Rank campaigns strictly by real earnings, views, and conversion ratios.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 14),
        ...state.campaigns.map((camp) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      camp.campaignName,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₹${camp.totalEarnings.toStringAsFixed(0)}',
                      style: const TextStyle(color: AppColors.success, fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                Text(
                  'Platform: ${camp.platform} • Videos: ${camp.videosPublished}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCampMetric('Views', '${camp.totalViews}'),
                    _buildCampMetric('Leads', '${camp.leads}'),
                    _buildCampMetric('Sales', '${camp.sales}'),
                    _buildCampMetric('ROI', '+${camp.roi.toStringAsFixed(0)}%', isHighlight: true),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCampMetric(String label, String value, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? AppColors.success : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  void _addContentDialog() {
    final titleCtrl = TextEditingController();
    final scriptCtrl = TextEditingController();
    String platform = 'YouTube';
    String type = 'Short';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Add Content Item', style: TextStyle(color: Colors.white, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Content Title / Hook *'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: platform,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Platform'),
                items: ['YouTube', 'Instagram', 'Telegram'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (val) {
                  if (val != null) setDlgState(() => platform = val);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: scriptCtrl,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Hook & Script Notes'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                final newItem = ContentItem(
                  id: 'cnt-${DateTime.now().millisecondsSinceEpoch}',
                  userId: 'demo-user-id',
                  title: titleCtrl.text.trim(),
                  platform: platform,
                  contentType: type,
                  plannedDate: DateTime.now().add(const Duration(days: 2)),
                  scriptNotes: scriptCtrl.text.trim(),
                );
                ref.read(growthCenterProvider.notifier).addContentItem(newItem);
                Navigator.pop(ctx);
              },
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  void _openUpdateMetricDialog(AudienceMetric aud) {
    final countCtrl = TextEditingController(text: '${aud.count}');
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Update ${aud.platform} Count', style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: countCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(labelText: 'Total Count *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notesCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(labelText: 'What caused growth?'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final count = int.tryParse(countCtrl.text.trim());
              if (count != null) {
                ref.read(growthCenterProvider.notifier).updateAudienceMetric(aud.platform, count, notesCtrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addLeadDialog() {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final prodCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add Lead / DM Inquiry', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(labelText: 'Lead Name *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contactCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(labelText: 'Handle / Phone / Email *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: prodCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(labelText: 'Interested Product / Course'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              final newLead = CreatorLead(
                id: 'lead-${DateTime.now().millisecondsSinceEpoch}',
                userId: 'demo-user-id',
                name: nameCtrl.text.trim(),
                platformSource: 'Instagram DM',
                contactInfo: contactCtrl.text.trim(),
                interestedProduct: prodCtrl.text.trim(),
              );
              ref.read(growthCenterProvider.notifier).addCreatorLead(newLead);
              Navigator.pop(ctx);
            },
            child: const Text('Add Lead'),
          ),
        ],
      ),
    );
  }
}

