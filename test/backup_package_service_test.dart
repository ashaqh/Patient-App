import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:carevault/core/models/backup_metadata.dart';
import 'package:carevault/core/services/backup/backup_crypto_service.dart';
import 'package:carevault/core/services/backup/backup_package_service.dart';
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
  test(
    'backup package encrypts archive and restores required entries',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'carevault_pkg_test',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final dbFile = File('${tempDir.path}/carevault.db');
      await dbFile.writeAsBytes(utf8.encode('sqlite bytes with medical data'));

      final filesDir = Directory('${tempDir.path}/prescriptions');
      await filesDir.create();
      await File('${filesDir.path}/report.pdf').writeAsBytes([1, 2, 3, 4]);

      final metadata = BackupMetadata(
        id: 'backup-1',
        appVersion: '1.0.0',
        backupTimestamp: DateTime.utc(2026, 5, 8, 10, 15),
        deviceInfo: 'Android 15',
        schemaVersion: 7,
        fileCount: 1,
        encryptionVersion: 1,
        backupSize: 0,
        deviceName: 'Pixel',
      );

      final crypto = BackupCryptoService(
        keyStore: _FixedKeyStore(Uint8List.fromList(List<int>.filled(32, 7))),
      );
      final service = BackupPackageService(cryptoService: crypto);

      final result = await service.createEncryptedPackage(
        outputDirectory: tempDir,
        databaseFile: dbFile,
        attachmentDirectories: [filesDir],
        metadata: metadata,
        settings: {'automaticBackupEnabled': true},
      );

      final encryptedBytes = await result.file.readAsBytes();
      expect(
        utf8.decode(encryptedBytes, allowMalformed: true),
        isNot(contains('medical data')),
      );

      final archive = await service.decryptPackage(result.file);
      expect(archive.findFile('metadata.json'), isNotNull);
      expect(archive.findFile('database.db'), isNotNull);
      expect(archive.findFile('files/prescriptions/report.pdf'), isNotNull);
      expect(archive.findFile('settings.json'), isNotNull);
      expect(archive.findFile('checksum.sha256'), isNotNull);

      final checksum = utf8.decode(
        archive.findFile('checksum.sha256')!.content as List<int>,
      );
      expect(checksum, isNotEmpty);
      final restoredMetadata = service.readMetadata(archive);
      expect(restoredMetadata.fileCount, 1);
      expect(restoredMetadata.backupSize, result.file.lengthSync());
    },
  );
}
