import 'dart:io';

import 'package:dart_snmp/src/models/message.dart';

/// An SNMP Request which will be sent to a [target] address
///
/// This request contains an SNMP [Message] with one or more
/// [Varbind]s encapsulated within a [Pdu]
class Request {
  Request(this.target, this.port, this.message, this.timeout, this.retries,
      this.onResponse, this.onError);

  /// The address of the target device where this request will be sent
  final InternetAddress target;

  /// The port on the target device where this request will be sent
  final int port;

  /// The [Message] to be encoded and sent
  final Message message;

  /// The length of time before the request is considered unresolved / failed
  final Duration timeout;

  /// A callback to send any response received from the [target] device
  final void Function(Message) onResponse;

  /// A callback to handle an error received from the [target] device
  final void Function(Exception) onError;

  /// The number of times to retry the request before considering it failed
  int retries;

  /// The unique identifier for this request
  int get requestId => message.pdu.requestId;

  set requestId(int id) => message.pdu.requestId = id;

  /// Completes this request by handling an incoming [Message]
  void complete(Message msg) {
    if (msg.pdu.error.value > 0) {
      completeError(Exception(
          'Snmp Pdu Error on ${message.pdu.varbinds[0].oid.identifier}: ${msg.pdu.error.name}'));
    } else {
      onResponse(msg);
    }
  }

  /// Completes this request by returning an error to the [onError] callback function
  void completeError(Exception error) => onError(error);

  @override
  String toString() =>
      '${message.pdu.type.name} @ ${target.address}:$port / ${message.pdu.varbinds[0].oid.identifier}';
}
