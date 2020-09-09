class Message {
  Message();

  SnmpVersion version;
  String community;
}

class SnmpVersion {
  const SnmpVersion._internal(this.value);

  final int value;

  static const Map<int, String> _versions = <int, String>{
    0: 'v1c',
    1: 'v2',
    3: 'v3',
  };

  @override
  String toString() => 'SnmpVersion.$name ($value)';

  String get name => _versions[value];

  static const V1 = SnmpVersion._internal(0);
  static const V2c = SnmpVersion._internal(1);
  static const V3 = SnmpVersion._internal(3);
}
