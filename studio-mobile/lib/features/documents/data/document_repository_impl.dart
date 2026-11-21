import 'dart:typed_data';

import '../../../core/network/api_service.dart';
import '../models/document_models.dart';
import '../repository/document_repository.dart';
import 'document_cache.dart';
import 'document_remote_data_source.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  DocumentRepositoryImpl({
    required DocumentRemoteDataSource remote,
    required DocumentCache cache,
    required String userId,
    required String role,
  }) : _remote = remote,
       _cache = cache,
       _userId = userId,
       _permissions = DocumentPermissions(role: role);

  final DocumentRemoteDataSource _remote;
  final DocumentCache _cache;
  final String _userId;
  final DocumentPermissions _permissions;

  @override
  Future<DocumentsWorkspaceData> fetchWorkspace() async {
    try {
      final results = await Future.wait<Object>([
        _remote.fetchSites(),
        _remote.fetchDocuments(),
      ]);
      final payload = <String, dynamic>{
        'sites': results[0],
        'documents': results[1],
      };
      await _cache.write(_userId, payload);
      return DocumentsWorkspaceData.fromJson(payload);
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        return DocumentsWorkspaceData.unavailable(fetchedAt: DateTime.now());
      }
      if (!error.isConnectivityFailure) rethrow;
      final cached = await _cache.read(_userId);
      if (cached == null) rethrow;
      return DocumentsWorkspaceData.fromJson(
        cached.payload,
        fetchedAt: cached.cachedAt,
        isOffline: true,
      );
    }
  }

  @override
  Future<DocumentRecord> upload(
    DocumentFileAsset asset,
    DocumentUploadInput input,
  ) async {
    _require(_permissions.canUpload, 'Your role cannot upload documents.');
    final validation = input.validationMessage(asset: asset);
    if (validation != null) _invalid(validation);
    final record = DocumentRecord.fromJson(
      await _remote.uploadDocument(asset, input),
    );
    if (record.id.isEmpty) {
      _invalid('The document service did not return a document id.');
    }
    return record;
  }

  @override
  Future<void> delete(String id) async {
    _require(_permissions.canDelete, 'Only contractors can delete documents.');
    _requireId(id);
    await _remote.deleteDocument(id);
  }

  @override
  Future<void> updateSharing(String id, bool sharedWithClient) async {
    _require(_permissions.canShare, 'Only contractors can change sharing.');
    _requireId(id);
    await _remote.updateSharing(id, sharedWithClient);
  }

  @override
  Future<Uint8List> download(DocumentRecord document) async {
    _requireId(document.id);
    return _remote.downloadDocument(document.id);
  }

  void _require(bool allowed, String message) {
    if (!allowed) {
      throw ApiException(
        message,
        statusCode: 403,
        kind: ApiErrorKind.authentication,
      );
    }
  }

  void _requireId(String id) {
    if (id.trim().isEmpty) {
      _invalid('Document is unavailable.');
    }
  }

  Never _invalid(String message) => throw ApiException(
    message,
    statusCode: 422,
    kind: ApiErrorKind.invalidResponse,
  );
}
