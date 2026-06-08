import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:carevault/core/models/backup_metadata.dart';
import 'package:carevault/core/services/backup/backup_crypto_service.dart';
import 'package:carevault/core/services/backup/backup_package_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

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
        encryptionVersion: 3,
        backupSize: 0,
        deviceName: 'Pixel',
      );

      final crypto = BackupCryptoService();
      final service = BackupPackageService(cryptoService: crypto);

      final result = await service.createEncryptedPackage(
        outputDirectory: tempDir,
        databaseFile: dbFile,
        attachmentDirectories: [filesDir],
        metadata: metadata,
        passphrase: 'correct horse battery staple',
        settings: {'automaticBackupEnabled': true},
      );

      final encryptedBytes = await result.file.readAsBytes();
      expect(
        utf8.decode(encryptedBytes, allowMalformed: true),
        isNot(contains('medical data')),
      );

      final archive = await service.decryptPackage(
        result.file,
        passphrase: 'correct horse battery staple',
      );
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

  test(
    'backup package decrypts passphrase-protected archives with compressed metadata',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'carevault_legacy_pkg_test',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final metadata = BackupMetadata(
        id: 'legacy-backup-1',
        appVersion: '1.0.0',
        backupTimestamp: DateTime.utc(2026, 5, 8, 10, 15),
        deviceInfo: 'Android 15',
        schemaVersion: 7,
        fileCount: 0,
        encryptionVersion: 3,
        backupSize: 0,
        deviceName: 'Pixel',
      );

      final archive = Archive()
        ..addFile(
          _testArchiveFile(
            'metadata.json',
            utf8.encode(jsonEncode(metadata.toJson())),
          ),
        )
        ..addFile(_testArchiveFile('database.db', utf8.encode('sqlite bytes')))
        ..addFile(_testArchiveFile('settings.json', utf8.encode('{}')));

      final checksum = _checksumArchiveForTest(archive);
      archive.addFile(
        _testArchiveFile('checksum.sha256', utf8.encode(checksum)),
      );

      final crypto = BackupCryptoService();
      final packageFile = File('${tempDir.path}/legacy.cvbackup');
      await packageFile.writeAsBytes(
        await crypto.encryptBytes(
          Uint8List.fromList(ZipEncoder().encode(archive)!),
          passphrase: 'correct horse battery staple',
        ),
      );

      final service = BackupPackageService(cryptoService: crypto);
      final restoredArchive = await service.decryptPackage(
        packageFile,
        passphrase: 'correct horse battery staple',
      );

      expect(restoredArchive.findFile('database.db'), isNotNull);
      expect(service.readMetadata(restoredArchive).id, 'legacy-backup-1');
    },
  );

  test(
    'backup package bundles profile.json when provided and keeps it optional',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'carevault_profile_pkg_test',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final dbFile = File('${tempDir.path}/carevault.db');
      await dbFile.writeAsBytes(utf8.encode('sqlite bytes'));

      final metadata = BackupMetadata(
        id: 'backup-profile-1',
        appVersion: '1.0.0',
        backupTimestamp: DateTime.utc(2026, 5, 8, 10, 15),
        deviceInfo: 'Android 15',
        schemaVersion: 7,
        fileCount: 0,
        encryptionVersion: 3,
        backupSize: 0,
        deviceName: 'Pixel',
      );

      final crypto = BackupCryptoService();
      final service = BackupPackageService(cryptoService: crypto);

      // Test with profileJson
      final resultWithProfile = await service.createEncryptedPackage(
        outputDirectory: tempDir,
        databaseFile: dbFile,
        attachmentDirectories: [],
        metadata: metadata,
        passphrase: 'correct horse battery staple',
        settings: {},
        profileJson: '{"fullName":"Ashaq"}',
      );

      final archiveWithProfile = await service.decryptPackage(
        resultWithProfile.file,
        passphrase: 'correct horse battery staple',
      );
      expect(archiveWithProfile.findFile('profile.json'), isNotNull);
      final profileContent = utf8.decode(
        archiveWithProfile.findFile('profile.json')!.content as List<int>,
      );
      expect(profileContent, '{"fullName":"Ashaq"}');

      // Test without profileJson
      final resultNoProfile = await service.createEncryptedPackage(
        outputDirectory: tempDir,
        databaseFile: dbFile,
        attachmentDirectories: [],
        metadata: metadata,
        passphrase: 'correct horse battery staple',
        settings: {},
        profileJson: null,
      );

      final archiveNoProfile = await service.decryptPackage(
        resultNoProfile.file,
        passphrase: 'correct horse battery staple',
      );
      expect(archiveNoProfile.findFile('profile.json'), isNull);
    },
  );
}

ArchiveFile _testArchiveFile(String name, List<int> bytes) {
  return ArchiveFile(name, bytes.length, Uint8List.fromList(bytes));
}

String _checksumArchiveForTest(Archive archive) {
  final builder = BytesBuilder(copy: false);
  final sortedFiles = archive.files.toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  for (final file in sortedFiles) {
    builder.add(utf8.encode(file.name));
    final content = file.content;
    if (content is Uint8List) {
      builder.add(content);
    } else if (content is List<int>) {
      builder.add(content);
    } else {
      throw FormatException('Unsupported archive content for ${file.name}');
    }
  }
  return sha256.convert(builder.takeBytes()).toString();
}
