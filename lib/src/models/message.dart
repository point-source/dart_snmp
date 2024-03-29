import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:dart_snmp/src/models/pdu.dart';

/// An SNMP v1 or v2c Message which contains the credential information
/// necessary to package a [Pdu] to be sent to a target device
class Message {
  /// An SNMP v1 or v2c Message which contains the credential information
  /// necessary to package a [Pdu] to be sent to a target device
  Message(this.version, this.community, this.pdu);

  /// Parses a list of bytes into a Message object
  static Message fromBytes(Uint8List bytes) {
    var sequence = ASN1Sequence.fromBytes(bytes);
    SnmpVersion? version;
    String? community;
    Pdu? pdu;
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
    if (version == null || community == null || pdu == null) {
      throw Exception('Could not parse incoming sequence into Message object');
    }

    return Message(version, community, pdu);
  }

  /// The SNMP protocol version used to encode/decode this message
  SnmpVersion version;

  /// An arbitrary user-defined string used to provide separation between
  /// multiple snmp configurations/deployments
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

  /// Returns the corresponding [SnmpVersion] matched to a given integer value
  /// for encoding/decoding
  SnmpVersion.fromInt(this.value);

  /// Integer representation of the SNMP version
  final int value;

  static const Map<int, String> _versions = <int, String>{
    0: 'v1',
    1: 'v2c',
    3: 'v3',
  };

  @override
  String toString() => 'SnmpVersion.$name ($value)';

  /// Human-friendly snmp version name
  String get name => _versions[value] ?? 'Unknown';

  /// Version 1
  static const v1 = SnmpVersion._internal(0);

  /// Version 2c
  static const v2c = SnmpVersion._internal(1);

  /// Version 3
  static const v3 = SnmpVersion._internal(3);
}
