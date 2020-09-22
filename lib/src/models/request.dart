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
  final void Function(String) onError;
  int retries;

  int get requestId => message.pdu.requestId;

  set requestId(int id) => message.pdu.requestId = id;

  void complete(dynamic response) => onResponse(response);

  void error(dynamic error) => onError(error);
}
