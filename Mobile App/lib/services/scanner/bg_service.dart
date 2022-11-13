import 'package:get_it/get_it.dart';
import 'package:keys_tracker_app/services/scanner/bg_scan.dart';
import 'package:keys_tracker_app/services/scanner/scanner.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BackgroundService {
  static const String BG_ERRORS_CHAN = "BG_ERRORS_CHAN";
  final _service = GetIt.I.get<FlutterBackgroundService>();

  /// Initialize background service and notification.
  /// Must be called before runApp
  Future<void> initializeService() async {
    const channel = AndroidNotificationChannel(
      Scanner.NOTIFICATION_CHANNEL_ID, // id
      'Initializing', // title
      importance: Importance.low, // importance must be at low or higher level
      description: 'Starting tracker', // description
    );

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _service.configure(
      iosConfiguration: IosConfiguration(
        onBackground: (ServiceInstance s) async {
          return Future.value(true);
        },
        onForeground: BGScan.onStart,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: BGScan.onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: Scanner
            .NOTIFICATION_CHANNEL_ID, // this must match with notification channel you created above.
        initialNotificationTitle: 'Initializing',
        initialNotificationContent: 'Starting tracker',
        foregroundServiceNotificationId: Scanner.NOTIFICATION_ID,
      ),
    );
  }
}
