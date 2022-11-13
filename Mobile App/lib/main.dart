import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:keys_tracker_app/constants.dart';
import 'package:keys_tracker_app/pages/home.dart';
import 'package:keys_tracker_app/pages/scan_device.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:keys_tracker_app/services/location_service.dart';
import 'package:keys_tracker_app/services/scanner/bg_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final granted = await [
    Permission.camera,
    Permission.locationAlways,
    Permission.bluetooth,
    Permission.bluetoothAdvertise,
    Permission.bluetoothConnect,
    Permission.bluetoothScan,
    Permission.notification,
    Permission.locationWhenInUse,
  ].request();

  // print("BLUETOOTH STATUS");
  // print(await Permission.bluetoothScan.status);
  if (!(granted[Permission.camera]!.isGranted &&
      granted[Permission.locationAlways]!.isGranted &&
      granted[Permission.bluetoothScan]!.isGranted &&
      granted[Permission.notification]!.isGranted &&
      granted[Permission.locationWhenInUse]!.isGranted)) {
    exit(1);
  }

  // await Future.delayed(const Duration(seconds: 5));

  GetIt.I
      .registerSingleton<FlutterBackgroundService>(FlutterBackgroundService());

  GetIt.I.registerSingletonAsync<BackgroundService>(() async {
    final bg = BackgroundService();
    await bg.initializeService();
    return bg;
  });
  await GetIt.I.isReady<BackgroundService>();

  await LocationService.initLocationService();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keys Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          useMaterial3: true,
          primarySwatch: kPrimarySwatch,
          fontFamily: 'Roboto',
          bottomAppBarTheme: BottomAppBarTheme(color: kPrimaryColor)),
      initialRoute: HomePage.ROUTE,
      routes: {
        HomePage.ROUTE: (context) => HomePage(),
        ScanDevice.ROUTE: (context) => ScanDevice()
      },
    );
  }
}
