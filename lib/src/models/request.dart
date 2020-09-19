import 'dart:io';

import 'package:dart_snmp/src/models/message.dart';
import 'package:dart_snmp/src/models/pdu.dart';

class Request {
  Request(this.target, this.port, this.message, this.timeout, this.retries,
      this.onResponse, this.onError, this.onCancel) {
    Future<void>.delayed(timeout, _timeout);
  }

  final InternetAddress target;
  final int port;
  final Message message;
  final Duration timeout;
  final void Function(Message) onResponse;
  final void Function(int) onCancel;
  final void Function(String) onError;
  int retries;

  int get requestId => message.pdu.requestId;

  set requestId(int id) => message.pdu.requestId = id;

  void _timeout() {
    if (retries > 0) {
      retries--;
      Future.delayed(timeout);
    } else {
      onCancel(requestId);
    }
  }

  void complete(dynamic response) => onResponse(response);

  void error(dynamic error) => onError(error);

  void cancel() => onCancel(requestId);
}
