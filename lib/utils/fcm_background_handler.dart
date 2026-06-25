import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_master_app/config/app_config.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📨 Background message received: ${message.messageId}');
  debugPrint('🔔 BG Notification: ${message.notification}');
  debugPrint('📦 BG Data: ${message.data}');

  final RemoteNotification? notification = message.notification;
  final Map<String, dynamic> data = message.data;

  // IMPORTANT:
  // If notification payload exists, Firebase Android already shows it.
  // Do NOT show another local notification.
  if (notification != null) {
    debugPrint(
        '✅ Firebase notification payload detected. Skipping local notification.');
    return;
  }

  // Only handle DATA-ONLY messages
  if (data.isEmpty) {
    debugPrint('⚠️ No notification payload and no data payload.');
    return;
  }

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings(AppConfig.notificationIcon);

  const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await notificationsPlugin.initialize(initSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    AppConfig.notificationChannelId,
    AppConfig.notificationChannelName,
    description: AppConfig.notificationChannelDescription,
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
    enableLights: true,
    ledColor: AppConfig.notificationColor,
  );

  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  final String title =
      data['title']?.toString() ??
      data['notificationTitle']?.toString() ??
      'Notification';

  final String body =
      data['body']?.toString() ??
      data['message']?.toString() ??
      data['notificationBody']?.toString() ??
      '';

  final AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
    AppConfig.notificationChannelId,
    AppConfig.notificationChannelName,
    channelDescription: AppConfig.notificationChannelDescription,
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    icon: AppConfig.notificationIcon,
    showWhen: true,
    color: AppConfig.notificationColor,
  );

  const DarwinNotificationDetails iosDetails =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  final NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  final int localNotificationId =
      (message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString())
              .hashCode
              .abs() %
          2147483647;

  await notificationsPlugin.show(
    localNotificationId,
    title,
    body,
    notificationDetails,
    payload: data.toString(),
  );

  debugPrint(
      '✅ Data-only notification shown: $title (ID: $localNotificationId)');
}