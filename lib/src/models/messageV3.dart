import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:dart_snmp/src/models/authentication.dart';
import 'package:dart_snmp/src/models/engine.dart';
import 'package:dart_snmp/src/models/message.dart';
import 'package:dart_snmp/src/models/pdu.dart';

class MessageV3 {
  MessageV3(this.engine, this.messageId, this.user, this.pdu,
      {this.maxSize = 65507});

  MessageV3.fromBytes(Uint8List bytes) {
    var sequence = ASN1Sequence.fromBytes(bytes);
    assert(sequence.tag == 48); // Message tag
    for (var o in sequence.elements) {
      switch (o.tag) {
        case INTEGER_TYPE:
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

  /// Determines engineId, engineBoots, engineTime, and maxMessageSize
  Engine engine;

  /// Identifies an SNMPv3 message and matches response messages to request messages
  int messageId;

  /// Security params for User-based security model
  User user;

  /// The maximum size of message that the sender of this message can receive (default is 65507, min is 484)
  int maxSize;

  /// Indicates the security model used for the message. Default is "3" ([User]-based)
  int securityModel = 3;

  /// Parameters necessary to implement the chosen security model
  dynamic securityParams;

  /// A Protocol Data Unit which contains a list of [Varbind]s
  Pdu pdu;

  Uint8List get encodedBytes => asAsn1Sequence.encodedBytes;

  ASN1Sequence get asAsn1Sequence {
    var sequence = ASN1Sequence();
    sequence.add(ASN1Integer.fromInt(SnmpVersion.V3.value));
    sequence.add(ASN1Integer.fromInt(messageId));
    sequence.add(ASN1Integer.fromInt(engine.maxMessageSize));
    sequence.add(ASN1Integer.fromInt(_flags));
    sequence.add(ASN1Integer.fromInt(securityModel));
    sequence.add(ASN1OctetString.fromBytes(engine.engineId));
    sequence.add(ASN1Integer.fromInt(engine.engineBoots));
    sequence.add(ASN1Integer.fromInt(engine.engineTime));
    sequence.add(ASN1OctetString(user.name));
    // TODO(andrew): auth / privacy, etc
    sequence.add(pdu.asAsn1Sequence);
    return sequence;
  }

  /// Controls processing of the message
  ///
  /// Bits 1-5 are reserved
  /// Bit 6 is [_reportable]
  /// Bit 7 is [_private]
  /// Bit 8 is [_authenticated]
  int get _flags => _reportable * 4 | _private * 2 | _authenticated * 1;

  /// Value of "1" requires a receiving device to send back a [PduType.Report] pdu
  int get _reportable =>
      (pdu.type == PduType.GetResponse || pdu.type == PduType.TrapV2) ? 0 : 1;

  /// Value of "1" indicates privacy (encryption) is enabled. Can only be used if authentication is enabled
  int get _private => user.level == SecurityLevel.authPriv ? 1 : 0;

  /// Value of "1" indicates authentication is enabled in [SecurityLevel]
  int get _authenticated => user.level != SecurityLevel.authNoPriv ? 1 : 0;
}
