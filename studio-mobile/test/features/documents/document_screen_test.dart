import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/core/theme/app_theme.dart';
import 'package:siteseva/features/auth/models/auth_user.dart';
import 'package:siteseva/features/auth/models/contractor_application.dart';
import 'package:siteseva/features/auth/providers/auth_provider.dart';
import 'package:siteseva/features/auth/repository/auth_repository.dart';
import 'package:siteseva/features/documents/models/document_models.dart';
import 'package:siteseva/features/documents/presentation/screens/document_center_screen.dart';
import 'package:siteseva/features/documents/providers/document_provider.dart';
import 'package:siteseva/features/documents/repository/document_repository.dart';

void main() {
  testWidgets('mobile client sees an honest unavailable document state', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(390, 844),
      user: _client,
      data: DocumentsWorkspaceData.unavailable(
        fetchedAt: DateTime(2026, 8, 8),
      ),
    );

    expect(find.text('Document Center'), findsOneWidget);
    expect(find.text('Document service not connected'), findsOneWidget);
    expect(find.text('Awaiting Document API'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Upload'), findsNothing);
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.takeException(), isNull);
  });

  testWidgets('contractor sees live files and upload action responsively', (
    tester,
  ) async {
    final data = DocumentsWorkspaceData.fromJson({
      'sites': [
        {'id': 'site-1', 'name': 'Orchid Residence', 'status': 'ACTIVE'},
      ],
      'documents': [
        {
          'id': 'doc-1',
          'name': 'Issued structural drawing',
          'kind': 'DRAWING',
          'site_id': 'site-1',
          'site_name': 'Orchid Residence',
          'mime_type': 'application/pdf',
          'size_bytes': 1024,
        },
      ],
    });
    await _pump(
      tester,
      size: const Size(1440, 1000),
      user: _contractor,
      data: data,
    );

    expect(find.text('Issued structural drawing'), findsOneWidget);
    expect(find.text('Orchid Residence'), findsOneWidget);
    expect(find.text('Upload'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required AuthUser user,
  required DocumentsWorkspaceData data,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repository = _FakeDocumentRepository(data);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          (ref) => _AuthenticatedController(user),
        ),
        documentRepositoryProvider.overrideWithValue(repository),
        documentControllerProvider.overrideWith(
          (ref) => _LoadedDocumentController(data, repository),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const DocumentCenterScreen(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));
}

const _contractor = AuthUser(
  id: 'contractor-1',
  email: 'contractor@siteseva.test',
  fullName: 'Aarav Mehta',
  role: 'CONTRACTOR',
  siteIds: ['site-1'],
  blocked: false,
);

const _client = AuthUser(
  id: 'client-1',
  email: 'client@siteseva.test',
  fullName: 'Neha Sharma',
  role: 'CLIENT',
  siteIds: ['site-1'],
  blocked: false,
);

class _LoadedDocumentController extends DocumentController {
  _LoadedDocumentController(
    DocumentsWorkspaceData data,
    DocumentRepository repository,
  ) : super(repository) {
    state = AsyncValue.data(data);
  }
}

class _AuthenticatedController extends AuthController {
  _AuthenticatedController(AuthUser user) : super(_FakeAuthRepository()) {
    state = AsyncValue.data(user);
  }
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthUser?> restoreSession() async => null;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
    required bool rememberSession,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<ContractorApplication> submitApplication(
    ContractorApplicationInput application,
  ) => throw UnimplementedError();
}

class _FakeDocumentRepository implements DocumentRepository {
  _FakeDocumentRepository(this.data);

  final DocumentsWorkspaceData data;

  @override
  Future<DocumentsWorkspaceData> fetchWorkspace() async => data;

  @override
  Future<DocumentRecord> upload(
    DocumentFileAsset asset,
    DocumentUploadInput input,
  ) => throw UnimplementedError();

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> updateSharing(String id, bool sharedWithClient) async {}

  @override
  Future<Uint8List> download(DocumentRecord document) =>
      throw UnimplementedError();
}
