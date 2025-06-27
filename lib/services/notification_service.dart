import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> onDidReceiveNotification(NotificationResponse notificationResponse) async {
    print("Notification receive");
  }

  static init() async {
    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings("@mipmap/ic_launcher");
    const DarwinInitializationSettings iOSInitializationSettings = DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iOSInitializationSettings,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotification,
      onDidReceiveBackgroundNotificationResponse: onDidReceiveNotification,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }


  static scheduleNotification({
    required DateTime scheduledDateTime,
    required String title,
    required String body,
  }) async {

    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    final tz.TZDateTime now = tz.TZDateTime.now(tz.getLocation(currentTimeZone));
    final tz.TZDateTime scheduled = tz.TZDateTime.from(scheduledDateTime, tz.getLocation(currentTimeZone));

    // if (scheduled.isBefore(now)) {
    //   print("Scheduled time is in the past. Notification not scheduled.");
    //   return;
    // }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'bjjfans_reminder_notifications',
      'Reminders',
      channelDescription: 'Notification channel for reminders',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
    NotificationDetails(android: androidDetails,iOS: DarwinNotificationDetails());

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      title,
      body,
      scheduled,
      platformDetails,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

}
