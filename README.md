An snmp library for Dart developers.

Created from templates made available by Stagehand under a BSD-style
[license](https://github.com/dart-lang/stagehand/blob/master/LICENSE).

## Usage

A simple usage example:

```dart
import 'dart:io';
import 'package:dart_snmp/dart_snmp.dart';

void main() async {
  var target = InternetAddress('192.168.1.1');
  var session = await Snmp.createSession(target);
  var oid = Oid.fromString('1.3.6.1.2.1.1.1.0'); // sysDesc
  var message = await session.get(oid);
  print(message.pdu.varbinds[0]); // outputs system description
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/point-source/dart_snmp/issues
