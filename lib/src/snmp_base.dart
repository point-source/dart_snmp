// TODO: Put public facing types in this file.

import 'dart:io';
import 'dart:math';

import 'package:dart_snmp/src/models.dart';

enum SnmpVersion { v1, v2c, v3 }

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
      SnmpVersion version = SnmpVersion.v1}) async {
    assert(version != SnmpVersion.v3);
    var session = Snmp(target, port, trapPort, retries, timeout, version,
        community: community);
    await session._bind(InternetAddress.anyIPv4, port);
    return session;
  }

  static Future<Snmp> createv3Session(InternetAddress target, User user,
      {int port = 161,
      int trapPort = 162,
      int retries = 1,
      Duration timeout = const Duration(seconds: 5)}) async {
    var session = Snmp(target, port, trapPort, retries, timeout, SnmpVersion.v3,
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
  SnmpVersion version = SnmpVersion.v1;
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
  }

  void _onClose() {
    // TODO(andrew): Handle closing
    _cancelRequests(Exception("Socket forcibly closed"));
  }

  void _onError(Exception error) {
    // TODO(andrew): Handle emitting the error
  }

  void _cancelRequests(Exception error) {
    // TODO(andrew): DO something
    // Is this needed?
    throw 
  }

  int _generateId(int bitSize) => bitSize == 16
      ? (Random().nextInt(10000) % 65535).floor()
      : (Random().nextInt(100000000) % 4294967295).floor();
}
