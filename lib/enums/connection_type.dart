enum ConnectionType { network, bluetooth, usb }

ConnectionType ConnectionTypefromString(String value) {
  return ConnectionType.values.firstWhere(
    (e) => e.toString().split('.').last.toLowerCase() == value.toLowerCase(),
    orElse: () => throw Exception('Unknown status: $value'),
  );
}
