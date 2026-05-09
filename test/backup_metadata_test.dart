import 'dart:convert';
import 'dart:io';

import 'package:carevault/core/models/backup_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BackupMetadata reads metadata JSON files', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'carevault_meta_test',
    );
    addTearDown(() => tempDir.delete(recursive: true));
    final file = File('${tempDir.path}/metadata.json');
    final timestamp = DateTime.utc(2026, 5, 8, 10, 15);

    await file.writeAsString(
      jsonEncode({
        'id': 'backup-1',
        'appVersion': '1.0.0',
        'backupTimestamp': timestamp.toIso8601String(),
        'deviceInfo': 'Android 15',
        'schemaVersion': 7,
        'fileCount': 3,
        'encryptionVersion': 1,
        'backupSize': 2048,
        'deviceName': 'Pixel',
        'notes': 'Manual backup',
      }),
    );

    final metadata = await BackupMetadata.fromFile(file);

    expect(metadata.id, 'backup-1');
    expect(metadata.backupTimestamp, timestamp);
    expect(metadata.schemaVersion, 7);
    expect(metadata.fileCount, 3);
    expect(metadata.deviceName, 'Pixel');
  });
}
