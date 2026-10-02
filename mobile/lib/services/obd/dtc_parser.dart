/// Decodes a Mode 03 ("read stored DTCs") response into a list of fault codes.
///
/// A typical reply is `43 01 33 03 01 00 00`:
/// - `43` is the response mode (request `03` + 0x40).
/// - The remaining bytes are two-byte code pairs (`01 33`, `03 01`).
/// - `00 00` is padding and marks the end of the list.
///
/// Echoed commands are tolerated: any bytes before the `43` marker are ignored.
List<String> parseDtcCodes(String response) {
  final bytes = _toBytes(response);
  final start = bytes.indexOf(0x43);
  final data = start == -1 ? bytes : bytes.sublist(start + 1);

  final codes = <String>[];
  for (var i = 0; i + 1 < data.length; i += 2) {
    final a = data[i];
    final b = data[i + 1];
    if (a == 0 && b == 0) break; // padding
    codes.add(_decodeDtc(a, b));
  }
  return codes;
}

/// Converts two raw bytes into the standard 5-character DTC string,
/// e.g. `01 33` -> `P0133`.
String _decodeDtc(int a, int b) {
  const letters = ['P', 'C', 'B', 'U'];
  final letter = letters[(a >> 6) & 0x03];
  final digit2 = (a >> 4) & 0x03;
  final digit3 = a & 0x0F;
  final digit4 = (b >> 4) & 0x0F;
  final digit5 = b & 0x0F;
  return '$letter$digit2'
      '${digit3.toRadixString(16).toUpperCase()}'
      '${digit4.toRadixString(16).toUpperCase()}'
      '${digit5.toRadixString(16).toUpperCase()}';
}

List<int> _toBytes(String response) {
  final bytes = <int>[];
  for (final token in response.split(RegExp(r'[\s\r\n]+'))) {
    if (token.isEmpty) continue;
    final value = int.tryParse(token, radix: 16);
    if (value != null) bytes.add(value);
  }
  return bytes;
}
