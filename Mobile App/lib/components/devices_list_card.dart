import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:keys_tracker_app/constants.dart';
import 'package:keys_tracker_app/models/connected_devices.dart';
import 'package:keys_tracker_app/services/scanner/scanner.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class DeviceCard extends StatefulWidget {
  final ConnectedDevice device;
  DeviceCard({super.key, required this.device});

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  bool editing = false;
  bool expanded = false;
  final updateNameCtrl = TextEditingController();
  final bgService = GetIt.I.get<FlutterBackgroundService>();

  void updateDevice(ConnectedDevice d) {
    bgService.invoke(Scanner.CRUD_BGSERVICE_UPDATE_CHAN, {"device": d});
  }

  void deleteDevice(ConnectedDevice d) {
    bgService.invoke(Scanner.CRUD_BGSERVICE_DEL_CHAN, {"device": d});
  }

  void saveName() async {
    final newName = updateNameCtrl.text;
    if (newName.isEmpty) {
      return;
    }
    final d = widget.device;
    d.name = newName;
    updateDevice(d);
    setState(() {
      editing = false;
    });
  }

  Future<void> lauchMap() async {
    final mapAvailable = await MapLauncher.isMapAvailable(MapType.google);
    if (mapAvailable != null && mapAvailable) {
      await MapLauncher.showMarker(
        zoom: 100,
        mapType: MapType.google,
        title: widget.device.name,
        coords: Coords(widget.device.latitude!, widget.device.longitude!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: ExpansionTile(
        leading: Icon(
          color: kPrimaryColor,
          !widget.device.notify
              ? Icons.label_outline
              : Icons.label_off_outlined,
        ),
        tilePadding: EdgeInsets.zero,
        onExpansionChanged: (_expanded) => setState(() {
          expanded = _expanded;
          if (!_expanded) editing = false;
        }),
        title: Container(
          width: 200,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              editing
                  ? SizedBox(
                      child: CupertinoTextField(
                        controller: updateNameCtrl,
                      ),
                      width: 150,
                    )
                  : Text(widget.device.name),
              Row(
                children: [
                  const Icon(
                    color: kSecondaryColor,
                    Icons.signal_cellular_alt,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "${widget.device.rssi.toString()} dbm",
                    style: TextStyle(color: kTextSecondary),
                  )
                ],
              )
            ],
          ),
        ),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text("Notify:"),
                  Switch(
                    onChanged: (value) async {
                      final d = widget.device;
                      d.notify = !value;
                      updateDevice(d);
                    },
                    activeColor: kPrimaryColor,
                    value: !widget.device.notify,
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    iconSize: 20,
                    onPressed: () => deleteDevice(widget.device),
                    splashRadius: 20,
                    color: kPrimaryColor,
                    icon: Icon(Icons.delete),
                  ),
                  Visibility(
                    visible: editing,
                    replacement: IconButton(
                      iconSize: 20,
                      onPressed: () {
                        setState(() {
                          editing = true;
                          updateNameCtrl.text = widget.device.name;
                        });
                      },
                      splashRadius: 20,
                      color: kPrimaryColor,
                      icon: Icon(Icons.edit),
                    ),
                    child: IconButton(
                      iconSize: 20,
                      onPressed: saveName,
                      splashRadius: 20,
                      color: kPrimaryColor,
                      icon: Icon(Icons.save),
                    ),
                  ),
                  IconButton(
                    color: kPrimaryColor,
                    icon: Icon(Icons.location_on_outlined),
                    onPressed:
                        widget.device.longitude != null ? lauchMap : null,
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}
