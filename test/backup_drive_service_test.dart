import 'package:carevault/core/services/backup/backup_drive_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGoogleDriveSignInClient implements GoogleDriveSignInClient {
  _FakeGoogleDriveSignInClient({
    this.signInAccount,
    this.silentAccount,
    this.scopesGranted = true,
    this.throwAuthError = false,
    this.throwScopeError = false,
  });

  final GoogleDriveAccount? signInAccount;
  final GoogleDriveAccount? silentAccount;
  final bool scopesGranted;
  final bool throwAuthError;
  final bool throwScopeError;
  final requestedScopes = <String>[];

  GoogleDriveAccount? _currentUser;
  int signOutCount = 0;

  @override
  GoogleDriveAccount? get currentUser => _currentUser;

  @override
  Future<Map<String, String>> authHeadersFor(GoogleDriveAccount account) async {
    if (throwAuthError) {
      throw StateError('auth failed');
    }
    return {'Authorization': 'Bearer ${account.email}'};
  }

  @override
  Future<bool> requestScopes(List<String> scopes) async {
    if (throwScopeError) {
      throw StateError('scope failed');
    }
    requestedScopes.addAll(scopes);
    return scopesGranted;
  }

  @override
  Future<GoogleDriveAccount?> signIn() async {
    _currentUser = signInAccount;
    return signInAccount;
  }

  @override
  Future<GoogleDriveAccount?> signInSilently() async {
    _currentUser = silentAccount;
    return silentAccount;
  }

  @override
  Future<void> signOut() async {
    signOutCount += 1;
    _currentUser = null;
  }
}

void main() {
  group('BackupDriveService', () {
    test('does not connect when Drive appdata scope is denied', () async {
      final signInClient = _FakeGoogleDriveSignInClient(
        signInAccount: const GoogleDriveAccount(email: 'user@example.com'),
        scopesGranted: false,
      );
      final service = BackupDriveService(signInClient: signInClient);

      final account = await service.signIn();

      expect(account, isNull);
      expect(service.currentAccount, isNull);
      expect(
        signInClient.requestedScopes,
        contains(BackupDriveService.driveScope),
      );
    });

    test(
      'connects when account selection and Drive scope authorization succeed',
      () async {
        final signInClient = _FakeGoogleDriveSignInClient(
          signInAccount: const GoogleDriveAccount(
            email: 'user@example.com',
            displayName: 'User',
            photoUrl: 'https://example.com/user.png',
          ),
        );
        final service = BackupDriveService(signInClient: signInClient);

        final account = await service.signIn();

        expect(account?.email, 'user@example.com');
        expect(account?.displayName, 'User');
        expect(account?.photoUrl, 'https://example.com/user.png');
        expect(service.currentAccount?.email, 'user@example.com');
        expect(
          signInClient.requestedScopes,
          contains(BackupDriveService.driveScope),
        );
      },
    );

    test(
      'does not restore a stale sign-in when auth headers are unavailable',
      () async {
        final signInClient = _FakeGoogleDriveSignInClient(
          silentAccount: const GoogleDriveAccount(email: 'user@example.com'),
          throwAuthError: true,
        );
        final service = BackupDriveService(signInClient: signInClient);

        final account = await service.restorePreviousSignIn();

        expect(account, isNull);
        expect(service.currentAccount, isNull);
      },
    );

    test('does not connect when Drive scope authorization fails', () async {
      final signInClient = _FakeGoogleDriveSignInClient(
        signInAccount: const GoogleDriveAccount(email: 'user@example.com'),
        throwScopeError: true,
      );
      final service = BackupDriveService(signInClient: signInClient);

      final account = await service.signIn();

      expect(account, isNull);
      expect(service.currentAccount, isNull);
    });
  });
}
