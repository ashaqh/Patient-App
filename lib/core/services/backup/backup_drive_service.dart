import 'dart:async';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import '../../models/backup_metadata.dart';

class BackupAccountInfo {
  final String email;
  final String? displayName;
  final String? photoUrl;

  const BackupAccountInfo({
    required this.email,
    this.displayName,
    this.photoUrl,
  });
}

class BackupDriveFile {
  final String id;
  final String name;
  final BackupMetadata metadata;

  const BackupDriveFile({
    required this.id,
    required this.name,
    required this.metadata,
  });
}

class GoogleDriveAccount {
  final String email;
  final String? displayName;
  final String? photoUrl;

  const GoogleDriveAccount({
    required this.email,
    this.displayName,
    this.photoUrl,
  });
}

abstract class GoogleDriveSignInClient {
  GoogleDriveAccount? get currentUser;

  Future<GoogleDriveAccount?> signIn();
  Future<GoogleDriveAccount?> signInSilently();
  Future<bool> requestScopes(List<String> scopes);
  Future<Map<String, String>> authHeadersFor(GoogleDriveAccount account);
  Future<void> signOut();
}

class GoogleSignInDriveClient implements GoogleDriveSignInClient {
  GoogleSignInDriveClient({GoogleSignIn? googleSignIn})
    : _googleSignIn =
          googleSignIn ??
          GoogleSignIn(scopes: <String>[BackupDriveService.driveScope]);

  final GoogleSignIn _googleSignIn;

  @override
  GoogleDriveAccount? get currentUser {
    final account = _googleSignIn.currentUser;
    return account == null ? null : _toDriveAccount(account);
  }

  @override
  Future<Map<String, String>> authHeadersFor(GoogleDriveAccount account) async {
    final googleAccount = _googleSignIn.currentUser;
    if (googleAccount == null || googleAccount.email != account.email) {
      throw StateError('Google Drive is not connected');
    }
    return googleAccount.authHeaders;
  }

  @override
  Future<bool> requestScopes(List<String> scopes) {
    return _googleSignIn.requestScopes(scopes);
  }

  @override
  Future<GoogleDriveAccount?> signIn() async {
    final account = await _googleSignIn.signIn();
    return account == null ? null : _toDriveAccount(account);
  }

  @override
  Future<GoogleDriveAccount?> signInSilently() async {
    final account = await _googleSignIn.signInSilently();
    return account == null ? null : _toDriveAccount(account);
  }

  @override
  Future<void> signOut() {
    return _googleSignIn.signOut();
  }

  static GoogleDriveAccount _toDriveAccount(GoogleSignInAccount account) {
    return GoogleDriveAccount(
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
    );
  }
}

class BackupDriveService {
  static const String backupMimeType = 'application/vnd.carevault.backup';
  static const String backupNamePrefix = 'carevault-backup-';
  static const String driveScope = drive.DriveApi.driveAppdataScope;

  final GoogleDriveSignInClient _signInClient;
  drive.DriveApi? _driveApi;
  BackupAccountInfo? _currentAccount;

  BackupDriveService({
    GoogleDriveSignInClient? signInClient,
    GoogleSignIn? googleSignIn,
  }) : _signInClient =
           signInClient ?? GoogleSignInDriveClient(googleSignIn: googleSignIn);

  BackupAccountInfo? get currentAccount => _currentAccount;

  Future<BackupAccountInfo?> restorePreviousSignIn() async {
    final account = await _signInClient.signInSilently();
    if (account == null) return null;
    try {
      return await _authorizeAndSetAccount(account, requestScopes: false);
    } catch (_) {
      _driveApi = null;
      _currentAccount = null;
      return null;
    }
  }

  Future<BackupAccountInfo?> signIn() async {
    final account = await _signInClient.signIn();
    if (account == null) return null;
    try {
      return await _authorizeAndSetAccount(account, requestScopes: true);
    } catch (_) {
      _driveApi = null;
      _currentAccount = null;
      return null;
    }
  }

  Future<BackupAccountInfo?> changeAccount() async {
    await _signInClient.signOut();
    _driveApi = null;
    _currentAccount = null;
    return signIn();
  }

  Future<void> signOut() async {
    await _signInClient.signOut();
    _driveApi = null;
    _currentAccount = null;
  }

  Future<BackupDriveFile> uploadBackup({
    required File file,
    required BackupMetadata metadata,
    int keepLatest = 5,
  }) async {
    final api = await _requireDriveApi();
    final driveFile = drive.File()
      ..name =
          '$backupNamePrefix${metadata.backupTimestamp.toUtc().toIso8601String()}.cvbackup'
      ..mimeType = backupMimeType
      ..parents = ['appDataFolder']
      ..appProperties = _metadataProperties(metadata);

    final media = drive.Media(file.openRead(), await file.length());
    final uploaded = await api.files.create(
      driveFile,
      uploadMedia: media,
      $fields: 'id,name,size,createdTime,appProperties',
    );
    await pruneOldBackups(keepLatest: keepLatest);

    return BackupDriveFile(
      id: uploaded.id!,
      name: uploaded.name ?? path.basename(file.path),
      metadata: metadata,
    );
  }

  Future<List<BackupDriveFile>> listBackups() async {
    final api = await _requireDriveApi();
    final response = await api.files.list(
      spaces: 'appDataFolder',
      q: "mimeType = '$backupMimeType' and trashed = false",
      orderBy: 'createdTime desc',
      $fields: 'files(id,name,size,createdTime,appProperties)',
    );

    final files = response.files ?? const <drive.File>[];
    return files
        .where((file) => file.id != null)
        .map(_toBackupDriveFile)
        .toList(growable: false);
  }

  Future<File> downloadBackup({
    required String fileId,
    required Directory outputDirectory,
    String? fileName,
  }) async {
    final api = await _requireDriveApi();
    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }

    final media =
        await api.files.get(
              fileId,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;

    final outputFile = File(
      path.join(outputDirectory.path, fileName ?? '$fileId.cvbackup'),
    );
    final sink = outputFile.openWrite();
    try {
      await media.stream.pipe(sink);
    } finally {
      await sink.close();
    }
    return outputFile;
  }

  Future<void> deleteBackup(String fileId) async {
    final api = await _requireDriveApi();
    await api.files.delete(fileId);
  }

  Future<void> pruneOldBackups({int keepLatest = 5}) async {
    if (keepLatest < 1) return;
    final backups = await listBackups();
    for (final backup in backups.skip(keepLatest)) {
      await deleteBackup(backup.id);
    }
  }

  Future<drive.DriveApi> _requireDriveApi() async {
    if (_driveApi != null) return _driveApi!;
    final account =
        _signInClient.currentUser ?? await _signInClient.signInSilently();
    if (account == null) {
      throw StateError('Google Drive is not connected');
    }
    final connected = await _authorizeAndSetAccount(
      account,
      requestScopes: false,
    );
    if (connected == null) {
      throw StateError('Google Drive authorization is required');
    }
    return _driveApi!;
  }

  Future<BackupAccountInfo?> _authorizeAndSetAccount(
    GoogleDriveAccount account, {
    required bool requestScopes,
  }) async {
    if (requestScopes) {
      final granted = await _signInClient.requestScopes(const [driveScope]);
      if (!granted) {
        _driveApi = null;
        _currentAccount = null;
        return null;
      }
    }

    final headers = await _signInClient.authHeadersFor(account);
    _driveApi = drive.DriveApi(_GoogleAuthClient(headers));
    _currentAccount = BackupAccountInfo(
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
    );
    return _currentAccount;
  }

  BackupDriveFile _toBackupDriveFile(drive.File file) {
    final props = file.appProperties ?? const <String, String>{};
    final createdTime = file.createdTime ?? DateTime.now();
    final size = int.tryParse(file.size ?? '') ?? 0;
    return BackupDriveFile(
      id: file.id!,
      name: file.name ?? file.id!,
      metadata: BackupMetadata(
        id: props['id'] ?? file.id!,
        appVersion: props['appVersion'] ?? 'unknown',
        backupTimestamp:
            DateTime.tryParse(props['backupTimestamp'] ?? '') ?? createdTime,
        deviceInfo: props['deviceInfo'] ?? 'Unknown device',
        schemaVersion: int.tryParse(props['schemaVersion'] ?? '') ?? 0,
        fileCount: int.tryParse(props['fileCount'] ?? '') ?? 0,
        encryptionVersion: int.tryParse(props['encryptionVersion'] ?? '') ?? 1,
        backupSize: int.tryParse(props['backupSize'] ?? '') ?? size,
        deviceName: props['deviceName'],
        notes: props['notes'],
      ),
    );
  }

  static Map<String, String> _metadataProperties(BackupMetadata metadata) {
    return {
      'id': metadata.id,
      'appVersion': metadata.appVersion,
      'backupTimestamp': metadata.backupTimestamp.toUtc().toIso8601String(),
      'deviceInfo': metadata.deviceInfo,
      'schemaVersion': metadata.schemaVersion.toString(),
      'fileCount': metadata.fileCount.toString(),
      'encryptionVersion': metadata.encryptionVersion.toString(),
      'backupSize': metadata.backupSize.toString(),
      if (metadata.deviceName != null) 'deviceName': metadata.deviceName!,
      if (metadata.notes != null) 'notes': metadata.notes!,
    };
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
    super.close();
  }
}
