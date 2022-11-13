import 'package:sqflite/sqflite.dart';
import 'package:keys_tracker_app/models/connected_devices.dart';
import 'package:keys_tracker_app/repositories/db_connection.dart';
import 'package:keys_tracker_app/exceptions/connected_devices.dart';

class DevicesRepository {
  static const String table = "devices";
  late final Database _db;

  Future<void> init() async {
    _db = await getDbConnection();
  }

  /// Add a new device to database
  Future<void> dbAddDevice(ConnectedDevice device) async {
    final id = await _db.insert(table, device.toMap());
    if (id <= 0) throw DeviceAlreadyExist;
  }

  /// Update device in database
  Future<void> dbUpdateDevice(ConnectedDevice device) async {
    final id = await _db.update(
      table,
      device.toMap(),
      where: "mac = ?",
      whereArgs: [device.mac],
    );

    if (id <= 0) throw DeviceUpdateFailed;
  }

  /// Delete device in database
  Future<void> dbDeleteDevice(ConnectedDevice device) async {
    final id = await _db.delete(
      table,
      where: "mac = ?",
      whereArgs: [device.mac],
    );

    if (id <= 0) throw DeviceDeleteFailed;
  }

  /// Get all devices from db
  Future<List<ConnectedDevice>> dbGetAllDevices() async {
    final dMaps = await _db.query(table);
    final devices = dMaps.map((d) => ConnectedDevice.fromMap(d)).toList();
    return devices;
  }
}
