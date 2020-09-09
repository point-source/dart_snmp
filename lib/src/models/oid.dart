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

  ASN1ObjectIdentifier get asAsn1Object => _oid;

  @override
  String toString() => _oid.oi.join('.');

  Uint8List toBytes() => _oid.valueBytes();
}
