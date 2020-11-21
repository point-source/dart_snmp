import 'dart:io';
import 'package:dart_snmp/dart_snmp.dart';

void main() async {
  var target = InternetAddress('192.168.1.1');
  var session = await Snmp.createSession(target);
  var oid = Oid.fromString('1.3.6.1.2.1.1.1.0'); // sysDesc
  var message = await session.get(oid);
  print(message.pdu.varbinds[0]); // outputs system description
}
