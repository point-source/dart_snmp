import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:dart_snmp/dart_snmp.dart';
import 'package:dart_snmp/src/models/oid.dart';

/// An SNMP Variable Binding which holds an [Oid] (Object Identifier),
/// a [tag] which specifies the data type, and a data value to be read or written
class Varbind {
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
                ASN1Integer.fromBytes(object.encodedBytes).intValue * 10);

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

class VarbindType {
  const VarbindType.fromInt(this.value);

  final int value;

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

  String get name => typeNames[value] ?? 'Unknown';

  static const Boolean = VarbindType.fromInt(BOOLEAN);
  static const Integer = VarbindType.fromInt(INTEGER);
  static const OctetString = VarbindType.fromInt(OCTET_STRING);
  static const Null = VarbindType.fromInt(NULL);
  static const Oid = VarbindType.fromInt(OID);
  static const IpAddress = VarbindType.fromInt(IP_ADDRESS);
  static const Counter = VarbindType.fromInt(COUNTER);
  static const Gauge = VarbindType.fromInt(GAUGE);
  static const TimeTicks = VarbindType.fromInt(TIME_TICKS);
  static const Opaque = VarbindType.fromInt(OPAQUE);
  static const Counter64 = VarbindType.fromInt(COUNTER_64);
  static const NoSuchObject = VarbindType.fromInt(NO_SUCH_OBJECT);
  static const NoSuchInstance = VarbindType.fromInt(NO_SUCH_INSTANCE);
  static const EndOfMibView = VarbindType.fromInt(END_OF_MIB_VIEW);
}

const BOOLEAN = 1;
const INTEGER = 2;
const OCTET_STRING = 4;
const NULL = 5;
const OID = 6;
const IP_ADDRESS = 64;
const COUNTER = 65;
const GAUGE = 66;
const TIME_TICKS = 67;
const OPAQUE = 68;
const COUNTER_64 = 70;
const NO_SUCH_OBJECT = 128;
const NO_SUCH_INSTANCE = 129;
const END_OF_MIB_VIEW = 130;
