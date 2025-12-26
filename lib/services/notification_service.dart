import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class CoreNotificationService {
  static final CoreNotificationService _instance = CoreNotificationService._internal();
  factory CoreNotificationService() => _instance;
  CoreNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
      },
    );
  }

  Future<void> scheduleDailyNotification(TimeOfDay time) async {
    await _notificationsPlugin.cancelAll();

    final now = tz.TZDateTime.now(tz.local);
   var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      0,
      'Time to Reflect',
      'The day has passed. What did you forge today?',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reflection_channel',
          'Daily Reflection',
          channelDescription: 'Reminders to reflect on your day',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
