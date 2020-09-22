import 'dart:io';

import 'package:dart_snmp/src/models/message.dart';

class Request {
  Request(this.target, this.port, this.message, this.timeout, this.retries,
      this.onResponse, this.onError);

  final InternetAddress target;
  final int port;
  final Message message;
  final Duration timeout;
  final void Function(Message) onResponse;
  final void Function(Exception) onError;
  int retries;

  int get requestId => message.pdu.requestId;

  set requestId(int id) => message.pdu.requestId = id;

  void complete(Message msg) {
    if (msg.pdu.error.value > 0) {
      completeError(Exception(
          'Snmp Pdu Error on ${message.pdu.varbinds[0].oid.identifier}: ${msg.pdu.error.name}'));
    }
    onResponse(msg);
  }

  void completeError(Exception error) => onError(error);

  @override
  String toString() =>
      '${message.pdu.type.name} @ ${target.address}:$port / ${message.pdu.varbinds[0].oid.identifier}';
}
