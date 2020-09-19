import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';

class Oid {
  Oid(this._oid);

  Oid.fromString(String str) {
    str = str.replaceAll(',', '.');
    _oid = ASN1ObjectIdentifier.fromComponentString(str);
  }

  Oid.fromBytes(Uint8List bytes) {
    _oid = ASN1ObjectIdentifier.fromBytes(bytes);
  }

  ASN1ObjectIdentifier _oid;

  ASN1ObjectIdentifier get asAsn1ObjectIdentifier => _oid;

  Uint8List get encodedBytes => _oid.encodedBytes;

  String get identifier => _oid.identifier;

  @override
  String toString() => 'Oid($identifier)';
}
