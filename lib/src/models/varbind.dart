// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:dart_snmp/dart_snmp.dart';
import 'package:dart_snmp/src/models/oid.dart';

/// An SNMP Variable Binding which holds an [Oid] (Object Identifier),
/// a [tag] which specifies the data type, and a data value to be read or written
class Varbind {
  /// An SNMP Variable Binding which holds an [Oid] (Object Identifier),
  /// a [tag] which specifies the data type, and a data value to be read or written
  Varbind(this.oid, VarbindType type, this.value) : tag = type.value;

  /// Parses a list of bytes into a Varbind object
  Varbind.fromBytes(Uint8List bytes) {
    var sequence = ASN1Sequence.fromBytes(bytes);
    assert(sequence.elements[0].tag == OBJECT_IDENTIFIER);
    oid = Oid.fromBytes(sequence.elements[0].encodedBytes);
    tag = sequence.elements[1].tag;
    value = _decodeValue(sequence.elements[1]);
  }

  /// An Object Identifier [Oid] for which this varbind contains a value
  late Oid oid;

  /// A number which indicates the type of data contained in this varbind
  ///
  /// See [VarbindType]
  late int tag;

  /// The data which has been read or is to be written to the [Oid] on the target device
  dynamic value;

  @override
  String toString() => '${oid.identifier} = $_typeName: $value';

  String get _typeName => VarbindType.typeNames[tag] ?? 'Unknown';

  /// Converts the Varbind to a (transmittable) list of bytes
  Uint8List get encodedBytes => asAsn1Sequence.encodedBytes;

  /// Converts the Varbind to an ASN1Sequence object
  ASN1Sequence get asAsn1Sequence {
    var sequence = ASN1Sequence();
    sequence.add(oid.asAsn1ObjectIdentifier);
    sequence.add(_encodeValue(tag, value));

    return sequence;
  }

  ASN1Object _encodeValue(int tag, dynamic value) {
    switch (tag) {
      case BOOLEAN:
        return value as bool
            ? ASN1Boolean.ASN1TrueBoolean
            : ASN1Boolean.ASN1FalseBoolean;

      case INTEGER:
      case COUNTER:
      case GAUGE:
      case COUNTER_64:
        return ASN1Integer.fromInt(value, tag: tag);
      case TIME_TICKS:
        if (value is Duration) {
          return ASN1Integer.fromInt(value.inMilliseconds ~/ 10);
        }
        return ASN1Integer.fromInt(value);

      case OCTET_STRING:
        return ASN1OctetString(value);

      case NULL:
        return ASN1Null();

      case OID:
        return ASN1ObjectIdentifier.fromComponentString(value);

      case IP_ADDRESS:
        if (value is InternetAddress) {
          return ASN1IpAddress.fromComponentString(value.address);
        }
        return ASN1IpAddress.fromComponentString(value);

      case OPAQUE:
        throw Exception('Opaque type not yet implemented');

      case NO_SUCH_OBJECT:
        throw Exception('NoSuchObject type not yet implemented');

      case NO_SUCH_INSTANCE:
        throw Exception('NoSuchInstance type not yet implemented');

      case END_OF_MIB_VIEW:
        throw Exception('EndOfMibView not yet implemented');

      default:
        throw Exception('Unrecognized type');
    }
  }

  dynamic _decodeValue(ASN1Object object) {
    switch (tag) {
      case BOOLEAN:
        return (object as ASN1Boolean).booleanValue;

      case INTEGER:
      case COUNTER:
      case GAUGE:
      case COUNTER_64:
        return ASN1Integer.fromBytes(object.encodedBytes).intValue;

      case TIME_TICKS:
        return Duration(
          milliseconds:
              ASN1Integer.fromBytes(object.encodedBytes).intValue * 10,
        );

      case OCTET_STRING:
        if (object.valueBytes().any((e) => e > 127)) {
          // Not Ascii
          return base64Encode(object.valueBytes());
        }
        return (object as ASN1OctetString).stringValue;

      case NULL:
        return null;

      case OID:
        return (object as ASN1ObjectIdentifier).identifier;

      case IP_ADDRESS:
        return ASN1IpAddress.fromBytes(object.encodedBytes).stringValue;

      case OPAQUE:
        return object.valueBytes();

      case NO_SUCH_OBJECT:
      case NO_SUCH_INSTANCE:
      case END_OF_MIB_VIEW:
        return object;

      default:
        throw Exception('Unrecognized type');
    }
  }
}

/// The type of data contained within the Varbind
class VarbindType {
  /// Returns a [VarbindType] corresponding to the provided integer value
  /// from a decoded Varbind
  const VarbindType.fromInt(this.value);

  /// Integer representation of the Varbind type
  final int value;

  /// Map of Varbind type integer values to human-readable names
  static const Map<int, String> typeNames = <int, String>{
    BOOLEAN: 'Boolean',
    INTEGER: 'Integer',
    OCTET_STRING: 'OctetString',
    NULL: 'Null',
    OID: 'OID',
    IP_ADDRESS: 'IpAddress',
    COUNTER: 'Counter32',
    GAUGE: 'Gauge32',
    TIME_TICKS: 'TimeTicks',
    OPAQUE: 'Opaque',
    COUNTER_64: 'Counter64',
    NO_SUCH_OBJECT: 'NoSuchObject',
    NO_SUCH_INSTANCE: 'NoSuchInstance',
    END_OF_MIB_VIEW: 'EndOfMibView',
  };

  @override
  String toString() => 'VarbindType.$name ($value)';

  /// Human-readable name of the Varbind type
  String get name => typeNames[value] ?? 'Unknown';

  /// A true or false value
  static const boolean = VarbindType.fromInt(BOOLEAN);

  /// A value whose range may include both positive and negative numbers
  static const integer = VarbindType.fromInt(INTEGER);

  /// Used to specify octets of binary or textual information.
  ///
  /// While SMIv1 doesn't limit the number of octets, SMIv2 specifies a limit of
  /// 65535 octets. A size may be specified which can be fixed,
  /// varying, or multiple ranges.
  static const octetString = VarbindType.fromInt(OCTET_STRING);

  /// Typically used as a placeholder when the value is not known.
  ///
  /// For example, when performing a GET request where you need to provide
  /// a varbind type but do not have any value to send since you are
  /// intending to retrieve a value instead.
  static const nullValue = VarbindType.fromInt(NULL);

  /// Used to identify a type that has an assigned object identifier value
  static const oid = VarbindType.fromInt(OID);

  /// This type is used to specify an IPv4 address as a string of 4 octets
  static const ipAddress = VarbindType.fromInt(IP_ADDRESS);

  /// Used to specify a value which represents a count.
  ///
  /// The range is 0 to 4,294,967,295.
  static const counter = VarbindType.fromInt(COUNTER);

  /// A non-negative integer which may increase or decrease,
  /// but which holds at the maximum or minimum value specified in the
  /// range when the actual value goes over or below the range, respectively
  static const gauge = VarbindType.fromInt(GAUGE);

  /// Used to specify the elapsed time between two events,
  /// in units of hundredth of a second. Range is 0 to 2e32 - 1.
  static const timeTicks = VarbindType.fromInt(TIME_TICKS);

  /// Used to specify octets of binary information.
  ///
  /// SMIv2 specifies a limit of 65535 octets while there is no limit in SMIv1.
  /// A size may be specified which can be fixed, varying, or multiple ranges.
  ///
  /// A value of this type must be an encapsulation of ASN.1 BER encoded value.
  static const opaque = VarbindType.fromInt(OPAQUE);

  /// Similar to Counter32, except the range is now (0 to 2e64  -1).
  ///
  /// This type may only be used when a 32-bit counter rollover could occur in
  /// less than an hour. Otherwise, the Counter32 type must be used.
  ///
  ///  Since this type is not available in SNMPv1, it may only be used when
  /// backwards compatibility is not a requirement.
  static const counter64 = VarbindType.fromInt(COUNTER_64);

  /// NoSuchObject is returned by the agent in response to a
  /// request when the requested object does not exist in its MIB. (SNMP v2)
  ///
  /// This value is returned as a with data of length 0
  static const noSuchObject = VarbindType.fromInt(NO_SUCH_OBJECT);

  /// The requested instance of the object does not exist (SNMP v2)
  ///
  /// For example: requesting data from port 9 of an 8-port switch
  static const noSuchInstance = VarbindType.fromInt(NO_SUCH_INSTANCE);

  /// Signifies the end of an SNMP "walk" or "get-next" (SNMP v2)
  static const endOfMibView = VarbindType.fromInt(END_OF_MIB_VIEW);
}

/// A true or false value
const BOOLEAN = 1;

/// A value whose range may include both positive and negative numbers
const INTEGER = 2;

/// Used to specify octets of binary or textual information.
///
/// While SMIv1 doesn't limit the number of octets, SMIv2 specifies a limit of
/// 65535 octets. A size may be specified which can be fixed,
/// varying, or multiple ranges.
const OCTET_STRING = 4;

/// Typically used as a placeholder when the value is not known.
///
/// For example, when performing a GET request where you need to provide
/// a varbind type but do not have any value to send since you are
/// intending to retrieve a value instead.
const NULL = 5;

/// Used to identify a type that has an assigned object identifier value
const OID = 6;

/// This type is used to specify an IPv4 address as a string of 4 octets
const IP_ADDRESS = 64;

/// Used to specify a value which represents a count.
///
/// The range is 0 to 4,294,967,295.
const COUNTER = 65;

/// A non-negative integer which may increase or decrease,
/// but which holds at the maximum or minimum value specified in the
/// range when the actual value goes over or below the range, respectively
const GAUGE = 66;

/// Used to specify the elapsed time between two events,
/// in units of hundredth of a second. Range is 0 to 2e32 - 1.
const TIME_TICKS = 67;

/// Used to specify octets of binary information.
///
/// SMIv2 specifies a limit of 65535 octets while there is no limit in SMIv1.
/// A size may be specified which can be fixed, varying, or multiple ranges.
///
/// A value of this type must be an encapsulation of ASN.1 BER encoded value.
const OPAQUE = 68;

/// Similar to Counter32, except the range is now (0 to 2e64  -1).
///
/// This type may only be used when a 32-bit counter rollover could occur in
/// less than an hour. Otherwise, the Counter32 type must be used.
///
///  Since this type is not available in SNMPv1, it may only be used when
/// backwards compatibility is not a requirement.
const COUNTER_64 = 70;

/// NoSuchObject is returned by the agent in response to a
/// request when the requested object does not exist in its MIB. (SNMP v2)
///
/// This value is returned as a with data of length 0
const NO_SUCH_OBJECT = 128;

/// The requested instance of the object does not exist (SNMP v2)
///
/// For example: requesting data from port 9 of an 8-port switch
const NO_SUCH_INSTANCE = 129;

/// Signifies the end of an SNMP "walk" or "get-next" (SNMP v2)
const END_OF_MIB_VIEW = 130;
