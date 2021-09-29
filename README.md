An snmp library for Dart developers.

## Usage

A simple usage example:

```dart
import 'dart:io';
import 'package:dart_snmp/dart_snmp.dart';
import 'package:dart_snmp/src/models/varbind.dart';

void main() async {
  // Starting a session
  var target = InternetAddress('192.168.1.1');
  var session = await Snmp.createSession(target);

  // Reading a parameter
  var oid = Oid.fromString('1.3.6.1.2.1.1.1.0'); // sysDesc
  var message = await session.get(oid);
  print(message.pdu.varbinds[0]); // outputs system description

  // Writing a parameter
  var varbind = Varbind(
    oid,
    VarbindType.OctetString,
    'New system description',
  ); // create payload
  await session.set(varbind); // send new system description to target
}

```

## Features and bugs

#### TODO

- [x] Implement SNMP v1 / v2c
- [ ] Implement SNMP v3

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/point-source/dart_snmp/issues
