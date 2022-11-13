import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AlertService {
  static const int BLE_ON_NOTI_ID = 1235;
  static const int NOTIFICATION_ID = 5244;
  static const String NOTIFICATION_CHANNEL_ID = "alert_id";

  static const channel = AndroidNotificationChannel(
    NOTIFICATION_CHANNEL_ID, // id
    'Out of range', // title
    importance: Importance.high, // importance must be at low or higher level
    description: 'Did you forget ?', // description
  );

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Clear turn ble on notification
  Future<void> bleIsOn() async {
    await flutterLocalNotificationsPlugin.cancel(BLE_ON_NOTI_ID);
  }

  /// Show turn ble on notification
  Future<void> bleIsOff() async {
    flutterLocalNotificationsPlugin.show(
      BLE_ON_NOTI_ID,
      "Turn on bluetooth",
      "Please turn on bluetooth for tracking.",
      NotificationDetails(
        android: AndroidNotificationDetails(
          NOTIFICATION_CHANNEL_ID,
          "Bluetooth off",
          enableLights: true,
          icon: 'ic_bg_service_small',
        ),
      ),
    );
  }

  /// Show out of range notification
  Future<void> outOfRangeAlert(String deviceName) async {
    flutterLocalNotificationsPlugin.show(
      NOTIFICATION_ID,
      "Out of range",
      "You forgot ${deviceName} behind.",
      NotificationDetails(
        android: AndroidNotificationDetails(
          NOTIFICATION_CHANNEL_ID,
          "Left behind",
          enableLights: true,
          icon: 'ic_bg_service_small',
        ),
      ),
    );
  }
}
