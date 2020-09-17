// TODO: Put public facing types in this file.

import 'dart:io';
import 'dart:math';

import 'package:dart_snmp/src/models/authentication.dart';
import 'package:dart_snmp/src/models/message.dart';
import 'package:dart_snmp/src/models/oid.dart';
import 'package:dart_snmp/src/models/pdu.dart';
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
      SnmpVersion version = SnmpVersion.V1}) async {
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
    print(
        'Datagram from ${d.address.address}:${d.port}: ${msg.pdu.varbinds[0].value}');
  }

  void _onClose() {
    // TODO(andrew): Handle closing
    _cancelRequests(Exception('Socket forcibly closed'));
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

  int _generateId(int bitSize) => bitSize == 16
      ? (Random().nextInt(10000) % 65535).floor()
      : (Random().nextInt(100000000) % 4294967295).floor();

  void get(List<Oid> oids) {}

  int send(List<Varbind> v) {
    var pdu = Pdu(PduType.GetRequest, 1, v);
    var msg = Message(version, community, pdu);
    return socket.send(msg.encodedBytes, target, port);
  }
}
