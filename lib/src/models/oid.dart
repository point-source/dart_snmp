import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';

/// An Object Identifier which corresponds to a specific value or
/// parameter on a target device
class Oid {
  Oid(this._oid);

  /// Parses a period or comma delimited string of octets into an Oid object
  Oid.fromString(String str) {
    str = str.replaceAll(',', '.');
    _oid = ASN1ObjectIdentifier.fromComponentString(str);
  }

  /// Parses a list of bytes into a Oid object
  Oid.fromBytes(Uint8List bytes) {
    _oid = ASN1ObjectIdentifier.fromBytes(bytes);
  }

  ASN1ObjectIdentifier _oid;

  ASN1ObjectIdentifier get asAsn1ObjectIdentifier => _oid;

  /// Converts an Oid object into a (transmittable) list of bytes
  Uint8List get encodedBytes => _oid.encodedBytes;

  /// Provides a period-delimited string of Oid octets
  String get identifier => _oid.identifier;

  @override
  String toString() => 'Oid($identifier)';
}
