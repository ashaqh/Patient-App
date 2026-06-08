import 'dart:convert';
import 'dart:typed_data';

import 'package:carevault/core/services/backup/backup_crypto_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedKeyStore implements BackupKeyStore {
  final Uint8List key;

  _FixedKeyStore(this.key);

  @override
  Future<Uint8List> getOrCreateBackupKey() async => key;

  @override
  Future<void> clearBackupKey() async {}
}

void main() {
  test('backup payloads require the same passphrase across installs', () async {
    final firstInstall = BackupCryptoService(
      keyStore: _FixedKeyStore(Uint8List.fromList(List<int>.filled(32, 1))),
    );
    final laterInstall = BackupCryptoService(
      keyStore: _FixedKeyStore(Uint8List.fromList(List<int>.filled(32, 2))),
    );

    final encrypted = await firstInstall.encryptBytes(
      Uint8List.fromList(utf8.encode('backup archive bytes')),
      passphrase: 'correct horse battery staple',
    );

    final decrypted = await laterInstall.decryptBytes(
      encrypted,
      passphrase: 'correct horse battery staple',
    );

    expect(utf8.decode(decrypted), 'backup archive bytes');
  });

  test('wrong passphrase fails with a safe error', () async {
    final crypto = BackupCryptoService(
      keyStore: _FixedKeyStore(Uint8List.fromList(List<int>.filled(32, 1))),
    );

    final encrypted = await crypto.encryptBytes(
      Uint8List.fromList(utf8.encode('backup archive bytes')),
      passphrase: 'correct horse battery staple',
    );

    expect(
      () => crypto.decryptBytes(
        encrypted,
        passphrase: 'wrong passphrase',
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('passphrase'),
        ),
      ),
    );
  });
}
