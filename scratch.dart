import 'dart:typed_data';

import 'package:dart_snmp/dart_snmp.dart';

void main() {
  var o = Oid.fromString('1.3.6.1.4.1.2680.1.2.7.3.2');
  print(o.encodedBytes);
  var v = Varbind<Uint8List>(o, VarbindType.Null, Uint8List.fromList([0]));
  print(v.encodedBytes);
  var p = Pdu(PduType.GetRequest, 1, [v]);
  print(p.encodedBytes);
  var m = Message(SnmpVersion.V1, 'private', p);
  print(m.encodedBytes);
  var d = Message.fromBytes(m.encodedBytes);
  print(d.encodedBytes);
}
