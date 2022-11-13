import 'dart:ui';
import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:sqflite/sqflite.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:keys_tracker_app/services/alert_service.dart';
import 'package:keys_tracker_app/models/connected_devices.dart';
import 'package:keys_tracker_app/services/scanner/scanner.dart';
import 'package:keys_tracker_app/repositories/db_connection.dart';
import 'package:keys_tracker_app/services/scanner/bg_service.dart';
import 'package:keys_tracker_app/repositories/connected_devices.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BGScan {
  static const String DEVICE_FILTER_CHAN = "filter-devices";

  /// scan ble devices in background service and pass results to main isolate
  static void bgScan(ServiceInstance service) async {
    bool bleON = false;
    final scanner = GetIt.I.get<Scanner>();
    final alertService = GetIt.I.get<AlertService>();

    FlutterBluePlus.instance.state.listen((event) async {
      switch (event) {
        case BluetoothState.off:
          bleON = false;
          await alertService.bleIsOff();
          service.invoke(BackgroundService.BG_ERRORS_CHAN,
              {"error": "Please turn on bluetooth."});
          break;
        case BluetoothState.on:
          bleON = true;
          await alertService.bleIsOn();
          break;
        default:
          break;
      }
    });

    while (true) {
      List<Map<String, String>> newScans = [];
      final _location = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      if (!bleON) {
        await Future.delayed(const Duration(seconds: 2));
        continue;
      }
      // print("STARTING SCAN ...");
      await FlutterBluePlus.instance.stopScan();
      StreamSubscription<ScanResult> handle = FlutterBluePlus.instance
          .scan(
        allowDuplicates: false,
        scanMode: ScanMode.balanced,
        timeout: const Duration(seconds: 5),
        macAddresses: scanner.devices.map((d) => d.mac).toList(growable: false),
      )
          .listen((r) {
        // print("Device Found: ${r.device.id}");
        newScans.add({
          "rssi": r.rssi.toString(),
          "mac": r.device.id.toString().toUpperCase(),
        });
      });

      try {
        /* wait until devices are scanned */
        await handle.asFuture();
        // print("SCAN COMPLETED...");
      } catch (err) {
        print("ERROR OCCUR IN BLE.");
        // print(err);
        await Future.delayed(const Duration(seconds: 2));
        continue;
      }

      final List<ConnectedDevice> updatedDevices = [];

      // ignore: avoid_function_literals_in_foreach_calls
      await scanner.mutex.acquireWrite();

      final _devices = List<ConnectedDevice>.from(scanner.devices);

      _devices.forEach((d) {
        final c = ConnectedDevice(
          mac: d.mac,
          name: d.name,
          rssi: d.rssi,
          missed: d.missed,
          notify: d.notify,
          latitude: d.latitude,
          longitude: d.longitude,
        );

        int idx = newScans.indexWhere((s) => s["mac"].toString() == d.mac);

        if (idx == -1) {
          c.rssi = 0;
          c.missed += 1;
        } else {
          c.missed = 0;
          c.rssi = int.parse(newScans[idx]["rssi"]!);
          c.latitude = _location.latitude;
          c.longitude = _location.longitude;
        }

        if (d.notify) {
          c.missed = 0;
        }

        updatedDevices.add(c);
      });

      scanner.updateStream(updatedDevices);
      scanner.mutex.release();
      /* wait for specific time before rescan */
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  /// Top-level function called on app start
  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    GetIt.I.registerSingletonAsync<Database>(() async {
      final db = await initDatabase();
      return db;
    });
    await GetIt.I.isReady<Database>();

    GetIt.I.registerSingletonAsync<DevicesRepository>(() async {
      final repo = DevicesRepository();
      await repo.init();
      return repo;
    });
    await GetIt.I.isReady<DevicesRepository>();

    GetIt.I.registerSingletonAsync<AlertService>(() async {
      final a = AlertService();
      await a.init();
      return a;
    });
    await GetIt.I.isReady<AlertService>();

    GetIt.I.registerSingleton<Scanner>(
      Scanner(deviceRepo: GetIt.I.get<DevicesRepository>(), service: service),
    );

    GetIt.I.get<Scanner>().loadConnectedDevices();

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    bgScan(service);

    flutterLocalNotificationsPlugin.show(
      Scanner.NOTIFICATION_ID,
      'Tracking',
      'I will inform you when you are away 😊',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          Scanner.NOTIFICATION_CHANNEL_ID,
          'MY FOREGROUND SERVICE',
          icon: 'ic_bg_service_small',
          ongoing: true,
        ),
      ),
    );
  }
}
