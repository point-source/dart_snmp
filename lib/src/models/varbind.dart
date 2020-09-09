import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:dart_snmp/src/models/oid.dart';

class Varbind {
  Oid oid;
  VarbindType type;
  dynamic value;

  Uint8List toBytes() {
    var sequence = ASN1Sequence();
    sequence.add(oid.asAsn1Object);
    sequence.add(_encode(type, value));
    return sequence.valueBytes();
  }

  ASN1Object _encode(VarbindType type, dynamic value) {
    switch (type) {
      case VarbindType.Boolean:
        return value as bool
            ? ASN1Boolean.ASN1TrueBoolean
            : ASN1Boolean.ASN1FalseBoolean;
      case VarbindType.Integer:
        return ASN1Integer.fromInt(value);
      case VarbindType.OctetString:
        return ASN1OctetString.fromBytes(value);
      case VarbindType.Null:
        return ASN1Null.fromBytes(value);
      case VarbindType.OID:
        return ASN1Integer.fromInt(value);
      case VarbindType.IpAddress:
        throw Exception('Not implemented');
      case VarbindType.Counter:
        return ASN1Integer.fromInt(value, tag: type.value);
      case VarbindType.Gauge:
        return ASN1Integer.fromInt(value, tag: type.value);
      case VarbindType.TimeTicks:
        return ASN1Integer.fromInt(value, tag: type.value);
      case VarbindType.Opaque:
        throw Exception('Not implemented');
      case VarbindType.Counter64:
        return ASN1Integer.fromInt(value, tag: type.value);
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
}

class VarbindType {
  const VarbindType._internal(this.value);

  final int value;

  static const Map<int, String> _types = <int, String>{
    1: 'Boolean',
    2: 'Integer',
    4: 'OctetString',
    5: 'Null',
    6: 'OID',
    64: 'IpAddress',
    65: 'Counter',
    66: 'Gauge',
    67: 'TimeTicks',
    68: 'Opaque',
    70: 'Counter64',
    128: 'NoSuchObject',
    129: 'NoSuchInstance',
    130: 'EndOfMibView'
  };

  @override
  String toString() => 'VarbindType.$name ($value)';

  String get name => _types[value];

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
}
