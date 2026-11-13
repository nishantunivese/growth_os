import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/auth_provider.dart';
import 'growth_models.dart';

class GrowthCenterState {
  final List<ContentItem> contentItems;
  final List<AudienceMetric> audienceMetrics;
  final List<ProductFunnel> funnels;
  final List<CreatorLead> leads;
  final List<CampaignAnalytics> campaigns;
  final bool isLoading;

  GrowthCenterState({
    required this.contentItems,
    required this.audienceMetrics,
    required this.funnels,
    required this.leads,
    required this.campaigns,
    this.isLoading = false,
  });

  GrowthCenterState copyWith({
    List<ContentItem>? contentItems,
    List<AudienceMetric>? audienceMetrics,
    List<ProductFunnel>? funnels,
    List<CreatorLead>? leads,
    List<CampaignAnalytics>? campaigns,
    bool? isLoading,
  }) {
    return GrowthCenterState(
      contentItems: contentItems ?? this.contentItems,
      audienceMetrics: audienceMetrics ?? this.audienceMetrics,
      funnels: funnels ?? this.funnels,
      leads: leads ?? this.leads,
      campaigns: campaigns ?? this.campaigns,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final growthCenterProvider = StateNotifierProvider<GrowthCenterNotifier, GrowthCenterState>((ref) {
  final user = ref.watch(authProvider).user;
  return GrowthCenterNotifier(ref, user?.id ?? 'demo-user-id');
});

class GrowthCenterNotifier extends StateNotifier<GrowthCenterState> {
  final Ref ref;
  final String userId;

  GrowthCenterNotifier(this.ref, this.userId)
      : super(GrowthCenterState(
          contentItems: [],
          audienceMetrics: [],
          funnels: [],
          leads: [],
          campaigns: [],
          isLoading: true,
        )) {
    loadData();
  }

  void loadData() {
    final now = DateTime.now();

    // 1. Content Calendar Items
    final content = [
      ContentItem(
        id: 'cnt-1',
        userId: userId,
        title: '5 AI Tools That Replaced My \$4000/mo Team',
        platform: 'YouTube',
        contentType: 'Long Video',
        plannedDate: now.add(const Duration(days: 1)),
        scriptNotes: 'Hook: Showing side-by-side Claude Code vs Manual coding. Retention graph peak at min 3.',
        status: ContentStatus.recorded,
      ),
      ContentItem(
        id: 'cnt-2',
        userId: userId,
        title: 'How Tenbox Pays Creators for 60s Clips',
        platform: 'Instagram',
        contentType: 'Reel',
        plannedDate: now.add(const Duration(days: 2)),
        scriptNotes: 'Walkthrough of dashboard, payment proof of ₹24,500.',
        status: ContentStatus.scheduled,
      ),
      ContentItem(
        id: 'cnt-3',
        userId: userId,
        title: 'Prompt Breakdown: Growth OS Master Architecture',
        platform: 'Telegram',
        contentType: 'Post',
        plannedDate: now,
        scriptNotes: 'Free value drop with download link to Whop community.',
        status: ContentStatus.published,
      ),
    ];

    // 2. Audience Metrics
    final audience = [
      AudienceMetric(
        id: 'aud-1',
        userId: userId,
        platform: 'YouTube',
        count: 42500,
        totalViews: 890000,
        watchHours: 14200,
        growthNotes: 'Viral Short on AI video repurposing gained 4.2k subs.',
        recordedDate: now,
      ),
      AudienceMetric(
        id: 'aud-2',
        userId: userId,
        platform: 'Instagram',
        count: 28400,
        totalViews: 320000,
        watchHours: 0,
        growthNotes: 'Reels collab with entrepreneur niche creator.',
        recordedDate: now,
      ),
      AudienceMetric(
        id: 'aud-3',
        userId: userId,
        platform: 'Telegram',
        count: 8950,
        totalViews: 45000,
        watchHours: 0,
        growthNotes: 'Exclusive PDF lead magnet pinned in channel.',
        recordedDate: now,
      ),
    ];

    // 3. Course Funnels
    final funnels = [
      ProductFunnel(
        id: 'funnel-1',
        userId: userId,
        productName: 'AI Video Monetization Masterclass',
        productPrice: 2499.0,
        visitors: 1850,
        leads: 420,
        checkoutVisits: 145,
        sales: 68,
        refunds: 2,
      ),
      ProductFunnel(
        id: 'funnel-2',
        userId: userId,
        productName: 'Whop 1-on-1 Mentorship VIP',
        productPrice: 9999.0,
        visitors: 420,
        leads: 85,
        checkoutVisits: 28,
        sales: 12,
        refunds: 0,
      ),
    ];

    // 4. Leads
    final leads = [
      CreatorLead(
        id: 'lead-1',
        userId: userId,
        name: 'Rahul Sharma',
        platformSource: 'YouTube comment',
        contactInfo: 'rahul.s@gmail.com',
        interestedProduct: 'AI Video Masterclass',
        stage: LeadStage.followUp,
        followUpDate: now.add(const Duration(days: 1)),
        notes: 'Asked if course covers mobile workflow on Android.',
      ),
      CreatorLead(
        id: 'lead-2',
        userId: userId,
        name: 'Priya Verma',
        platformSource: 'Instagram DM',
        contactInfo: '@priyacreates',
        interestedProduct: 'Whop Mentorship VIP',
        stage: LeadStage.interested,
        notes: 'Wants to scale clipping agency from ₹20k to ₹100k/mo.',
      ),
    ];

    // 5. Campaigns
    final campaigns = [
      CampaignAnalytics(
        id: 'camp-1',
        userId: userId,
        campaignName: 'Tenbox Clipping Sprint Q4',
        platform: 'Tenbox',
        videosPublished: 14,
        totalViews: 240000,
        leads: 320,
        sales: 45,
        adSpend: 2500.0,
        totalEarnings: 38500.0,
      ),
      CampaignAnalytics(
        id: 'camp-2',
        userId: userId,
        campaignName: 'Black Friday Blueprint Launch',
        platform: 'Whop & YouTube',
        videosPublished: 6,
        totalViews: 95000,
        leads: 180,
        sales: 32,
        adSpend: 4000.0,
        totalEarnings: 52000.0,
      ),
    ];

    state = GrowthCenterState(
      contentItems: content,
      audienceMetrics: audience,
      funnels: funnels,
      leads: leads,
      campaigns: campaigns,
      isLoading: false,
    );
  }

  void addContentItem(ContentItem item) {
    state = state.copyWith(contentItems: [item, ...state.contentItems]);
  }

  void updateContentStatus(String id, ContentStatus status) {
    state = state.copyWith(
      contentItems: state.contentItems.map((c) {
        if (c.id == id) {
          return ContentItem(
            id: c.id,
            userId: c.userId,
            title: c.title,
            platform: c.platform,
            contentType: c.contentType,
            plannedDate: c.plannedDate,
            scriptNotes: c.scriptNotes,
            status: status,
            videoLink: c.videoLink,
          );
        }
        return c;
      }).toList(),
    );
  }

  void updateAudienceMetric(String platform, int count, String notes) {
    state = state.copyWith(
      audienceMetrics: state.audienceMetrics.map((a) {
        if (a.platform == platform) {
          return AudienceMetric(
            id: a.id,
            userId: a.userId,
            platform: a.platform,
            count: count,
            totalViews: a.totalViews,
            watchHours: a.watchHours,
            growthNotes: notes,
            recordedDate: DateTime.now(),
          );
        }
        return a;
      }).toList(),
    );
  }

  void addCreatorLead(CreatorLead lead) {
    state = state.copyWith(leads: [lead, ...state.leads]);
  }
}

