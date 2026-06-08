import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

import '../../models/backup_metadata.dart';
import 'backup_crypto_service.dart';

class BackupPackageResult {
  final File file;
  final BackupMetadata metadata;
  final String checksum;
  final int unencryptedSize;

  const BackupPackageResult({
    required this.file,
    required this.metadata,
    required this.checksum,
    required this.unencryptedSize,
  });
}

class BackupPackageService {
  final BackupCryptoService _cryptoService;

  BackupPackageService({BackupCryptoService? cryptoService})
    : _cryptoService = cryptoService ?? BackupCryptoService();

  Future<BackupPackageResult> createEncryptedPackage({
    required Directory outputDirectory,
    required File databaseFile,
    required List<Directory> attachmentDirectories,
    required BackupMetadata metadata,
    required String passphrase,
    Map<String, dynamic> settings = const {},
    String? profileJson,
  }) async {
    if (!await databaseFile.exists()) {
      throw StateError('Database file not found at ${databaseFile.path}');
    }
    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }

    final fileManifest = <Map<String, String>>[];
    final archiveEntries = <ArchiveFile>[];

    _addEntry(archiveEntries, 'database.db', await databaseFile.readAsBytes());
    _addEntry(
      archiveEntries,
      'settings.json',
      Uint8List.fromList(utf8.encode(jsonEncode(settings))),
    );
    if (profileJson != null) {
      _addEntry(
        archiveEntries,
        'profile.json',
        Uint8List.fromList(utf8.encode(profileJson)),
      );
    }

    for (final directory in attachmentDirectories) {
      if (!await directory.exists()) continue;
      final baseName = path.basename(directory.path);
      await for (final entity in directory.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File) continue;
        final relativePath = path
            .join(
              'files',
              baseName,
              path.relative(entity.path, from: directory.path),
            )
            .replaceAll(r'\', '/');
        _addEntry(archiveEntries, relativePath, await entity.readAsBytes());
        fileManifest.add({
          'originalPath': entity.path,
          'relativePath': relativePath,
        });
      }
    }

    _addEntry(
      archiveEntries,
      'file_manifest.json',
      Uint8List.fromList(utf8.encode(jsonEncode(fileManifest))),
    );

    var actualMetadata = _copyMetadata(
      metadata,
      fileCount: fileManifest.length,
      backupSize: 0,
    );
    var checksum = '';
    var zipBytes = Uint8List(0);
    var encryptedBytes = Uint8List(0);
    for (var attempt = 0; attempt < 3; attempt++) {
      final archive = _buildArchive(archiveEntries, actualMetadata);
      checksum = utf8.decode(
        _contentBytes(archive.findFile('checksum.sha256')!),
      );
      zipBytes = Uint8List.fromList(ZipEncoder().encode(archive)!);
      encryptedBytes = await _cryptoService.encryptBytes(
        zipBytes,
        passphrase: passphrase,
      );
      if (actualMetadata.backupSize == encryptedBytes.length) break;
      actualMetadata = _copyMetadata(
        metadata,
        fileCount: fileManifest.length,
        backupSize: encryptedBytes.length,
      );
    }

    final outputFile = File(
      path.join(outputDirectory.path, '${metadata.id}.cvbackup'),
    );
    await outputFile.writeAsBytes(encryptedBytes, flush: true);

    return BackupPackageResult(
      file: outputFile,
      metadata: actualMetadata,
      checksum: checksum,
      unencryptedSize: zipBytes.length,
    );
  }

  Future<Archive> decryptPackage(
    File packageFile, {
    String? passphrase,
  }) async {
    final encryptedBytes = await packageFile.readAsBytes();
    final zipBytes = await _cryptoService.decryptBytes(
      Uint8List.fromList(encryptedBytes),
      passphrase: passphrase,
    );
    final archive = ZipDecoder().decodeBytes(zipBytes);
    validateArchive(archive);
    return archive;
  }

  BackupMetadata readMetadata(Archive archive) {
    final file = archive.findFile('metadata.json');
    if (file == null) {
      throw const FormatException('Backup metadata is missing');
    }
    return BackupMetadata.fromJson(
      jsonDecode(utf8.decode(_contentBytes(file))) as Map<String, dynamic>,
    );
  }

  List<Map<String, String>> readFileManifest(Archive archive) {
    final file = archive.findFile('file_manifest.json');
    if (file == null) return const [];
    final decoded = jsonDecode(utf8.decode(_contentBytes(file)));
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map(
          (entry) => {
            'originalPath': entry['originalPath'] as String,
            'relativePath': entry['relativePath'] as String,
          },
        )
        .toList(growable: false);
  }

  void validateArchive(Archive archive) {
    final requiredFiles = [
      'metadata.json',
      'database.db',
      'settings.json',
      'checksum.sha256',
    ];
    for (final fileName in requiredFiles) {
      if (archive.findFile(fileName) == null) {
        throw FormatException('Backup is missing $fileName');
      }
    }

    final expected = utf8
        .decode(_contentBytes(archive.findFile('checksum.sha256')!))
        .trim();
    final withoutChecksum = Archive();
    for (final file in archive.files) {
      if (file.name == 'checksum.sha256') continue;
      withoutChecksum.addFile(
        ArchiveFile(file.name, file.size, _contentBytes(file)),
      );
    }
    final actual = _checksumArchive(withoutChecksum);
    if (expected != actual) {
      throw const FormatException('Backup checksum does not match');
    }
  }

  static Archive _buildArchive(
    List<ArchiveFile> entries,
    BackupMetadata metadata,
  ) {
    final metadataBytes = Uint8List.fromList(
      utf8.encode(jsonEncode(metadata.toJson())),
    );
    final archive = Archive()
      ..addFile(
        ArchiveFile.noCompress(
          'metadata.json',
          metadataBytes.length,
          metadataBytes,
        ),
      );
    for (final entry in entries) {
      archive.addFile(
        ArchiveFile(entry.name, entry.size, _contentBytes(entry)),
      );
    }

    final checksum = _checksumArchive(archive);
    final checksumBytes = Uint8List.fromList(utf8.encode(checksum));
    archive.addFile(
      ArchiveFile('checksum.sha256', checksumBytes.length, checksumBytes),
    );
    return archive;
  }

  static void _addEntry(
    List<ArchiveFile> entries,
    String name,
    Uint8List bytes,
  ) {
    entries.add(ArchiveFile(name, bytes.length, bytes));
  }

  static BackupMetadata _copyMetadata(
    BackupMetadata metadata, {
    required int fileCount,
    required int backupSize,
  }) {
    return BackupMetadata(
      id: metadata.id,
      appVersion: metadata.appVersion,
      backupTimestamp: metadata.backupTimestamp,
      deviceInfo: metadata.deviceInfo,
      schemaVersion: metadata.schemaVersion,
      fileCount: fileCount,
      encryptionVersion: metadata.encryptionVersion,
      backupSize: backupSize,
      deviceName: metadata.deviceName,
      notes: metadata.notes,
    );
  }

  static String _checksumArchive(Archive archive) {
    final builder = BytesBuilder(copy: false);
    final sortedFiles = archive.files.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    for (final file in sortedFiles) {
      builder.add(utf8.encode(file.name));
      builder.add(_contentBytes(file));
    }
    return sha256.convert(builder.takeBytes()).toString();
  }

  static Uint8List _contentBytes(ArchiveFile file) {
    final content = file.content;
    if (content is Uint8List) return content;
    if (content is List<int>) return Uint8List.fromList(content);
    throw FormatException('Unsupported archive content for ${file.name}');
  }
}
