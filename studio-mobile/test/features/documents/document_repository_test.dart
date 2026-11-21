import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/core/network/api_service.dart';
import 'package:siteseva/features/documents/data/document_cache.dart';
import 'package:siteseva/features/documents/data/document_remote_data_source.dart';
import 'package:siteseva/features/documents/data/document_repository_impl.dart';
import 'package:siteseva/features/documents/models/document_models.dart';

void main() {
  group('DocumentRepositoryImpl', () {
    test('loads and caches live document metadata', () async {
      final cache = _MemoryDocumentCache();
      final repository = _repository(
        remote: _FakeDocumentRemote(),
        cache: cache,
      );

      final data = await repository.fetchWorkspace();

      expect(data.documents.single.id, 'doc-1');
      expect(cache.values['user-1'], isNotNull);
    });

    test('returns explicit unavailable state when registry route is missing', () async {
      final data = await _repository(
        remote: _FakeDocumentRemote(
          error: const ApiException('not found', statusCode: 404),
        ),
        cache: _MemoryDocumentCache(),
      ).fetchWorkspace();

      expect(data.apiAvailable, isFalse);
      expect(data.apiMessage, contains('not enabled'));
    });

    test('uses only real cached data for connectivity failures', () async {
      final cache = _MemoryDocumentCache()
        ..values['user-1'] = CachedDocumentsWorkspace(
          payload: _payload,
          cachedAt: DateTime(2026, 8, 7, 18),
        );
      final data = await _repository(
        remote: _FakeDocumentRemote(
          error: const ApiException('offline', kind: ApiErrorKind.network),
        ),
        cache: cache,
      ).fetchWorkspace();

      expect(data.isOffline, isTrue);
      expect(data.documents.single.id, 'doc-1');
      expect(data.fetchedAt, DateTime(2026, 8, 7, 18));
    });

    test('enforces role mutation boundaries and forwards uploads', () async {
      final remote = _FakeDocumentRemote();
      final contractor = _repository(remote: remote, cache: _MemoryDocumentCache());
      final supervisor = _repository(
        remote: remote,
        cache: _MemoryDocumentCache(),
        role: 'SUPERVISOR',
      );
      final asset = DocumentFileAsset(
        bytes: Uint8List.fromList([1, 2, 3]),
        filename: 'site-photo.jpg',
      );
      const input = DocumentUploadInput(
        name: 'Site photo',
        kind: DocumentKind.photo,
        siteId: 'site-1',
        description: 'Progress evidence',
        sharedWithClient: false,
      );

      await contractor.upload(asset, input);
      await supervisor.upload(asset, input);

      expect(remote.uploadCount, 2);
      expect(contractor.delete('doc-1'), completes);
      expect(supervisor.delete('doc-1'), throwsA(isA<ApiException>()));
      expect(supervisor.updateSharing('doc-1', true), throwsA(isA<ApiException>()));
    });

    test('downloads only through the authorized document route', () async {
      final repository = _repository(
        remote: _FakeDocumentRemote(),
        cache: _MemoryDocumentCache(),
      );
      final bytes = await repository.download(
        DocumentRecord.fromJson({'id': 'doc-1', 'name': 'Drawing'}),
      );

      expect(bytes, Uint8List.fromList([4, 5, 6]));
    });
  });
}

DocumentRepositoryImpl _repository({
  required DocumentRemoteDataSource remote,
  required DocumentCache cache,
  String role = 'CONTRACTOR',
}) => DocumentRepositoryImpl(
  remote: remote,
  cache: cache,
  userId: 'user-1',
  role: role,
);

class _FakeDocumentRemote implements DocumentRemoteDataSource {
  _FakeDocumentRemote({this.error});

  final ApiException? error;
  int uploadCount = 0;

  void _throwIfNeeded() {
    if (error != null) throw error!;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSites() async {
    _throwIfNeeded();
    return [
      {'id': 'site-1', 'name': 'Orchid Residence', 'status': 'ACTIVE'},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchDocuments() async {
    _throwIfNeeded();
    return [_documentPayload];
  }

  @override
  Future<Map<String, dynamic>> uploadDocument(
    DocumentFileAsset asset,
    DocumentUploadInput input,
  ) async {
    _throwIfNeeded();
    uploadCount++;
    return _documentPayload;
  }

  @override
  Future<void> deleteDocument(String id) async {
    _throwIfNeeded();
  }

  @override
  Future<void> updateSharing(String id, bool sharedWithClient) async {
    _throwIfNeeded();
  }

  @override
  Future<Uint8List> downloadDocument(String id) async {
    _throwIfNeeded();
    return Uint8List.fromList([4, 5, 6]);
  }
}

class _MemoryDocumentCache implements DocumentCache {
  final values = <String, CachedDocumentsWorkspace>{};

  @override
  Future<CachedDocumentsWorkspace?> read(String userId) async => values[userId];

  @override
  Future<void> write(String userId, Map<String, dynamic> payload) async {
    values[userId] = CachedDocumentsWorkspace(
      payload: payload,
      cachedAt: DateTime(2026, 8, 8),
    );
  }
}

const _documentPayload = <String, dynamic>{
  'id': 'doc-1',
  'name': 'Issued site drawing',
  'kind': 'DRAWING',
  'site_id': 'site-1',
  'site_name': 'Orchid Residence',
  'mime_type': 'application/pdf',
  'size_bytes': 1024,
  'created_at': '2026-08-08T09:00:00Z',
};

const _payload = <String, dynamic>{
  'sites': [
    {'id': 'site-1', 'name': 'Orchid Residence', 'status': 'ACTIVE'},
  ],
  'documents': [_documentPayload],
};
