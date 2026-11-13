// Feature 1: Content Calendar
enum ContentStatus {
  idea,
  scripted,
  recorded,
  edited,
  scheduled,
  published,
}

class ContentItem {
  final String id;
  final String userId;
  final String title;
  final String platform; // YouTube, Instagram, Telegram
  final String contentType; // Long Video, Short, Reel, Post, Story
  final DateTime plannedDate;
  final String scriptNotes;
  final ContentStatus status;
  final String? videoLink;

  ContentItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.platform,
    required this.contentType,
    required this.plannedDate,
    this.scriptNotes = '',
    this.status = ContentStatus.idea,
    this.videoLink,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'platform': platform,
      'content_type': contentType,
      'planned_date': plannedDate.toIso8601String(),
      'script_notes': scriptNotes,
      'status': status.name,
      'video_link': videoLink,
    };
  }

  factory ContentItem.fromMap(Map<String, dynamic> map) {
    return ContentItem(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      title: map['title'] ?? '',
      platform: map['platform'] ?? 'YouTube',
      contentType: map['content_type'] ?? 'Short',
      plannedDate: map['planned_date'] != null ? DateTime.parse(map['planned_date']) : DateTime.now(),
      scriptNotes: map['script_notes'] ?? '',
      status: ContentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ContentStatus.idea,
      ),
      videoLink: map['video_link'],
    );
  }
}

// Feature 2: Audience Metrics
class AudienceMetric {
  final String id;
  final String userId;
  final String platform; // YouTube, Instagram, Telegram
  final int count; // Subscribers or Followers
  final int totalViews;
  final int watchHours;
  final String growthNotes;
  final DateTime recordedDate;

  AudienceMetric({
    required this.id,
    required this.userId,
    required this.platform,
    required this.count,
    this.totalViews = 0,
    this.watchHours = 0,
    this.growthNotes = '',
    required this.recordedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'platform': platform,
      'count': count,
      'total_views': totalViews,
      'watch_hours': watchHours,
      'growth_notes': growthNotes,
      'recorded_date': recordedDate.toIso8601String(),
    };
  }

  factory AudienceMetric.fromMap(Map<String, dynamic> map) {
    return AudienceMetric(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      platform: map['platform'] ?? 'YouTube',
      count: map['count'] ?? 0,
      totalViews: map['total_views'] ?? 0,
      watchHours: map['watch_hours'] ?? 0,
      growthNotes: map['growth_notes'] ?? '',
      recordedDate: map['recorded_date'] != null ? DateTime.parse(map['recorded_date']) : DateTime.now(),
    );
  }
}

// Feature 3: Course Sales Funnel
class ProductFunnel {
  final String id;
  final String userId;
  final String productName;
  final double productPrice;
  final int visitors;
  final int leads;
  final int checkoutVisits;
  final int sales;
  final int refunds;

  ProductFunnel({
    required this.id,
    required this.userId,
    required this.productName,
    required this.productPrice,
    this.visitors = 0,
    this.leads = 0,
    this.checkoutVisits = 0,
    this.sales = 0,
    this.refunds = 0,
  });

  double get totalRevenue => sales * productPrice;
  double get conversionRate => visitors > 0 ? (sales / visitors) * 100 : 0.0;
  double get leadConversionRate => leads > 0 ? (sales / leads) * 100 : 0.0;
  double get refundRate => sales > 0 ? (refunds / sales) * 100 : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'product_name': productName,
      'product_price': productPrice,
      'visitors': visitors,
      'leads': leads,
      'checkout_visits': checkoutVisits,
      'sales': sales,
      'refunds': refunds,
    };
  }

  factory ProductFunnel.fromMap(Map<String, dynamic> map) {
    return ProductFunnel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      productName: map['product_name'] ?? '',
      productPrice: (map['product_price'] as num?)?.toDouble() ?? 0.0,
      visitors: map['visitors'] ?? 0,
      leads: map['leads'] ?? 0,
      checkoutVisits: map['checkout_visits'] ?? 0,
      sales: map['sales'] ?? 0,
      refunds: map['refunds'] ?? 0,
    );
  }
}

// Feature 4: Creator Lead
enum LeadStage {
  interested,
  followUp,
  closed,
  lost,
}

class CreatorLead {
  final String id;
  final String userId;
  final String name;
  final String platformSource; // YouTube comment, Instagram DM, Telegram, Website, Ads
  final String contactInfo;
  final String interestedProduct;
  final LeadStage stage;
  final DateTime? followUpDate;
  final String notes;

  CreatorLead({
    required this.id,
    required this.userId,
    required this.name,
    required this.platformSource,
    required this.contactInfo,
    this.interestedProduct = '',
    this.stage = LeadStage.interested,
    this.followUpDate,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'platform_source': platformSource,
      'contact_info': contactInfo,
      'interested_product': interestedProduct,
      'stage': stage.name,
      'follow_up_date': followUpDate?.toIso8601String(),
      'notes': notes,
    };
  }

  factory CreatorLead.fromMap(Map<String, dynamic> map) {
    return CreatorLead(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      name: map['name'] ?? '',
      platformSource: map['platform_source'] ?? 'Instagram DM',
      contactInfo: map['contact_info'] ?? '',
      interestedProduct: map['interested_product'] ?? '',
      stage: LeadStage.values.firstWhere(
        (e) => e.name == map['stage'],
        orElse: () => LeadStage.interested,
      ),
      followUpDate: map['follow_up_date'] != null ? DateTime.parse(map['follow_up_date']) : null,
      notes: map['notes'] ?? '',
    );
  }
}

// Feature 5: Campaign Analytics
class CampaignAnalytics {
  final String id;
  final String userId;
  final String campaignName;
  final String platform;
  final int videosPublished;
  final int totalViews;
  final int leads;
  final int sales;
  final double adSpend;
  final double totalEarnings;

  CampaignAnalytics({
    required this.id,
    required this.userId,
    required this.campaignName,
    required this.platform,
    this.videosPublished = 0,
    this.totalViews = 0,
    this.leads = 0,
    this.sales = 0,
    this.adSpend = 0.0,
    this.totalEarnings = 0.0,
  });

  double get viewsToLeadRatio => totalViews > 0 ? (leads / totalViews) * 100 : 0.0;
  double get leadToSaleRatio => leads > 0 ? (sales / leads) * 100 : 0.0;
  double get roi => adSpend > 0 ? ((totalEarnings - adSpend) / adSpend) * 100 : 100.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'campaign_name': campaignName,
      'platform': platform,
      'videos_published': videosPublished,
      'total_views': totalViews,
      'leads': leads,
      'sales': sales,
      'ad_spend': adSpend,
      'total_earnings': totalEarnings,
    };
  }

  factory CampaignAnalytics.fromMap(Map<String, dynamic> map) {
    return CampaignAnalytics(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      campaignName: map['campaign_name'] ?? '',
      platform: map['platform'] ?? 'Tenbox',
      videosPublished: map['videos_published'] ?? 0,
      totalViews: map['total_views'] ?? 0,
      leads: map['leads'] ?? 0,
      sales: map['sales'] ?? 0,
      adSpend: (map['ad_spend'] as num?)?.toDouble() ?? 0.0,
      totalEarnings: (map['total_earnings'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

