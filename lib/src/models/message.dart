import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:dart_snmp/src/models/pdu.dart';

/// An SNMP v1 or v2c Message which contains the credential information
/// necessary to package a [Pdu] to be sent to a target device
class Message {
  Message(this.version, this.community, this.pdu);

  /// Parses a list of bytes into a Message object
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

  /// Describes the SNMP version number of this message
  SnmpVersion version;

  /// A user-defined string used to provide a basic level of "security" between devices
  String community;

  /// A Protocol Data Unit which contains a list of [Varbind]s
  Pdu pdu;

  /// Converts the Message to a (transmittable) list of bytes
  Uint8List get encodedBytes => asAsn1Sequence.encodedBytes;

  /// Converts the Message to an [ASN1Sequence] object
  ASN1Sequence get asAsn1Sequence {
    var sequence = ASN1Sequence();
    sequence.add(ASN1Integer.fromInt(version.value));
    sequence.add(ASN1OctetString(community));
    sequence.add(pdu.asAsn1Sequence);
    return sequence;
  }
}

/// The version of the snmp protocol to use
class SnmpVersion {
  const SnmpVersion._internal(this.value);

  SnmpVersion.fromInt(this.value);

  final int value;

  static const Map<int, String> _versions = <int, String>{
    0: 'v1',
    1: 'v2c',
    3: 'v3',
  };

  @override
  String toString() => 'SnmpVersion.$name ($value)';

  String get name => _versions[value];

  static const V1 = SnmpVersion._internal(0);
  static const V2c = SnmpVersion._internal(1);
  static const V3 = SnmpVersion._internal(3);
}
