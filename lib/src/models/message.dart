import 'package:asn1lib/asn1lib.dart';
import 'package:dart_snmp/src/models/pdu.dart';

class Message {
  Message(this.version, this.community, this.pdu);

  SnmpVersion version;
  String community;
  Pdu pdu;

  ASN1Sequence get asAsn1Sequence {
    var sequence = ASN1Sequence();
    sequence.add(ASN1Integer.fromInt(version.value));
    sequence.add(ASN1OctetString(community));
    sequence.add(pdu.asAsn1Sequence);
    return sequence;
  }
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
