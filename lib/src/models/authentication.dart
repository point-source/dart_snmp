import 'dart:typed_data';

import 'package:pointycastle/export.dart';

class Authentication {
  Authentication(this.authProtocol, this.authKey, this.engineId);

  /// The type of authorization protocol to use (md5 or sha) when using SNMP v3
  AuthProtocol authProtocol;

  /// A user's secret key to be used when calculating a digest.
  //
  // This will be expanded to 16 octets for MD5 or 20 octets for SHA-1
  // as defined in RFC 3414 sections 6 and 7, respectively
  String authKey;

  /// Specifies the authoritative SNMP engine for [Message]s sent
  //
  // Defined in RFC 3411
  String engineId;

  /// Converts the authKey from a String to a byte list
  Uint8List get authKeyBytes => Uint8List.fromList(authKey.codeUnits);

  /// Converts the engineId from a String to a byte list
  Uint8List get engineIdBytes => Uint8List.fromList(engineId.codeUnits);

  Uint8List get privateLocalizedKey {
    final buf = _expandAuthKey(authKeyBytes);
    final d =
        authProtocol == AuthProtocol.usmHMACMD5 ? MD5Digest() : SHA1Digest();
    final first = d.process(buf);
    final bytes = BytesBuilder();
    bytes.add(first);
    bytes.add(engineIdBytes);
    bytes.add(first);
    return d.process(bytes.takeBytes());
  }

  /// Expands user-provided secret key to 16 (MD5) or 20 (SHA) octets depending
  /// on the authentication protocol selected
  Uint8List _expandAuthKey(Uint8List password, {int size = 1024 * 1024}) {
    final passwordLength = password.length;
    final remainder = size % passwordLength;
    final whole = size - remainder;

    final buf = Uint8List(size);
    for (var i = 0; i < whole; i += passwordLength) {
      buf.setRange(i, i + passwordLength, password);
    }
    buf.setRange(whole, size, password);

    return buf;
  }

  Uint8List get authParams {}

  Uint8List calculateDigest() {}
}

/// The type of authorization protocol to use (md5 or sha) when using SNMP v3
//
// Defined in RFC 3414 sections 6 and 7, respectively
enum AuthProtocol { usmHMACMD5, usmHMACSHA }
