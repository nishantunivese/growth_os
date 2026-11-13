import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../database/local_db_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          // Handle notification tap
        },
      );
      _isInitialized = true;
    } catch (_) {
      // Graceful fallback if platform is not yet ready
    }
  }

  /// Evaluates smart rules before sending project update reminder:
  /// 1. Quiet hours (no notifications between 10 PM and 7 AM)
  /// 2. Deduplication (no reminder if user already posted an update within the last [intervalHours])
  Future<bool> shouldSendProjectReminder(String projectId, int intervalHours) async {
    final now = DateTime.now();
    // Quiet hours check
    if (now.hour >= 22 || now.hour < 7) {
      return false;
    }

    final updates = await LocalDbService.instance.getUpdates(projectId);
    if (updates.isNotEmpty) {
      final latestDate = DateTime.tryParse(updates.first['created_at'] ?? '');
      if (latestDate != null) {
        final hoursSinceLast = now.difference(latestDate).inHours;
        if (hoursSinceLast < intervalHours) {
          return false; // Skip reminder, already updated recently
        }
      }
    }
    return true;
  }

  /// Evaluates smart rules before sending daily earning reminder:
  /// 1. Skips if an income entry has already been recorded today
  Future<bool> shouldSendGoalReminder() async {
    final now = DateTime.now();
    if (now.hour >= 22 || now.hour < 7) {
      return false;
    }

    final incomes = await LocalDbService.instance.getIncome();
    final today = DateTime(now.year, now.month, now.day);
    for (var inc in incomes) {
      final date = DateTime.tryParse(inc['date'] ?? '');
      if (date != null && (date.isAfter(today) || date.isAtSameMomentAs(today))) {
        return false; // Earnings already updated today!
      }
    }
    return true;
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'growth_os_reminders',
      'Growth OS Smart Reminders',
      channelDescription: 'Intelligent business milestone and project cadence reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationSettings(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        const NotificationDetails(android: androidDetails),
        payload: payload,
      );
    } catch (_) {}
  }
}

