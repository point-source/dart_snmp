import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dart_snmp/src/models/authentication.dart';
import 'package:dart_snmp/src/models/message.dart';
import 'package:dart_snmp/src/models/oid.dart';
import 'package:dart_snmp/src/models/pdu.dart';
import 'package:dart_snmp/src/models/request.dart';
import 'package:dart_snmp/src/models/varbind.dart';
import 'package:logging/logging.dart' as logging;

final log = logging.Logger('Snmp');

class Snmp {
  Snmp(this.target, this.port, this.trapPort, this.retries, this.timeout,
      this.version,
      {this.community,
      this.user,
      logging.Level logLevel = logging.Level.INFO}) {
    _logging(logLevel);
    assert(community != null || user != null);
    log.info('Snmp ${version.name} session initialized.');
  }

  static Future<Snmp> createSession(InternetAddress target,
      {String community = 'public',
      int port = 161,
      int trapPort = 162,
      int retries = 1,
      Duration timeout = const Duration(seconds: 5),
      SnmpVersion version = SnmpVersion.V2c,
      InternetAddress sourceAddress,
      int sourcePort,
      logging.Level logLevel}) async {
    assert(version != SnmpVersion.V3);
    var session = Snmp(target, port, trapPort, retries, timeout, version,
        community: community, logLevel: logLevel);
    await session._bind(address: sourceAddress, port: sourcePort);
    return session;
  }

  static Future<Snmp> createV3Session(InternetAddress target, User user,
      {int port = 161,
      int trapPort = 162,
      int retries = 1,
      Duration timeout = const Duration(seconds: 5),
      InternetAddress sourceAddress,
      int sourcePort,
      logging.Level logLevel}) async {
    var session = Snmp(target, port, trapPort, retries, timeout, SnmpVersion.V3,
        user: user, logLevel: logLevel);
    await session._bind(address: sourceAddress, port: sourcePort);
    return session;
  }

  InternetAddress target;
  int port;
  int trapPort;
  User user;
  String community;
  int retries;
  Duration timeout;
  SnmpVersion version;
  InternetAddress sourceAddress;
  int sourcePort;
  RawDatagramSocket socket;
  Map<int, Request> requests = {};

  void _logging(logging.Level level) {
    logging.hierarchicalLoggingEnabled = true;
    log.level = level;
    log.onRecord
        .listen((r) => print('${r.level.name}: ${r.time}: ${r.message}'));
  }

  Future<void> _bind({InternetAddress address, int port}) async {
    address ??= InternetAddress.anyIPv4;
    port ??= 49152 + Random().nextInt(16383); // IANA range 49152 to 65535
    socket = await RawDatagramSocket.bind(address, port);
    socket.listen(_onEvent, onError: _onError, onDone: _onClose);
    log.info('Bound to target ${address.address} on port $port');
  }

  void close() {
    socket.close();
    log.info('Socket on ${target.address}:$port closed.');
  }

  void _onEvent(RawSocketEvent event) {
    var d = socket.receive();
    if (d == null) return;

    var msg = Message.fromBytes(d.data);
    if (requests.containsKey(msg.pdu.requestId)) {
      log.finest('Received expected message from ${d.address}');
      requests[msg.pdu.requestId].complete(msg);
    } else {
      log.finest('Discarding unexpected message from ${d.address.address}');
    }
/*     print(
        'Datagram from ${d.address.address}:${d.port}: ${msg.pdu.varbinds[0].value}'); */
  }

  void _onClose() {
    _cancelAllRequests();
    socket.close();
    throw Exception('Socket forcibly closed. All requests cleared.');
  }

  void _onError(Object error) {
    log.severe(error);
    throw error;
  }

  void _cancelAllRequests() => requests.clear();

  void _cancelRequest(int requestId) => requests.remove(requestId);

  int _generateId(int bitSize) => bitSize == 16
      ? (Random().nextInt(10000) % 65535).floor()
      : (Random().nextInt(100000000) % 4294967295).floor();

  Future<Message> get(Oid oid, {InternetAddress target, int port}) =>
      _get(oid, PduType.GetRequest, target: target, port: port);

  Future<Message> getNext(Oid oid, {InternetAddress target, int port}) =>
      _get(oid, PduType.GetNextRequest, target: target, port: port);

  Stream<Message> walk({InternetAddress target, int port}) {
    StreamController<Message> _ctrl;
    var paused = false;
    var oid = Oid.fromString('1.3');

    void _walk() async {
      while (true) {
        if (!paused) {
          var msg = await getNext(oid, target: target, port: port);
          oid = msg.pdu.varbinds.last.oid;
          if (msg.pdu.error == PduError.NoSuchName) {
            log.finer('Reached end of walk: ${msg.pdu.error}');
            break;
          } else if (msg.pdu.varbinds[0].type == VarbindType.EndOfMibView) {
            log.finer('Reached end of MIB view');
            break;
          } else {
            _ctrl.add(msg);
          }
        }
      }
      await _ctrl.close();
    }

    _ctrl = StreamController<Message>(
        onListen: _walk,
        onPause: () => paused = true,
        onResume: () => paused = false,
        onCancel: () {});

    return _ctrl.stream;
  }

  Future<Message> set(Varbind varbind,
      {InternetAddress target, int port}) async {
    target ??= this.target;
    port ??= this.port;
    var c = Completer<Message>();
    var p = Pdu(PduType.SetRequest, _generateId(32), [varbind]);
    while (requests.containsKey(p.requestId)) {
      p.requestId = _generateId(32);
    }
    var m = Message(version, community, p);
    var r =
        Request(target, port, m, timeout, retries, c.complete, c.completeError);
    _send(r);
    var result = await c.future;
    requests.remove(r.requestId);
    return result;
  }

  Future<Message> _get(Oid oid, PduType type,
      {InternetAddress target, int port}) async {
    target ??= this.target;
    port ??= this.port;
    var c = Completer<Message>();
    var v = Varbind(oid, VarbindType.Null, null);
    var p = Pdu(type, _generateId(32), [v]);
    while (requests.containsKey(p.requestId)) {
      p.requestId = _generateId(32);
    }
    var m = Message(version, community, p);
    var r =
        Request(target, port, m, timeout, retries, c.complete, c.completeError);
    _send(r);
    var result = await c.future;
    requests.remove(r.requestId);
    return result;
  }

  void _send(Request r) {
    log.finest('Sending: $r');
    socket.send(r.message.encodedBytes, r.target, r.port);
    Future<void>.delayed(r.timeout, () => _timeout(r));
    requests[r.requestId] = r;
  }

  void _timeout(Request r) {
    if (requests.containsKey(r.requestId)) {
      if (r.retries > 0) {
        r.retries--;
        _send(r);
      } else {
        var e = Exception('Request to ${r.target.address}:${r.port} timed out');
        r.completeError(e);
        _cancelRequest(r.requestId);
        log.info(e);
      }
    }
  }
}
