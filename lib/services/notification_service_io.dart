import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static final List<String> _messages = [
    'You are one habit away from a stronger streak. Make today count!',
    'Every task completed earns XP and brings your goals closer. Keep going!',
    'Strong habits create unstoppable momentum. Crush a task now!',
    'Your streak is waiting. Take action, earn rewards, and stay on fire!',
    'Build consistency today and watch your XP skyrocket.',
    'A small win today becomes a big success tomorrow. Keep the momentum!',
    'Stay committed, stay energized, and keep leveling up.',
    'Your better self is coming. Complete one habit and keep the streak alive.',
    'Earn XP, collect gems, and prove your progress one task at a time.',
    'You are building greatness. One more task and one more streak day.',
  ];

  static Future<void> initialize() async {
    if (kIsWeb) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestAlertPermission: false,
      requestBadgePermission: false,
    );
    const macos = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestAlertPermission: false,
      requestBadgePermission: false,
    );
    const linux = LinuxInitializationSettings(defaultActionName: 'Open app');
    const settings = InitializationSettings(
      android: android,
      iOS: ios,
      macOS: macos,
      linux: linux,
    );

    await _plugin.initialize(settings);
    await _requestPermissions();
    await _configureLocalTimeZone();
  }

  static Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }

    if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();

    try {
      final Object timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timezoneName = timezoneInfo is String
          ? timezoneInfo
          : (timezoneInfo as dynamic).identifier as String;
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (error, stackTrace) {
      debugPrint('Timezone configuration failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      tz.setLocalLocation(tz.local);
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static String _randomMessage() {
    final random = Random();
    return _messages[random.nextInt(_messages.length)];
  }

  static const _androidGentleTone = UriAndroidNotificationSound('content://settings/system/notification_sound');

  static NotificationDetails _notificationDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: _androidGentleTone,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      ),
      linux: const LinuxNotificationDetails(defaultActionName: 'Open app'),
    );
  }

  static Future<void> scheduleDailyMotivation({int hour = 8, int minute = 0}) async {
    if (kIsWeb) return;

    await _plugin.cancel(0);
    await _plugin.zonedSchedule(
      0,
      '1% Better Reminder',
      _randomMessage(),
      _nextInstanceOfTime(hour, minute),
      _notificationDetails(
        channelId: 'daily_reminder',
        channelName: 'Daily Motivation',
        channelDescription: 'Daily habit reminders and XP motivation',
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> showTaskCompletedNotification(int reward) async {
    if (kIsWeb) return;

    final message = 'Nice work! You earned $reward XP and moved your streak forward.';
    await _plugin.show(
      1,
      'Task Completed',
      message,
      _notificationDetails(
        channelId: 'task_complete',
        channelName: 'Task Completion',
        channelDescription: 'Notifications for completed tasks and XP rewards',
      ),
    );
  }

  static Future<void> showMotivationalNotification() async {
    if (kIsWeb) return;

    await _plugin.show(
      2,
      'Keep Going!',
      _randomMessage(),
      _notificationDetails(
        channelId: 'motivation',
        channelName: 'Motivation',
        channelDescription: 'Motivational messages to keep your habits strong',
      ),
    );
  }
}
