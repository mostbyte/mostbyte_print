enum ConnectionType { network, bluetooth, usb }

ConnectionType connectionTypeFromString(String value) {
  return ConnectionType.values.firstWhere(
    (e) => e.toString().split('.').last.toLowerCase() == value.toLowerCase(),
    orElse: () => throw Exception('Unknown status: $value'),
  );
}

String toStringConnectionType(ConnectionType type) {
  return type.toString().split('.').last;
}
