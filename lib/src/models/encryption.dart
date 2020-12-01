import 'dart:math';
import 'dart:typed_data';

import 'package:dart_snmp/src/models/authentication.dart';
import 'package:dart_snmp/src/models/engine.dart';
import 'package:dart_snmp/src/models/pdu.dart';
import 'package:pointycastle/export.dart';

class Encryption {
  Encryption(this.authentication, this.privProtocol, this.privKey, this.engine);

  Engine engine;
  Authentication authentication;
  PrivProtocol privProtocol;
  String privKey;

  final CFBBlockCipher aesCipher = CFBBlockCipher(AESFastEngine(), 16);

  EncryptionResult encryptPdu(Pdu pdu) {
    final _encrypt = authentication.authProtocol == AuthProtocol.md5
        ? _encryptPduAes
        : _encryptPduDes;
    final result = EncryptionResult();
    result.salt = generateSalt();
    result.encryptedPdu = _encrypt(pdu.encodedBytes, result.salt);
    return result;
  }

  Pdu decryptPdu(Uint8List pduBytes) =>
      authentication.authProtocol == AuthProtocol.md5
          ? Pdu.fromBytes(_decryptPduAes(pduBytes))
          : Pdu.fromBytes(_decryptPduDes(pduBytes));

  Uint8List _encryptPduAes(Uint8List pduBytes, Uint8List salt) {
    final params = PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(_key), generateIvAes(salt)), null);
    final p = PaddedBlockCipherImpl(PKCS7Padding(), aesCipher)
      ..init(true, params);

    return p.process(pduBytes);
  }

  Uint8List _decryptPduAes(Uint8List pduBytes, Uint8List salt) {
    final params = PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(_key), _iv), null);
    final p = PaddedBlockCipherImpl(PKCS7Padding(), aesCipher)
      ..init(false, params);

    return p.process(pduBytes);
  }

  Uint8List _encryptPduDes(Uint8List pduBytes, Uint8List salt) {}

  Uint8List _decryptPduDes(Uint8List pduBytes, Uint8List salt) {}

  Uint8List get _key =>
      authentication.privateLocalizedKey.sublist(0, _keyLength);

  int get _keyLength => privProtocol == PrivProtocol.aes ? 16 : 8;

  int get _blockLength => privProtocol == PrivProtocol.aes ? 16 : 8;

  Uint8List generateSalt() =>
      Uint8List.fromList(List<int>.generate(8, (i) => Random().nextInt(256)));

  Uint8List generateIvAes(Uint8List salt) {
    final bytes = Uint8List(_blockLength);
    bytes.buffer.asByteData().setInt32(0, engine.engineBoots);
    bytes.buffer.asByteData().setInt32(4, engine.engineTime);
    bytes.setRange(8, 16, salt);
    return bytes;
  }
}

class EncryptionResult {
  Uint8List encryptedPdu;
  Uint8List salt;
}

/// The type of privacy (encryption) to use (des or aes) when using snmp v3
enum PrivProtocol { des, aes }
