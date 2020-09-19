// TODO: Put public facing types in this file.

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dart_snmp/src/models/authentication.dart';
import 'package:dart_snmp/src/models/message.dart';
import 'package:dart_snmp/src/models/oid.dart';
import 'package:dart_snmp/src/models/pdu.dart';
import 'package:dart_snmp/src/models/request.dart';
import 'package:dart_snmp/src/models/varbind.dart';

class Snmp {
  Snmp(this.target, this.port, this.trapPort, this.retries, this.timeout,
      this.version,
      {this.community, this.user}) {
    assert(community != null || user != null);
  }

  static Future<Snmp> createSession(InternetAddress target,
      {String community = 'public',
      int port = 161,
      int trapPort = 162,
      int retries = 1,
      Duration timeout = const Duration(seconds: 5),
      SnmpVersion version = SnmpVersion.V2c}) async {
    assert(version != SnmpVersion.V3);
    var session = Snmp(target, port, trapPort, retries, timeout, version,
        community: community);
    await session._bind(InternetAddress.anyIPv4, port);
    return session;
  }

  static Future<Snmp> createV3Session(InternetAddress target, User user,
      {int port = 161,
      int trapPort = 162,
      int retries = 1,
      Duration timeout = const Duration(seconds: 5)}) async {
    var session = Snmp(target, port, trapPort, retries, timeout, SnmpVersion.V3,
        user: user);
    await session._bind(InternetAddress.anyIPv4, port);
    return session;
  }

  InternetAddress target;
  int port;
  int trapPort;
  User user;
  String community;
  int retries = 1;
  Duration timeout = Duration(seconds: 5);
  SnmpVersion version = SnmpVersion.V2c;
  RawDatagramSocket socket;
  Map<int, Request> requests = {};

  Future<void> _bind(InternetAddress address, int port) async {
    socket = await RawDatagramSocket.bind(address, port);
    socket.listen(_onEvent, onError: _onError, onDone: _onClose);
  }

  void close() {
    socket.close();
  }

  void _onEvent(RawSocketEvent event) {
    // TODO(andrew): Handle event message
    var d = socket.receive();
    if (d == null) return;

    var msg = Message.fromBytes(d.data);
    if (requests.containsKey(msg.pdu.requestId)) {
      requests[msg.pdu.requestId].complete(msg);
    }
/*     print(
        'Datagram from ${d.address.address}:${d.port}: ${msg.pdu.varbinds[0].value}'); */
  }

  void _onClose() {
    // TODO(andrew): Handle closing
    _cancelRequests(Exception('Socket forcibly closed. HANDLE ME'));
  }

  void _onError(Object error) {
    // TODO(andrew): Handle emitting the error
    throw error;
  }

  void _cancelRequests(Exception error) {
    // TODO(andrew): DO something
    // Is this needed?
    throw error;
  }

  void _cancelRequest(int requestId) => requests.remove(requestId);

  int _generateId(int bitSize) => bitSize == 16
      ? (Random().nextInt(10000) % 65535).floor()
      : (Random().nextInt(100000000) % 4294967295).floor();

  Future<Message> get(Oid oid) => _get(oid, PduType.GetRequest);

  Future<Message> getNext(Oid oid) => _get(oid, PduType.GetNextRequest);

  Stream<Message> walk() async* {
    var oid = Oid.fromString('1.3');
    while (true) {
      var msg = await getNext(oid);
      oid = msg.pdu.varbinds.last.oid;
      if (msg.pdu.error == PduError.NoSuchName) {
        close();
      } else {
        yield msg;
      }
    }
  }

  Future<Message> _get(Oid oid, PduType type) {
    var c = Completer<Message>();
    var v = Varbind<String>(oid, VarbindType.Null, null);
    var p = Pdu(type, _generateId(16), [v]);
    while (requests.containsKey(p.requestId)) {
      p.requestId = _generateId(16);
    }
    var m = Message(version, community, p);
    var r = Request(target, port, m, timeout, retries, c.complete,
        c.completeError, _cancelRequest);
    _send(r);
    return c.future;
  }

  void _send(Request r) {
    socket.send(r.message.encodedBytes, r.target, r.port);
    requests[r.requestId] = r;
  }
}
