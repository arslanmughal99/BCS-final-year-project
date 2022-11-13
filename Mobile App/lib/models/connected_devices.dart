// Connected device model
class ConnectedDevice {
  int rssi;
  int missed;
  String name;
  bool notify;
  final String mac;
  double? latitude;
  double? longitude;

  ConnectedDevice({
    this.rssi = 0,
    this.latitude,
    this.longitude,
    this.missed = 0,
    required this.mac,
    required this.name,
    this.notify = false,
  });

  String toString() {
    return "ConnectedDevice(name: $name, mac: $mac, disabled: $notify, rssi: $rssi, missed: $missed, long: $longitude, lat: $latitude)";
  }

  Map<String, dynamic> toJson() {
    return {
      "mac": mac,
      "name": name,
      "rssi": rssi,
      "missed": missed,
      "latitude": latitude,
      "longitude": longitude,
      "disabled": notify ? 0 : 1,
    };
  }

  static ConnectedDevice fromJson(dynamic json) {
    return ConnectedDevice(
      mac: json["mac"],
      name: json["name"],
      missed: json["missed"],
      notify: json["disabled"] == 1,
      rssi: int.parse(json["rssi"] ?? 0),
      latitude: double.parse(json["latitude"]),
      longitude: double.parse(json["longitude"]),
    );
  }

  Map<String, dynamic> toMap() {
    return Map.fromEntries([
      MapEntry("mac", mac),
      MapEntry("rssi", rssi),
      MapEntry("name", name),
      MapEntry("missed", missed),
      MapEntry("latitude", latitude),
      MapEntry("longitude", longitude),
      MapEntry("disabled", notify ? 0 : 1),
    ]);
  }

  static ConnectedDevice fromMap(Map<String, dynamic> m) {
    return ConnectedDevice(
      mac: m["mac"],
      name: m["name"],
      rssi: m["rssi"] ?? 0,
      missed: m["missed"] ?? 0,
      notify: m["disabled"] == 0,
      latitude: m["latitude"],
      longitude: m["longitude"],
    );
  }
}
