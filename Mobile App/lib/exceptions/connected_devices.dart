class DeviceAlreadyExist implements Exception {
  const DeviceAlreadyExist();
  String toString() => "[DeviceAlreadyExist] Device already exist";
}

class DeviceUpdateFailed implements Exception {
  const DeviceUpdateFailed();
  String toString() => "[DeviceUpdateFailed] Device update failed";
}

class DeviceDeleteFailed implements Exception {
  const DeviceDeleteFailed();
  String toString() => "[DeviceDeleteFailed] Device delete failed";
}
