import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool initialized = false;

  Future<void> init() async {
    if (initialized) return;
    tz.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    final timezoneName = tzInfo.identifier;
    tz.setLocalLocation(tz.getLocation(timezoneName));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    initialized = true;
  }

  Future<bool> requestPermissionIfNeeded() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final granted = await android?.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<void> scheduleNotification({
    required int notificationId,
    required String title,
    required String? body,
    required DateTime scheduledTime,
    required int remindMinutes,
  }) async {
    if (!initialized) {
      await init();
    }

    await _plugin.cancel(notificationId);
    final advancedTime = scheduledTime.subtract(
      Duration(minutes: remindMinutes),
    );
    if (advancedTime.isBefore(DateTime.now())) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'event_reminder',
        'Event Reminder',
        channelDescription: 'Reminder for calendar events',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.zonedSchedule(
      notificationId,
      title,
      body ?? 'Event reminder',
      tz.TZDateTime.from(advancedTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelNotification(int notificationId) async {
    await _plugin.cancel(notificationId);
  }
}
