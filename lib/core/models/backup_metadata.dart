import 'dart:convert';
import 'dart:io';

class BackupMetadata {
  final String id;
  final String appVersion;
  final DateTime backupTimestamp;
  final String deviceInfo;
  final int schemaVersion;
  final int fileCount;
  final int encryptionVersion;
  final int backupSize;
  final String? deviceName;
  final String? notes;

  BackupMetadata({
    required this.id,
    required this.appVersion,
    required this.backupTimestamp,
    required this.deviceInfo,
    required this.schemaVersion,
    required this.fileCount,
    required this.encryptionVersion,
    required this.backupSize,
    this.deviceName,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appVersion': appVersion,
      'backupTimestamp': backupTimestamp.toIso8601String(),
      'deviceInfo': deviceInfo,
      'schemaVersion': schemaVersion,
      'fileCount': fileCount,
      'encryptionVersion': encryptionVersion,
      'backupSize': backupSize,
      'deviceName': deviceName,
      'notes': notes,
    };
  }

  factory BackupMetadata.fromJson(Map<String, dynamic> json) {
    return BackupMetadata(
      id: json['id'] as String,
      appVersion: json['appVersion'] as String,
      backupTimestamp: DateTime.parse(json['backupTimestamp'] as String),
      deviceInfo: json['deviceInfo'] as String,
      schemaVersion: json['schemaVersion'] as int,
      fileCount: json['fileCount'] as int,
      encryptionVersion: json['encryptionVersion'] as int,
      backupSize: json['backupSize'] as int,
      deviceName: json['deviceName'] as String?,
      notes: json['notes'] as String?,
    );
  }

  static Future<BackupMetadata> fromFile(File file) async {
    final content = await file.readAsString();
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Backup metadata must be a JSON object');
    }
    return BackupMetadata.fromJson(decoded);
  }

  @override
  String toString() {
    return 'BackupMetadata(id: $id, appVersion: $appVersion, backupTimestamp: $backupTimestamp, deviceInfo: $deviceInfo, schemaVersion: $schemaVersion, fileCount: $fileCount, encryptionVersion: $encryptionVersion, backupSize: $backupSize, deviceName: $deviceName, notes: $notes)';
  }
}
