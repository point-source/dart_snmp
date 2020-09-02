// TODO: Put public facing types in this file.

import 'dart:io';

import 'package:dart_snmp/src/models.dart';

enum SnmpVersion { v1, v2c, v3 }

class Snmp {
  Snmp(this.target, this.port, this.trapPort, this.retries, this.timeout,
      this.transport, this.version,
      {this.community, this.user}) {
    assert(community != null || user != null);
  }

  static Future<Snmp> createSession(InternetAddress target,
      {String community = 'public',
      int port = 161,
      int trapPort = 162,
      int retries = 1,
      Duration timeout = const Duration(seconds: 5),
      String transport = 'udp4',
      SnmpVersion version = SnmpVersion.v1}) async {
    assert(version != SnmpVersion.v3);
    var session = Snmp(
        target, port, trapPort, retries, timeout, transport, version,
        community: community);
    await session._bind(InternetAddress.anyIPv4, port);
    return session;
  }

  static Future<Snmp> create3Session(InternetAddress target, User user,
      {int port = 161,
      int trapPort = 162,
      int retries = 1,
      Duration timeout = const Duration(seconds: 5),
      String transport = 'udp4'}) async {
    var session = Snmp(
        target, port, trapPort, retries, timeout, transport, SnmpVersion.v3,
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
  String transport = 'udp4';
  SnmpVersion version = SnmpVersion.v1;
  RawDatagramSocket socket;

  Future<void> _bind(InternetAddress address, int port) async =>
      socket = await RawDatagramSocket.bind(address, port);

  void close() {
    socket.close();
  }
}
