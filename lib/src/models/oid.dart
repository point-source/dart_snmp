import 'package:asn1lib/asn1lib.dart';

class Oid {
  Oid(this._oid);

  Oid.fromString(String str) {
    str = str.replaceAll(',', '.');
    _oid = ASN1ObjectIdentifier.fromComponentString(str);
  }

  ASN1ObjectIdentifier _oid;

  ASN1ObjectIdentifier get asAsn1ObjectIdentifier => _oid;

  @override
  String toString() => _oid.oi.join('.');
}
