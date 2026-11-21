import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/features/documents/models/document_models.dart';

void main() {
  group('Document models', () {
    test('parses file records and derives workspace metrics', () {
      final data = DocumentsWorkspaceData.fromJson({
        'sites': [
          {'id': 'site-1', 'name': 'Orchid Residence', 'status': 'ACTIVE'},
        ],
        'documents': [
          {
            'id': 'doc-1',
            'title': 'Electrical drawing',
            'type': 'DRAWING',
            'site_id': 'site-1',
            'site_name': 'Orchid Residence',
            'original_filename': 'electrical.pdf',
            'mime_type': 'application/pdf',
            'size_bytes': 2048,
            'shared_with_client': true,
            'created_at': '2026-08-08T09:00:00Z',
          },
          {
            'id': 'doc-2',
            'name': 'Site photo',
            'kind': 'PHOTO',
            'site_id': 'site-1',
            'url': 'https://cdn.example/photo.jpg',
            'mime_type': 'image/jpeg',
            'size_bytes': 4096,
          },
        ],
      });

      expect(data.documents, hasLength(2));
      expect(data.documents.first.kind, DocumentKind.drawing);
      expect(data.documents.first.isPdf, isTrue);
      expect(data.documents.first.sharedWithClient, isTrue);
      expect(data.metrics.total, 2);
      expect(data.metrics.shared, 1);
      expect(data.metrics.media, 1);
      expect(data.metrics.projects, 1);
      expect(data.metrics.totalBytes, 6144);
    });

    test('filters by project, kind and query without changing server records', () {
      final data = DocumentsWorkspaceData.fromJson({
        'documents': [
          {
            'id': 'doc-1',
            'name': 'Foundation BOQ',
            'kind': 'BOQ',
            'site_id': 'site-1',
            'site_name': 'Orchid Residence',
          },
          {
            'id': 'doc-2',
            'name': 'Client agreement',
            'kind': 'AGREEMENT',
            'site_id': 'site-2',
            'site_name': 'Palm Villa',
          },
        ],
      });

      expect(data.copyWith(kind: DocumentKind.boq).visibleDocuments.single.id, 'doc-1');
      expect(data.copyWith(siteId: 'site-2').visibleDocuments.single.id, 'doc-2');
      expect(data.copyWith(query: 'palm').visibleDocuments.single.id, 'doc-2');
      expect(data.copyWith(query: 'missing').visibleDocuments, isEmpty);
    });

    test('validates supported uploads and keeps role permissions narrow', () {
      final pdf = DocumentFileAsset(
        bytes: Uint8List.fromList([1, 2, 3]),
        filename: 'drawing.pdf',
      );
      const input = DocumentUploadInput(
        name: 'Issued drawing',
        kind: DocumentKind.drawing,
        siteId: 'site-1',
        description: '',
        sharedWithClient: false,
      );

      expect(pdf.resourceType, 'raw');
      expect(pdf.mimeType, 'application/pdf');
      expect(input.validationMessage(asset: pdf), isNull);
      expect(
        DocumentFileAsset(
          bytes: Uint8List.fromList([1]),
          filename: 'unsupported.exe',
        ).validationMessage,
        isNotNull,
      );
      expect(DocumentPermissions(role: 'CONTRACTOR').canDelete, isTrue);
      expect(DocumentPermissions(role: 'SUPERVISOR').canUpload, isTrue);
      expect(DocumentPermissions(role: 'SUPERVISOR').canDelete, isFalse);
      expect(DocumentPermissions(role: 'CLIENT').canUpload, isFalse);
    });

    test('represents missing backend routes explicitly', () {
      final data = DocumentsWorkspaceData.unavailable(
        fetchedAt: DateTime(2026, 8, 8),
      );

      expect(data.apiAvailable, isFalse);
      expect(data.visibleDocuments, isEmpty);
      expect(data.apiMessage, contains('not enabled'));
    });
  });
}
