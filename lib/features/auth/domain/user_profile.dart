class UserProfile {
  final String id;
  final String fullName;
  final String businessName;
  final String avatarUrl;
  final String youtubeChannel;
  final String instagramUsername;
  final String telegramChannel;
  final double monthlyEarningTarget;
  final double annualEarningTarget;
  final String primaryCategory;
  String get primaryBusinessCategory => primaryCategory;
  final String preferredCurrency;
  final String timeZone;
  final bool isAdmin;
  final int streakCount;

  UserProfile({
    required this.id,
    required this.fullName,
    this.businessName = '',
    this.avatarUrl = '',
    this.youtubeChannel = '',
    this.instagramUsername = '',
    this.telegramChannel = '',
    this.monthlyEarningTarget = 100000.0,
    this.annualEarningTarget = 1200000.0,
    this.primaryCategory = 'Digital Creator',
    this.preferredCurrency = '₹',
    this.timeZone = 'Asia/Kolkata',
    this.isAdmin = false,
    this.streakCount = 1,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'Creator',
      businessName: json['business_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      youtubeChannel: json['youtube_channel'] as String? ?? '',
      instagramUsername: json['instagram_username'] as String? ?? '',
      telegramChannel: json['telegram_channel'] as String? ?? '',
      monthlyEarningTarget: (json['monthly_earning_target'] as num?)?.toDouble() ?? 100000.0,
      annualEarningTarget: (json['annual_earning_target'] as num?)?.toDouble() ?? 1200000.0,
      primaryCategory: json['primary_category'] as String? ?? 'Digital Creator',
      preferredCurrency: json['preferred_currency'] as String? ?? '₹',
      timeZone: json['time_zone'] as String? ?? 'Asia/Kolkata',
      isAdmin: json['is_admin'] as bool? ?? false,
      streakCount: json['streak_count'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'business_name': businessName,
      'avatar_url': avatarUrl,
      'youtube_channel': youtubeChannel,
      'instagram_username': instagramUsername,
      'telegram_channel': telegramChannel,
      'monthly_earning_target': monthlyEarningTarget,
      'annual_earning_target': annualEarningTarget,
      'primary_category': primaryCategory,
      'preferred_currency': preferredCurrency,
      'time_zone': timeZone,
      'is_admin': isAdmin,
      'streak_count': streakCount,
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? businessName,
    String? avatarUrl,
    String? youtubeChannel,
    String? instagramUsername,
    String? telegramChannel,
    double? monthlyEarningTarget,
    double? annualEarningTarget,
    String? primaryCategory,
    String? preferredCurrency,
    String? timeZone,
    bool? isAdmin,
    int? streakCount,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      businessName: businessName ?? this.businessName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      youtubeChannel: youtubeChannel ?? this.youtubeChannel,
      instagramUsername: instagramUsername ?? this.instagramUsername,
      telegramChannel: telegramChannel ?? this.telegramChannel,
      monthlyEarningTarget: monthlyEarningTarget ?? this.monthlyEarningTarget,
      annualEarningTarget: annualEarningTarget ?? this.annualEarningTarget,
      primaryCategory: primaryCategory ?? this.primaryCategory,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      timeZone: timeZone ?? this.timeZone,
      isAdmin: isAdmin ?? this.isAdmin,
      streakCount: streakCount ?? this.streakCount,
    );
  }
}

