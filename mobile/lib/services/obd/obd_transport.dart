/// A Bluetooth OBD-II adapter the app can connect to.
class ObdDevice {
  final String name;
  final String address;

  const ObdDevice({required this.name, required this.address});

  @override
  String toString() => '$name ($address)';
}

/// Raised when a transport cannot connect, is not connected, or times out.
class ObdTransportException implements Exception {
  final String message;

  ObdTransportException(this.message);

  @override
  String toString() => 'ObdTransportException: $message';
}

/// The low-level link between the app and an ELM327 adapter.
///
/// Everything above this interface (the AT protocol client, the service, the
/// UI) is deliberately unaware of *how* bytes reach the adapter. That lets a
/// real Bluetooth Classic (SPP) link and a mock simulator be swapped freely —
/// which is what makes the whole stack testable without a car.
abstract class ObdTransport {
  /// Whether a link is currently open.
  bool get isConnected;

  /// Opens a link to [device].
  Future<void> connect(ObdDevice device);

  /// Writes raw characters to the adapter (the caller includes the `\r`).
  Future<void> writeRaw(String data);

  /// Incoming characters from the adapter (responses, prompts, banners).
  Stream<String> get input;

  /// Closes the link and releases resources.
  Future<void> disconnect();
}
