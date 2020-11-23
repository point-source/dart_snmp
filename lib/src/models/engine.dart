import 'dart:math';
import 'dart:typed_data';

class Engine {
  Engine(
      {Uint8List engineId,
      this.engineBoots = 0,
      this.engineTime = 10,
      this.maxMessageSize = 65507})
      : _engineId = engineId;

  /// A unique ID which identifies this SNMP agent on the network
  Uint8List _engineId;
  int engineBoots;
  int engineTime;

  /// The maximum size of message that the sender of this message can receive (default is 65507, min is 484)
  int maxMessageSize;

  Uint8List get engineId => _engineId ??= _engineId = generateEngineId();

  set engineId(Uint8List i) => _engineId = i;

  /// Generate a 17-byte Engine ID
  ///
  /// Bytes 1-4 are enterprise OID.
  /// Fifth byte specifies enterprise format.
  /// Remaining bytes are random.
  Uint8List generateEngineId() {
    var b = Uint8List(17);
    b.setRange(0, 5, [0x80, 0x00, 0xB9, 0x83, 0x80]);
    b.setRange(5, 17, List<int>.generate(12, (i) => Random().nextInt(256)));
    return b;
  }
}
