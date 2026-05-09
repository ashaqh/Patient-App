import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class BackupKeyStore {
  Future<Uint8List> getOrCreateBackupKey();
  Future<void> clearBackupKey();
}

class SecureBackupKeyStore implements BackupKeyStore {
  static const _backupKeyName = 'carevault_backup_encryption_key_v1';

  final FlutterSecureStorage _secureStorage;

  const SecureBackupKeyStore({
    FlutterSecureStorage secureStorage = const FlutterSecureStorage(),
  }) : _secureStorage = secureStorage;

  @override
  Future<Uint8List> getOrCreateBackupKey() async {
    final existing = await _secureStorage.read(key: _backupKeyName);
    if (existing != null && existing.isNotEmpty) {
      return base64Url.decode(existing);
    }

    final key = _randomBytes(32);
    await _secureStorage.write(
      key: _backupKeyName,
      value: base64UrlEncode(key),
    );
    return key;
  }

  @override
  Future<void> clearBackupKey() {
    return _secureStorage.delete(key: _backupKeyName);
  }
}

class BackupCryptoService {
  static final _magic = Uint8List.fromList([0x43, 0x56, 0x42, 0x31]); // CVB1
  static const int _ivLength = 16;
  static const int _macLength = 32;

  final BackupKeyStore keyStore;

  BackupCryptoService({BackupKeyStore? keyStore})
    : keyStore = keyStore ?? const SecureBackupKeyStore();

  Future<Uint8List> encryptBytes(Uint8List plainBytes) async {
    final masterKey = await keyStore.getOrCreateBackupKey();
    final iv = _randomBytes(_ivLength);
    final cipher = _encrypter(masterKey).encryptBytes(plainBytes, iv: IV(iv));

    final body = Uint8List.fromList([..._magic, ...iv, ...cipher.bytes]);
    final mac = _hmac(masterKey, body);
    return Uint8List.fromList([...body, ...mac]);
  }

  Future<Uint8List> decryptBytes(Uint8List encryptedBytes) async {
    if (encryptedBytes.length <= _magic.length + _ivLength + _macLength) {
      throw const FormatException('Backup payload is too short');
    }

    final magic = encryptedBytes.sublist(0, _magic.length);
    if (!_constantTimeEquals(magic, _magic)) {
      throw const FormatException('Unsupported backup encryption format');
    }

    final masterKey = await keyStore.getOrCreateBackupKey();
    final body = encryptedBytes.sublist(0, encryptedBytes.length - _macLength);
    final expectedMac = _hmac(masterKey, body);
    final actualMac = encryptedBytes.sublist(
      encryptedBytes.length - _macLength,
    );
    if (!_constantTimeEquals(actualMac, expectedMac)) {
      throw const FormatException('Backup integrity check failed');
    }

    final iv = encryptedBytes.sublist(_magic.length, _magic.length + _ivLength);
    final cipherBytes = encryptedBytes.sublist(
      _magic.length + _ivLength,
      encryptedBytes.length - _macLength,
    );

    final plain = _encrypter(
      masterKey,
    ).decryptBytes(Encrypted(cipherBytes), iv: IV(iv));
    return Uint8List.fromList(plain);
  }

  Encrypter _encrypter(Uint8List masterKey) {
    return Encrypter(AES(Key(_deriveKey(masterKey, 'encryption'))));
  }

  static Uint8List _deriveKey(Uint8List masterKey, String purpose) {
    return Uint8List.fromList(
      sha256.convert([...masterKey, ...utf8.encode(purpose)]).bytes,
    );
  }

  static Uint8List _hmac(Uint8List masterKey, Uint8List data) {
    final key = _deriveKey(masterKey, 'integrity');
    return Uint8List.fromList(Hmac(sha256, key).convert(data).bytes);
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

Uint8List _randomBytes(int length) {
  final random = Random.secure();
  return Uint8List.fromList(
    List<int>.generate(length, (_) => random.nextInt(256)),
  );
}
