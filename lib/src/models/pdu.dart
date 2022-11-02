import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';

import 'package:dart_snmp/src/models/varbind.dart';

/// An SNMP Protocol Data Unit which contains a list of [Varbind]s and
/// may (when received as a response) contain error information from an
/// snmp device
class Pdu {
  /// An SNMP Protocol Data Unit which contains a list of [Varbind]s and
  /// may (when received as a response) contain error information from an
  /// snmp device
  Pdu(
    this.type,
    this.requestId,
    this.varbinds, {
    this.error = PduError.noError,
    this.errorIndex = 0,
  });

  /// Parses a list of bytes into a Pdu object
  static Pdu fromBytes(Uint8List bytes) {
    var sequence = ASN1Sequence.fromBytes(bytes);
    assert(sequence.tag > 159 && sequence.tag < 169); // PDU tags
    PduType? type;
    int? requestId;
    PduError? error;
    int? errorIndex;
    List<Varbind>? varbinds;
    type = PduType._internal(sequence.tag);
    requestId = (sequence.elements[0] as ASN1Integer).intValue;
    error = PduError.fromInt((sequence.elements[1] as ASN1Integer).intValue);
    errorIndex = (sequence.elements[2] as ASN1Integer).intValue;
    varbinds = [];
    for (var v in (sequence.elements[3] as ASN1Sequence).elements) {
      varbinds.add(Varbind.fromBytes(v.encodedBytes));
    }

    return Pdu(type, requestId, varbinds, error: error, errorIndex: errorIndex);
  }

  /// The type of snmp request/response for which this Pdu contains data
  PduType type;

  /// The unique identifier for this request
  int requestId;

  /// The type of snmp error (if any) which occured at the target
  PduError error;

  /// Indicates the presence (1) or lack of an error (0)
  int errorIndex;

  /// List of variable bindings [Varbind] which contain an [oid] and data
  List<Varbind> varbinds;

  /// Converts the Pdu to a (transmittable) list of bytes
  Uint8List get encodedBytes => asAsn1Sequence.encodedBytes;

  /// Converts the Pdu to an [ASN1Sequence] object
  ASN1Sequence get asAsn1Sequence {
    var sequence = ASN1Sequence(tag: type.value);
    sequence.add(ASN1Integer.fromInt(requestId));
    sequence.add(ASN1Integer.fromInt(error.value));
    sequence.add(ASN1Integer.fromInt(errorIndex));
    sequence.add(_varbindListSequence(varbinds));

    return sequence;
  }

  ASN1Sequence _varbindListSequence(List<Varbind> varbinds) {
    var sequence = ASN1Sequence();
    for (var v in varbinds) {
      sequence.add(v.asAsn1Sequence);
    }

    return sequence;
  }
}

/// The type of snmp request which is sent to or received from the target device
class PduType {
  const PduType._internal(this.value);

  /// Integer representation (tag) of the PDU type
  final int value;

  static const Map<int, String> _types = <int, String>{
    160: 'GetRequest',
    161: 'GetNextRequest',
    162: 'GetResponse',
    163: 'SetRequest',
    164: 'Trap',
    165: 'GetBulkRequest',
    166: 'InformRequest',
    167: 'TrapV2',
    168: 'Report',
  };

  @override
  String toString() => 'PduType.$name ($value)';

  /// Human-readable name of the PDU type
  String get name => _types[value] ?? 'Unknown';

  /// Returns true if the tag (integer) is recognized as a PDU type
  static bool contains(int i) => _types.containsKey(i);

  /// Retrieve one or more requested MIB variables specified in the PDU
  static const getRequest = PduType._internal(160);

  /// Retrieve the next MIB variable that is specified in the PDU
  static const getNextRequest = PduType._internal(161);

  /// Sent by the SNMP agent in response to a GETREQUEST,
  /// GETNEXTREQUEST, or SETREQUEST PDU
  static const getResponse = PduType._internal(162);

  /// Set one or more MIB variables specified in the PDU with
  /// the value specified in the PDU
  static const setRequest = PduType._internal(163);

  /// An unsolicited message sent by the SNMP agent to notify the SNMP manager
  /// about a significant event that occurred in the agent
  static const trap = PduType._internal(164);

  /// Requests the next variable in the MIB tree and
  /// can also be used to specify multiple successors
  static const getBulkRequest = PduType._internal(165);

  /// Sent from an agent to a manager or from a manager
  /// to another manager to report a network event
  ///
  /// Attempts to confirm delivery are made for Inform-PDUs, but not Trap-PDUs
  static const informRequest = PduType._internal(166);

  /// An unsolicited message sent by the SNMP agent to notify the SNMP manager
  /// about a significant event that occurred in the agent
  static const trapV2 = PduType._internal(167);

  /// Allows an SNMP engine to tell another SNMP engine that an error was detected
  /// while processing an SNMP message (SNMP v3 only)
  static const report = PduType._internal(168);

  @override
  bool operator ==(Object other) =>
      other is PduType && (identical(this, other) || value == other.value);

  @override
  int get hashCode => value.hashCode;
}

/// The type of error which occurred while the target device was
/// attempting to respond to the snmp request
class PduError {
  const PduError._internal(this.value);

  /// Returns the corresponding [PduError] matched to a given integer value
  /// for encoding/decoding
  PduError.fromInt(this.value);

  /// Integer representation of the PDU error
  final int value;

  static const Map<int, String> _errors = <int, String>{
    0: 'NoError',
    1: 'TooBig',
    2: 'NoSuchName',
    3: 'BadValue',
    4: 'ReadOnly',
    5: 'GeneralError',
    6: 'NoAccess',
    7: 'WrongType',
    8: 'WrongLength',
    9: 'WrongEncoding',
    10: 'WrongValue',
    11: 'NoCreation',
    12: 'InconsistentValue',
    13: 'ResourceUnavailable',
    14: 'CommitFailed',
    15: 'UndoFailed',
    16: 'AuthorizationError',
    17: 'NotWritable',
    18: 'InconsistentName',
  };

  @override
  String toString() => 'PduError.$name ($value)';

  /// Human-readable name of the PDU error
  String get name => _errors[value] ?? 'Unknown';

  /// No error detected
  static const noError = PduError._internal(0);

  /// Too big
  static const tooBig = PduError._internal(1);

  /// No such name
  static const noSuchName = PduError._internal(2);

  /// Bad value
  static const badValue = PduError._internal(3);

  /// Read only
  static const readOnly = PduError._internal(4);

  /// General error
  static const generalError = PduError._internal(5);

  /// No access
  static const noAccess = PduError._internal(6);

  /// Wrong type
  static const wrongType = PduError._internal(7);

  /// Wrong length
  static const wrongLength = PduError._internal(8);

  /// Wrong encoding
  static const wrongEncoding = PduError._internal(9);

  /// Wrong value
  static const wrongValue = PduError._internal(10);

  /// No creation
  static const noCreation = PduError._internal(11);

  /// Inconsistent value
  static const inconsistentValue = PduError._internal(12);

  /// Resource unavailable
  static const resourceUnavailable = PduError._internal(13);

  /// Commit failed
  static const commitFailed = PduError._internal(14);

  /// Undo failed
  static const undoFailed = PduError._internal(15);

  /// Authorization error
  static const authorizationError = PduError._internal(16);

  /// No writable
  static const notWritable = PduError._internal(17);

  /// Inconsistent name
  static const inconsistentName = PduError._internal(18);

  @override
  bool operator ==(Object other) =>
      other is PduError && (identical(this, other) || value == other.value);

  @override
  int get hashCode => value.hashCode;
}
