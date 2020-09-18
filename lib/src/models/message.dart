import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:dart_snmp/src/models/pdu.dart';

class Message {
  Message(this.version, this.community, this.pdu);

  Message.fromBytes(Uint8List bytes) {
    var sequence = ASN1Sequence.fromBytes(bytes);
    assert(sequence.tag == 48); // Message tag
    for (var o in sequence.elements) {
      switch (o.tag) {
        case INTEGER_TYPE:
          version = SnmpVersion.fromInt((o as ASN1Integer).intValue);
          break;
        case OCTET_STRING_TYPE:
          community = (o as ASN1OctetString).stringValue;
          break;
        default:
          if (PduType.contains(o.tag)) {
            pdu = Pdu.fromBytes(o.encodedBytes);
          } else {
            throw Exception('No matching snmp type for incoming bytes');
          }
      }
    }
  }

  SnmpVersion version;
  String community;
  Pdu pdu;

  Uint8List get encodedBytes => asAsn1Sequence.encodedBytes;

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

  SnmpVersion.fromInt(this.value);

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
