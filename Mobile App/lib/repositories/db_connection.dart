import 'dart:io';

import 'package:path/path.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:keys_tracker_app/repositories/connected_devices.dart';

const String DB_NAME = "sqflite1.db";

/// Initialize and return database connection
Future<Database> initDatabase() async {
  // await _clearDbFile();
  final dbPath = await getApplicationDocumentsDirectory();
  final db = await openDatabase(join(dbPath.path, DB_NAME), version: 1,
      onCreate: ((_db, version) async {
    await _db.execute(
      "CREATE TABLE IF NOT EXISTS ${DevicesRepository.table} (mac TEXT PRIMARY KEY, name TEXT, disabled INTEGER, rssi INTEGER, missed INTEGER, longitude REAL, latitude REAL)",
    );
  }), singleInstance: true);

  return db;
}

Future<void> _clearDbFile() async {
  final dbPath = await getApplicationDocumentsDirectory();
  File(join(dbPath.path, DB_NAME)).delete();
}

/// Get singliton instance of Database connection
Future<Database> getDbConnection() async {
  return GetIt.I.getAsync<Database>();
}
