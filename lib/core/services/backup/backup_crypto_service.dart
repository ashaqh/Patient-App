import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';

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
  static const currentEncryptionVersion = 3;
  static final _magicV1 = Uint8List.fromList([0x43, 0x56, 0x42, 0x31]); // CVB1
  static final _magicV2 = Uint8List.fromList([0x43, 0x56, 0x42, 0x32]); // CVB2
  static final _magicV3 = Uint8List.fromList([0x43, 0x56, 0x42, 0x33]); // CVB3
  static const int _ivLength = 16;
  static const int _saltLength = 16;
  static const int _macLength = 32;
  static const int _kdfIterationsLength = 4;
  static const int _pbkdf2Iterations = 150000;
  static const int _masterKeyLength = 32;

  final BackupKeyStore keyStore;

  BackupCryptoService({BackupKeyStore? keyStore})
    : keyStore = keyStore ?? const SecureBackupKeyStore();

  Future<Uint8List> encryptBytes(
    Uint8List plainBytes, {
    required String passphrase,
  }) async {
    if (passphrase.trim().isEmpty) {
      throw const FormatException('Backup passphrase is required');
    }

    final salt = _randomBytes(_saltLength);
    final iv = _randomBytes(_ivLength);
    final masterKey = _derivePassphraseMasterKey(
      passphrase: passphrase,
      salt: salt,
      iterations: _pbkdf2Iterations,
    );
    final cipher = _encrypter(masterKey).encryptBytes(plainBytes, iv: IV(iv));

    final bodyBuilder = BytesBuilder(copy: false)
      ..add(_magicV3)
      ..add(_uint32be(_pbkdf2Iterations))
      ..add(salt)
      ..add(iv)
      ..add(cipher.bytes);
    final body = bodyBuilder.takeBytes();
    final mac = _hmac(masterKey, body);
    return Uint8List.fromList([...body, ...mac]);
  }

  Future<Uint8List> decryptBytes(
    Uint8List encryptedBytes, {
    String? passphrase,
  }) async {
    if (encryptedBytes.length < _magicV3.length + _macLength + 1) {
      throw const FormatException('Backup payload is too short');
    }

    final magic = encryptedBytes.sublist(0, _magicV3.length);
    final isV3 = _constantTimeEquals(magic, _magicV3);
    final isV2 = _constantTimeEquals(magic, _magicV2);
    final isV1 = _constantTimeEquals(magic, _magicV1);
    if (!isV3 && !isV2 && !isV1) {
      throw const FormatException('Unsupported backup encryption format');
    }

    if (isV3) {
      return _decryptV3(encryptedBytes, passphrase: passphrase);
    }

    return _decryptLegacy(encryptedBytes, isV2: isV2);
  }

  Future<Uint8List> _decryptLegacy(
    Uint8List encryptedBytes, {
    required bool isV2,
  }) async {
    if (encryptedBytes.length <= _magicV2.length + _ivLength + _macLength) {
      throw const FormatException('Backup payload is too short');
    }

    final masterKey = isV2
        ? _legacyPortableMasterKey()
        : await keyStore.getOrCreateBackupKey();
    final body = encryptedBytes.sublist(0, encryptedBytes.length - _macLength);
    final expectedMac = _hmac(masterKey, body);
    final actualMac = encryptedBytes.sublist(
      encryptedBytes.length - _macLength,
    );
    if (!_constantTimeEquals(actualMac, expectedMac)) {
      throw const FormatException('Backup integrity check failed');
    }

    final iv = encryptedBytes.sublist(
      _magicV2.length,
      _magicV2.length + _ivLength,
    );
    final cipherBytes = encryptedBytes.sublist(
      _magicV2.length + _ivLength,
      encryptedBytes.length - _macLength,
    );

    final plain = _encrypter(
      masterKey,
    ).decryptBytes(Encrypted(cipherBytes), iv: IV(iv));
    return Uint8List.fromList(plain);
  }

  Uint8List _decryptV3(Uint8List encryptedBytes, {String? passphrase}) {
    if (passphrase == null || passphrase.trim().isEmpty) {
      throw const FormatException('Backup passphrase is required');
    }

    final minimumLength =
        _magicV3.length +
        _kdfIterationsLength +
        _saltLength +
        _ivLength +
        _macLength +
        1;
    if (encryptedBytes.length < minimumLength) {
      throw const FormatException('Backup payload is too short');
    }

    final iterations = _readUint32be(
      encryptedBytes,
      offset: _magicV3.length,
    );
    if (iterations <= 0) {
      throw const FormatException('Backup payload has invalid KDF parameters');
    }

    final saltStart = _magicV3.length + _kdfIterationsLength;
    final saltEnd = saltStart + _saltLength;
    final ivEnd = saltEnd + _ivLength;

    final salt = encryptedBytes.sublist(saltStart, saltEnd);
    final iv = encryptedBytes.sublist(saltEnd, ivEnd);
    final cipherBytes = encryptedBytes.sublist(
      ivEnd,
      encryptedBytes.length - _macLength,
    );

    final masterKey = _derivePassphraseMasterKey(
      passphrase: passphrase,
      salt: salt,
      iterations: iterations,
    );
    final body = encryptedBytes.sublist(0, encryptedBytes.length - _macLength);
    final expectedMac = _hmac(masterKey, body);
    final actualMac = encryptedBytes.sublist(
      encryptedBytes.length - _macLength,
    );
    if (!_constantTimeEquals(actualMac, expectedMac)) {
      throw const FormatException(
        'Backup passphrase is incorrect or backup is corrupted',
      );
    }

    try {
      final plain = _encrypter(
        masterKey,
      ).decryptBytes(Encrypted(cipherBytes), iv: IV(iv));
      return Uint8List.fromList(plain);
    } catch (_) {
      throw const FormatException(
        'Backup passphrase is incorrect or backup is corrupted',
      );
    }
  }

  Encrypter _encrypter(Uint8List masterKey) {
    return Encrypter(AES(Key(_deriveKey(masterKey, 'encryption'))));
  }

  static Uint8List _deriveKey(Uint8List masterKey, String purpose) {
    return Uint8List.fromList(
      sha256.convert([...masterKey, ...utf8.encode(purpose)]).bytes,
    );
  }

  static Uint8List _derivePassphraseMasterKey({
    required String passphrase,
    required Uint8List salt,
    required int iterations,
  }) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    derivator.init(Pbkdf2Parameters(salt, iterations, _masterKeyLength));
    return Uint8List.fromList(derivator.process(utf8.encode(passphrase)));
  }

  static Uint8List _legacyPortableMasterKey() {
    return Uint8List.fromList(
      sha256
          .convert(utf8.encode('carevault-drive-backup-portable-key-v2'))
          .bytes,
    );
  }

  static Uint8List _hmac(Uint8List masterKey, Uint8List data) {
    final key = _deriveKey(masterKey, 'integrity');
    return Uint8List.fromList(Hmac(sha256, key).convert(data).bytes);
  }

  static Uint8List _uint32be(int value) {
    final data = ByteData(4)..setUint32(0, value, Endian.big);
    return data.buffer.asUint8List();
  }

  static int _readUint32be(Uint8List bytes, {required int offset}) {
    return ByteData.sublistView(bytes, offset, offset + 4).getUint32(0);
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
