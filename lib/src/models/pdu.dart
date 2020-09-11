import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:dart_snmp/src/models/varbind.dart';

class Pdu {
  Pdu(this.type, this.requestId, this.varbinds,
      {this.error = PduError.NoError, this.errorIndex = 0});

  Pdu.fromBytes(Uint8List bytes) {
    var parser = ASN1Parser(bytes);
    var sequence = parser.nextObject();
    assert(sequence.tag > 159 && sequence.tag < 169); // PDU tags
/*     for (var o in sequence.elements) {
      switch (o.tag) {
        case INTEGER_TYPE:
          requestId = (o as ASN1Integer).intValue;
          o = parser.nextObject();
          error = PduError.fromInt((o as ASN1Integer).intValue);
          o = parser.nextObject();
          errorIndex = (o as ASN1Integer).intValue;
          break;
        case SEQUENCE_TYPE:
          varbinds = [];
          for (var v in (o as ASN1Sequence).elements) {
            varbinds.add(Varbind.fromBytes(v.encodedBytes));
          }
          break;
        default:
          throw Exception('No matching snmp type for incoming bytes');
      }
    } */
  }

  PduType type;
  int requestId;
  PduError error;
  int errorIndex;
  List<Varbind> varbinds;

  Uint8List get encodedBytes => asAsn1Sequence.encodedBytes;

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

class PduType {
  const PduType._internal(this.value);

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
    168: 'Report'
  };

  @override
  String toString() => 'PduType.$name ($value)';

  String get name => _types[value];

  static const GetRequest = PduType._internal(160);
  static const GetNextRequest = PduType._internal(161);
  static const GetResponse = PduType._internal(162);
  static const SetRequest = PduType._internal(163);
  static const Trap = PduType._internal(164);
  static const GetBulkRequest = PduType._internal(165);
  static const InformRequest = PduType._internal(166);
  static const TrapV2 = PduType._internal(167);
  static const Repor = PduType._internal(168);
}

class PduError {
  const PduError._internal(this.value);

  PduError.fromInt(this.value);

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
    18: 'InconsistentName'
  };

  @override
  String toString() => 'PduError.$name ($value)';

  String get name => _errors[value];

  static const NoError = PduError._internal(0);
  static const TooBig = PduError._internal(1);
  static const NoSuchName = PduError._internal(2);
  static const BadValue = PduError._internal(3);
  static const ReadOnly = PduError._internal(4);
  static const GeneralError = PduError._internal(5);
  static const NoAccess = PduError._internal(6);
  static const WrongType = PduError._internal(7);
  static const WrongLength = PduError._internal(8);
  static const WrongEncoding = PduError._internal(9);
  static const WrongValue = PduError._internal(10);
  static const NoCreation = PduError._internal(11);
  static const InconsistentValue = PduError._internal(12);
  static const ResourceUnavailable = PduError._internal(13);
  static const CommitFailed = PduError._internal(14);
  static const UndoFailed = PduError._internal(15);
  static const AuthorizationError = PduError._internal(16);
  static const NotWritable = PduError._internal(17);
  static const InconsistentNam = PduError._internal(18);
}
