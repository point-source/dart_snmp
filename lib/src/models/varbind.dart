import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:dart_snmp/src/models/oid.dart';

class Varbind<T> {
  Varbind(this.oid, this.type, this.value);

  Varbind.fromBytes(Uint8List bytes) {
    var sequence = ASN1Sequence.fromBytes(bytes);
    assert(sequence.elements[0].tag == OBJECT_IDENTIFIER);
    oid = Oid.fromBytes(sequence.elements[0].encodedBytes);
    type = VarbindType.fromInt(sequence.elements[1].tag);
    value = _decodeValue(sequence.elements[1]) as T;
  }

  Oid oid;
  VarbindType type;
  T value;

  @override
  String toString() => '${oid.identifier} = ${type.name}: $value';

  Uint8List get encodedBytes => asAsn1Sequence.encodedBytes;

  ASN1Sequence get asAsn1Sequence {
    var sequence = ASN1Sequence();
    sequence.add(oid.asAsn1ObjectIdentifier);
    sequence.add(_encodeValue(type, value));
    return sequence;
  }

  ASN1Object _encodeValue(VarbindType type, dynamic value) {
    switch (type) {
      case VarbindType.Boolean:
        return value as bool
            ? ASN1Boolean.ASN1TrueBoolean
            : ASN1Boolean.ASN1FalseBoolean;

      case VarbindType.Integer:
      case VarbindType.Counter:
      case VarbindType.Gauge:
      case VarbindType.TimeTicks:
      case VarbindType.Counter64:
        return ASN1Integer.fromInt(value);

      case VarbindType.OctetString:
        return ASN1OctetString(value);

      case VarbindType.Null:
        return ASN1Null();

      case VarbindType.OID:
        return ASN1ObjectIdentifier.fromComponentString(value);

      case VarbindType.IpAddress:
        throw ASN1IpAddress.fromComponentString(value);

      case VarbindType.Opaque:
        throw Exception('Not implemented');

      case VarbindType.NoSuchObject:
        throw Exception('Not implemented');

      case VarbindType.NoSuchInstance:
        throw Exception('Not implemented');

      case VarbindType.EndOfMibView:
        throw Exception('Not implemented');

      default:
        throw Exception('Unrecognized type');
    }
  }

  dynamic _decodeValue(ASN1Object object) {
    switch (type) {
      case VarbindType.Boolean:
        return value as bool
            ? ASN1Boolean.ASN1TrueBoolean
            : ASN1Boolean.ASN1FalseBoolean;

      case VarbindType.Integer:
      case VarbindType.Counter:
      case VarbindType.Gauge:
      case VarbindType.Counter64:
        return ASN1Integer.fromBytes(object.encodedBytes).intValue;

      case VarbindType.TimeTicks:
        return Duration(
            milliseconds:
                ASN1Integer.fromBytes(object.encodedBytes).intValue * 10);

      case VarbindType.OctetString:
        return (object as ASN1OctetString).stringValue;

      case VarbindType.Null:
        return null;

      case VarbindType.OID:
        return (object as ASN1ObjectIdentifier).identifier;

      case VarbindType.IpAddress:
        return ASN1IpAddress.fromBytes(object.encodedBytes).stringValue;

      case VarbindType.Opaque:
      case VarbindType.NoSuchObject:
      case VarbindType.NoSuchInstance:
      case VarbindType.EndOfMibView:
        return object;

      default:
        throw Exception('Unrecognized type');
    }
  }
}

class VarbindType {
  const VarbindType._internal(this.value);

  VarbindType.fromInt(this.value);

  final int value;

  static const Map<int, String> _snmpTypes = <int, String>{
    1: 'Boolean',
    2: 'Integer',
    4: 'OctetString',
    5: 'Null',
    6: 'OID',
    64: 'IpAddress',
    65: 'Counter32',
    66: 'Gauge32',
    67: 'TimeTicks',
    68: 'Opaque',
    70: 'Counter64',
    128: 'NoSuchObject',
    129: 'NoSuchInstance',
    130: 'EndOfMibView',
  };

  static const Map<int, Type> _dartTypes = <int, Type>{
    1: bool, // Boolean
    2: int, // Integer
    4: String, // OctetString
    5: int, // Null
    6: String, // OID
    64: String, // IpAddress
    65: int, // Counter32
    66: int, // Gauge32
    67: int, // TimeTicks
    68: dynamic, // Opaque
    70: int, // Counter64
    128: int, // NoSuchObject
    129: int, // NoSuchInstance
    130: int, // EndOfMibView
  };

  @override
  String toString() => 'VarbindType.$name ($value)';

  String get name => _snmpTypes[value];

  Type get type => _dartTypes[value];

  static const Boolean = VarbindType._internal(1);
  static const Integer = VarbindType._internal(2);
  static const OctetString = VarbindType._internal(4);
  static const Null = VarbindType._internal(5);
  static const OID = VarbindType._internal(6);
  static const IpAddress = VarbindType._internal(64);
  static const Counter = VarbindType._internal(65);
  static const Gauge = VarbindType._internal(66);
  static const TimeTicks = VarbindType._internal(67);
  static const Opaque = VarbindType._internal(68);
  static const Counter64 = VarbindType._internal(70);
  static const NoSuchObject = VarbindType._internal(128);
  static const NoSuchInstance = VarbindType._internal(129);
  static const EndOfMibView = VarbindType._internal(130);

  @override
  bool operator ==(Object other) =>
      other is VarbindType && (identical(this, other) || value == other.value);
}
