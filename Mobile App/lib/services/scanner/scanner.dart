import 'dart:async';

import 'package:mutex/mutex.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';
import 'package:keys_tracker_app/services/alert_service.dart';
import 'package:keys_tracker_app/models/connected_devices.dart';
import 'package:keys_tracker_app/services/scanner/bg_service.dart';
import 'package:keys_tracker_app/repositories/connected_devices.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class Scanner {
  final ServiceInstance service;
  final mutex = ReadWriteMutex();
  final DevicesRepository deviceRepo;
  final alertService = GetIt.I.get<AlertService>();

  Scanner({required this.deviceRepo, required this.service}) {
    handleMainIsolateEvents();
  }

  static const int NOTIFICATION_ID = 888;
  static const String BG_SCAN_CHANNEL = "scan/update";
  static const String NOTIFICATION_CHANNEL_ID = "my_foreground";
  static const String CRUD_BGSERVICE_UPDATE_CHAN =
      "crud-bg-service-update-chan";
  static const String UI_DEVICES_STREAM_CHAN = "ui-devices-stream-chan";
  static const String CRUD_BGSERVICE_ADD_CHAN = "crud-bg-service-add-chan";
  static const String CRUD_BGSERVICE_DEL_CHAN = "crud-bg-service-del-chan";

  /// Connected devices with scan information
  List<ConnectedDevice> _devices = [];

  /// Get current devices being process by scanner
  List<ConnectedDevice> get devices => _devices;

  /// Set new devices list and update stream
  void set devices(List<ConnectedDevice> _ds) {
    _devices = _ds;
    _devicesSubject.add(_devices);
  }

  /// Update connected device stream
  void updateStream(List<ConnectedDevice> _ds) {
    _devices = List.from(_ds);
    _devicesSubject.add(_ds);
  }

  /// BehaviourSubject to handle stream of latest device information
  final BehaviorSubject<List<ConnectedDevice>> _devicesSubject =
      BehaviorSubject<List<ConnectedDevice>>();

  /// latest device information stream
  ValueStream<List<ConnectedDevice>> get stream$ => _devicesSubject.stream;

  /// Add new device to stream and Db
  Future<void> addDevice(ConnectedDevice d) async {
    final exist = _devices.indexWhere((_d) => _d.mac == d.mac);

    if (exist > -1) {
      service.invoke(BackgroundService.BG_ERRORS_CHAN,
          {"error": "Tracker already exist."});
      return;
    }

    await deviceRepo.dbAddDevice(d);

    _devices.add(d);
    _devicesSubject.add(_devices);
  }

  /// Update device in stream and on Db
  Future<void> updateDevice(ConnectedDevice d) async {
    await mutex.acquireWrite();
    await deviceRepo.dbUpdateDevice(d);

    _devices = _devices.map((e) {
      if (e.mac == d.mac) {
        return d;
      }
      return e;
    }).toList();
    mutex.release();
    _devicesSubject.add(_devices);
  }

  /// Delete device from stream and Db
  Future<void> deleteDevice(ConnectedDevice d) async {
    _devices.removeWhere((_d) => _d.mac == d.mac);
    await deviceRepo.dbDeleteDevice(d);
    devices = _devices;
  }

  /// Handle crud event from main isolate
  void _crudHandler() {
    // Update device event handler
    service.on(CRUD_BGSERVICE_UPDATE_CHAN).listen((_payload) async {
      final d = ConnectedDevice.fromMap(_payload!["device"]);
      try {
        await updateDevice(d);
      } catch (e) {
        service.invoke(BackgroundService.BG_ERRORS_CHAN,
            {"error": "Something went wrong."});
      }
    });

    // Add device event handler
    service.on(CRUD_BGSERVICE_ADD_CHAN).listen((_payload) async {
      final d = ConnectedDevice.fromMap(_payload!["device"]);
      await addDevice(d);
    });

    // Delete device event handler
    service.on(CRUD_BGSERVICE_DEL_CHAN).listen((_payload) async {
      final d = ConnectedDevice.fromMap(_payload!["device"]);
      try {
        await deleteDevice(d);
      } catch (e) {
        service.invoke(BackgroundService.BG_ERRORS_CHAN,
            {"error": "Something went wrong."});
      }
    });
  }

  /// Load persistent devices from disk.
  /// Must be called before runApp function
  Future<void> loadConnectedDevices() async {
    final deviceRepo = GetIt.I.get<DevicesRepository>();
    _devices = await deviceRepo.dbGetAllDevices();
    _devicesSubject.add(_devices);
  }

  /// Update UI with latest devices
  void _updateUIHandler() {
    stream$.listen((payload) {
      service.invoke(UI_DEVICES_STREAM_CHAN, {"devices": payload});
    });
  }

  void _alertHandler() {
    stream$.listen((devices) {
      devices.where((device) => !device.notify).forEach((device) async {
        // print("DEVICE");
        // print(device);
        if (device.missed > 1) {
          alertService.outOfRangeAlert(device.name);
          device.missed = 0;
          device.notify = true;
          await updateDevice(device);
        }
      });
    });
  }

  /// Handle message passing between main isolate and background isolate.
  void handleMainIsolateEvents() {
    // handle bg scan events
    _updateUIHandler();
    _crudHandler();
    _alertHandler();
  }
}
