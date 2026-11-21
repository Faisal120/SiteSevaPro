import 'dart:typed_data';

import '../models/document_models.dart';

abstract interface class DocumentRepository {
  Future<DocumentsWorkspaceData> fetchWorkspace();
  Future<DocumentRecord> upload(
    DocumentFileAsset asset,
    DocumentUploadInput input,
  );
  Future<void> delete(String id);
  Future<void> updateSharing(String id, bool sharedWithClient);
  Future<Uint8List> download(DocumentRecord document);
}
