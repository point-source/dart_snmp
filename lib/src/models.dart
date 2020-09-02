class User {
  User(this.name, this.level,
      {this.authProtocol = AuthProtocol.sha,
      this.authKey,
      this.privProtocol = PrivProtocol.des,
      this.privKey});

  String name;
  SecurityLevel level = SecurityLevel.authNoPriv;
  AuthProtocol authProtocol = AuthProtocol.sha;
  String authKey;
  PrivProtocol privProtocol = PrivProtocol.des;
  String privKey;
}

enum SecurityLevel {
  noAuthNoPriv,
  authNoPriv,
  authPriv,
}

enum AuthProtocol { md5, sha }

enum PrivProtocol { des, aes }
