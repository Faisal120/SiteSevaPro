import 'dart:typed_data';

import '../../../core/network/api_service.dart';
import '../models/document_models.dart';

abstract interface class DocumentRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchSites();
  Future<List<Map<String, dynamic>>> fetchDocuments();
  Future<Map<String, dynamic>> uploadDocument(
    DocumentFileAsset asset,
    DocumentUploadInput input,
  );
  Future<void> deleteDocument(String id);
  Future<void> updateSharing(String id, bool sharedWithClient);
  Future<Uint8List> downloadDocument(String id);
}

class HttpDocumentRemoteDataSource implements DocumentRemoteDataSource {
  const HttpDocumentRemoteDataSource();

  @override
  Future<List<Map<String, dynamic>>> fetchSites() => ApiService.getSites();

  @override
  Future<List<Map<String, dynamic>>> fetchDocuments() =>
      ApiService.getDocuments();

  @override
  Future<Map<String, dynamic>> uploadDocument(
    DocumentFileAsset asset,
    DocumentUploadInput input,
  ) async {
    final signature = await ApiService.getCloudinarySignature(
      resourceType: asset.resourceType,
      folder: 'siteseva/documents',
    );
    final uploaded = await ApiService.uploadCloudinaryAsset(
      bytes: asset.bytes,
      filename: asset.filename,
      signature: signature,
    );
    final normalized = Map<String, dynamic>.from(uploaded)
      ..putIfAbsent('resource_type', () => asset.resourceType)
      ..putIfAbsent('original_filename', () => asset.filename)
      ..putIfAbsent('bytes', () => asset.bytes.lengthInBytes)
      ..putIfAbsent('mime_type', () => asset.mimeType);
    return ApiService.createDocument(input.toJson(uploaded: normalized));
  }

  @override
  Future<void> deleteDocument(String id) => ApiService.deleteDocument(id);

  @override
  Future<void> updateSharing(String id, bool sharedWithClient) async {
    await ApiService.updateDocument(id, {
      'shared_with_client': sharedWithClient,
    });
  }

  @override
  Future<Uint8List> downloadDocument(String id) =>
      ApiService.downloadDocument(id);
}
