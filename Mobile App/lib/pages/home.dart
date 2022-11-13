import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:keys_tracker_app/constants.dart';
import 'package:keys_tracker_app/pages/scan_device.dart';
import 'package:keys_tracker_app/models/connected_devices.dart';
import 'package:keys_tracker_app/services/scanner/scanner.dart';
import 'package:keys_tracker_app/services/scanner/bg_service.dart';
import 'package:keys_tracker_app/components/devices_list_card.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class HomePage extends StatefulWidget {
  static const String ROUTE = 'home';

  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ConnectedDevice> devices = [];
  List<ConnectedDevice> filteredDevices = [];
  final searchCtrl = TextEditingController();
  final bgService = GetIt.I.get<FlutterBackgroundService>();

  @override
  void initState() {
    super.initState();
    displayBGErrors();
    searchCtrl.addListener(() {
      setState(() {
        filteredDevices = searchCtrl.text.isNotEmpty
            ? devices
                .where(
                  (_d) => _d.name.toUpperCase().startsWith(
                        searchCtrl.text.toUpperCase(),
                      ),
                )
                .toList()
            : devices;
      });
    });

    bgService.on(Scanner.UI_DEVICES_STREAM_CHAN).listen((payload) {
      if (payload == null) return;

      final _newScannedDevices = List.from(payload["devices"], growable: false)
          .map((d) => ConnectedDevice.fromMap(d))
          .toList(growable: false);

      devices = _newScannedDevices;
      if (searchCtrl.text.isEmpty) {
        setState(() {
          filteredDevices = devices;
        });
      }
    });
  }

  void displayBGErrors() {
    bgService.on(BackgroundService.BG_ERRORS_CHAN).listen((err) {
      if (err == null) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err["error"]),
      ));
    });
  }

  void addDevice(BuildContext context, ConnectedDevice _d) {
    bgService.invoke(
      Scanner.CRUD_BGSERVICE_ADD_CHAN,
      Map.fromEntries([MapEntry("device", _d)]),
    );
  }

  Future<void> showAddDeviceDialog(BuildContext ctx, String mac) async {
    final _nameCtrl = TextEditingController();

    await showDialog(
      context: ctx,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Tracker"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              child: const Text("Save"),
              onPressed: () async {
                final d = ConnectedDevice(
                  rssi: 0,
                  mac: mac.toUpperCase(),
                  notify: true,
                  name: _nameCtrl.text,
                );
                addDevice(ctx, d);
                Navigator.of(context).pop();
              },
            ),
          ],
          content: TextFormField(
            autofocus: true,
            autocorrect: false,
            controller: _nameCtrl,
            decoration: InputDecoration(
              label: const Text("Name"),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndDocked,
      floatingActionButton: FloatingActionButton(
        shape: CircleBorder(),
        onPressed: () async {
          final mac = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ScanDevice()),
          );
          if (mac == null) return;
          await showAddDeviceDialog(context, mac);
        },
        child: Icon(Icons.add),
      ),
      //
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Trackers"),
            const SizedBox(height: 10),
            CupertinoSearchTextField(
              controller: searchCtrl,
            ),
          ],
        ),
        titleTextStyle: TextStyle(
          fontSize: 30,
          color: kTextPrimary,
        ),
      ),
      //
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(width: 10),
              const Text(
                "BCS final year project by Arsalan Mughal\nSubmited to Govt College Kalimori Hyderabad.",
                style: TextStyle(color: Colors.white),
              )
            ],
          ),
        ),
        shape: CircularNotchedRectangle(),
      ),
      //
      body: devices.isEmpty
          ? Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.track_changes_sharp,
                    color: kTextPrimary,
                  ),
                  const Text("Click + to add device")
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.only(top: 5, bottom: 5),
              itemCount: filteredDevices.length,
              itemBuilder: (ctx, idx) {
                return DeviceCard(
                  device: filteredDevices[idx],
                );
              },
            ),
    );
  }
}
