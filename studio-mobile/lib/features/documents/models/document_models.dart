import 'dart:typed_data';

import '../../sites/models/site_models.dart';

enum DocumentKind {
  drawing('DRAWING', 'Drawings'),
  boq('BOQ', 'BOQ'),
  estimate('ESTIMATE', 'Estimates'),
  agreement('AGREEMENT', 'Agreements'),
  invoice('INVOICE', 'Invoices'),
  bill('BILL', 'Bills'),
  report('REPORT', 'Reports'),
  photo('PHOTO', 'Photos'),
  video('VIDEO', 'Videos'),
  other('OTHER', 'Other');

  const DocumentKind(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static DocumentKind fromApi(Object? value) {
    final normalized = '$value'.trim().toUpperCase().replaceAll('-', '_');
    return switch (normalized) {
      'DRAWING' || 'DRAWINGS' || 'PLAN' => DocumentKind.drawing,
      'BOQ' || 'QUANTITY' || 'QUANTITIES' => DocumentKind.boq,
      'ESTIMATE' || 'ESTIMATES' || 'QUOTATION' => DocumentKind.estimate,
      'AGREEMENT' || 'CONTRACT' => DocumentKind.agreement,
      'INVOICE' || 'INVOICES' => DocumentKind.invoice,
      'BILL' || 'BILLS' || 'VENDOR_BILL' => DocumentKind.bill,
      'REPORT' || 'REPORTS' => DocumentKind.report,
      'PHOTO' || 'PHOTOS' || 'IMAGE' || 'IMAGES' => DocumentKind.photo,
      'VIDEO' || 'VIDEOS' => DocumentKind.video,
      _ => DocumentKind.other,
    };
  }
}

class DocumentRecord {
  const DocumentRecord({
    required this.id,
    required this.name,
    required this.kind,
    required this.siteId,
    required this.siteName,
    required this.url,
    required this.downloadUrl,
    required this.thumbnailUrl,
    required this.mimeType,
    required this.originalFilename,
    required this.sizeBytes,
    required this.version,
    required this.createdBy,
    required this.createdAt,
    required this.sharedWithClient,
    this.description,
    this.publicId,
  });

  factory DocumentRecord.fromJson(Map<String, dynamic> json) => DocumentRecord(
    id: _string(json['id'] ?? json['_id']),
    name: _string(
      json['name'] ??
          json['title'] ??
          json['file_name'] ??
          json['filename'] ??
          json['original_filename'],
    ),
    kind: DocumentKind.fromApi(
      json['kind'] ?? json['type'] ?? json['category'] ?? json['document_type'],
    ),
    siteId: _string(json['site_id']),
    siteName: _string(json['site_name'] ?? json['project_name']),
    url: _string(json['secure_url'] ?? json['url'] ?? json['file_url']),
    downloadUrl: _string(json['download_url'] ?? json['url'] ?? json['file_url']),
    thumbnailUrl: _string(json['thumbnail_url'] ?? json['thumb_url']),
    mimeType: _string(json['mime_type'] ?? json['content_type']),
    originalFilename: _string(
      json['original_filename'] ?? json['filename'] ?? json['file_name'],
    ),
    sizeBytes: _int(json['size_bytes'] ?? json['file_size'] ?? json['bytes']),
    version: _int(json['version'], fallback: 1),
    createdBy: _string(json['created_by_name'] ?? json['uploaded_by_name']),
    createdAt: _date(json['created_at'] ?? json['uploaded_at']),
    sharedWithClient: json['shared_with_client'] == true ||
        json['is_shared'] == true,
    description: _nullableString(json['description']),
    publicId: _nullableString(json['public_id']),
  );

  final String id;
  final String name;
  final DocumentKind kind;
  final String siteId;
  final String siteName;
  final String url;
  final String downloadUrl;
  final String thumbnailUrl;
  final String mimeType;
  final String originalFilename;
  final int sizeBytes;
  final int version;
  final String createdBy;
  final DateTime? createdAt;
  final bool sharedWithClient;
  final String? description;
  final String? publicId;

  bool get isImage =>
      mimeType.startsWith('image/') || kind == DocumentKind.photo;
  bool get isVideo =>
      mimeType.startsWith('video/') || kind == DocumentKind.video;
  bool get isPdf => mimeType == 'application/pdf' || name.toLowerCase().endsWith('.pdf');
  String get fileLabel => originalFilename.isNotEmpty ? originalFilename : name;

  String get sizeLabel {
    if (sizeBytes <= 0) return 'Size unavailable';
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    }
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class DocumentMetrics {
  const DocumentMetrics({
    required this.total,
    required this.shared,
    required this.media,
    required this.projects,
    required this.totalBytes,
  });

  factory DocumentMetrics.fromJson(Map<String, dynamic> json) => DocumentMetrics(
    total: _int(json['total'] ?? json['total_documents']),
    shared: _int(json['shared'] ?? json['shared_documents']),
    media: _int(json['media'] ?? json['media_count']),
    projects: _int(json['projects'] ?? json['project_count']),
    totalBytes: _int(json['total_bytes'] ?? json['storage_bytes']),
  );

  final int total;
  final int shared;
  final int media;
  final int projects;
  final int totalBytes;

  DocumentMetrics fromDocuments(List<DocumentRecord> documents) {
    final mediaCount = documents
        .where((document) => document.isImage || document.isVideo)
        .length;
    return DocumentMetrics(
      total: documents.length,
      shared: documents.where((document) => document.sharedWithClient).length,
      media: mediaCount,
      projects: documents.map((document) => document.siteId).where((id) => id.isNotEmpty).toSet().length,
      totalBytes: documents.fold(0, (sum, document) => sum + document.sizeBytes),
    );
  }
}

class DocumentsWorkspaceData {
  const DocumentsWorkspaceData({
    required this.documents,
    required this.sites,
    required this.metrics,
    required this.fetchedAt,
    this.query = '',
    this.kind,
    this.siteId,
    this.isOffline = false,
    this.apiAvailable = true,
    this.apiMessage,
  });

  factory DocumentsWorkspaceData.fromJson(
    Map<String, dynamic> json, {
    DateTime? fetchedAt,
    bool isOffline = false,
  }) {
    final documents = _maps(
      json['documents'] ?? json['files'] ?? json['items'],
    ).map(DocumentRecord.fromJson).where((document) => document.id.isNotEmpty).toList(growable: false);
    final sites = _maps(json['sites'])
        .map(SiteSummary.fromJson)
        .where((site) => site.id.isNotEmpty)
        .toList(growable: false);
    final parsedMetrics = DocumentMetrics.fromJson(_map(json['metrics']));
    return DocumentsWorkspaceData(
      documents: documents,
      sites: sites,
      metrics: parsedMetrics.total == 0 && documents.isNotEmpty
          ? parsedMetrics.fromDocuments(documents)
          : parsedMetrics,
      fetchedAt: fetchedAt ?? DateTime.now(),
      isOffline: isOffline,
    );
  }

  factory DocumentsWorkspaceData.unavailable({required DateTime fetchedAt}) =>
      DocumentsWorkspaceData(
        documents: const [],
        sites: const [],
        metrics: const DocumentMetrics(
          total: 0,
          shared: 0,
          media: 0,
          projects: 0,
          totalBytes: 0,
        ),
        fetchedAt: fetchedAt,
        apiAvailable: false,
        apiMessage:
            'Document Center endpoints are not enabled in the connected FastAPI backend yet.',
      );

  final List<DocumentRecord> documents;
  final List<SiteSummary> sites;
  final DocumentMetrics metrics;
  final DateTime fetchedAt;
  final String query;
  final DocumentKind? kind;
  final String? siteId;
  final bool isOffline;
  final bool apiAvailable;
  final String? apiMessage;

  List<DocumentRecord> get visibleDocuments {
    final normalized = query.trim().toLowerCase();
    return documents.where((document) {
      if (kind != null && document.kind != kind) return false;
      if (siteId != null && siteId!.isNotEmpty && document.siteId != siteId) {
        return false;
      }
      if (normalized.isEmpty) return true;
      return [
        document.name,
        document.fileLabel,
        document.siteName,
        document.createdBy,
        document.kind.label,
      ].join(' ').toLowerCase().contains(normalized);
    }).toList(growable: false);
  }

  String siteName(String id) => sites
      .where((site) => site.id == id)
      .map((site) => site.name)
      .firstOrNull ??
      '';

  DocumentsWorkspaceData copyWith({
    String? query,
    DocumentKind? kind,
    bool clearKind = false,
    String? siteId,
    bool clearSite = false,
    bool? isOffline,
  }) => DocumentsWorkspaceData(
    documents: documents,
    sites: sites,
    metrics: metrics,
    fetchedAt: fetchedAt,
    query: query ?? this.query,
    kind: clearKind ? null : kind ?? this.kind,
    siteId: clearSite ? null : siteId ?? this.siteId,
    isOffline: isOffline ?? this.isOffline,
    apiAvailable: apiAvailable,
    apiMessage: apiMessage,
  );
}

class DocumentUploadInput {
  const DocumentUploadInput({
    required this.name,
    required this.kind,
    required this.siteId,
    required this.description,
    required this.sharedWithClient,
  });

  final String name;
  final DocumentKind kind;
  final String siteId;
  final String description;
  final bool sharedWithClient;

  String? validationMessage({required DocumentFileAsset asset}) {
    if (name.trim().isEmpty) return 'Enter a file name.';
    if (kind == DocumentKind.other && asset.extension.isEmpty) {
      return 'Choose a supported file type.';
    }
    final assetError = asset.validationMessage;
    if (assetError != null) return assetError;
    return null;
  }

  Map<String, dynamic> toJson({required Map<String, dynamic> uploaded}) => {
    'name': name.trim(),
    'kind': kind.apiValue,
    'site_id': siteId.isEmpty ? null : siteId,
    'description': description.trim().isEmpty ? null : description.trim(),
    'shared_with_client': sharedWithClient,
    'url': uploaded['secure_url'] ?? uploaded['url'],
    'secure_url': uploaded['secure_url'] ?? uploaded['url'],
    'public_id': uploaded['public_id'],
    'resource_type': uploaded['resource_type'],
    'mime_type': uploaded['mime_type'],
    'original_filename': uploaded['original_filename'],
    'size_bytes': uploaded['bytes'],
  };
}

class DocumentFileAsset {
  const DocumentFileAsset({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;

  String get extension {
    final name = filename.toLowerCase();
    final dot = name.lastIndexOf('.');
    return dot == -1 ? '' : name.substring(dot + 1);
  }

  String get resourceType => switch (extension) {
    'jpg' || 'jpeg' || 'png' || 'webp' || 'heic' || 'gif' => 'image',
    'mp4' || 'mov' || 'm4v' || 'webm' => 'video',
    _ => 'raw',
  };

  String get mimeType => switch (extension) {
    'pdf' => 'application/pdf',
    'doc' => 'application/msword',
    'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls' => 'application/vnd.ms-excel',
    'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'csv' => 'text/csv',
    'ppt' => 'application/vnd.ms-powerpoint',
    'pptx' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'dwg' || 'dxf' => 'application/acad',
    'svg' => 'image/svg+xml',
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    'gif' => 'image/gif',
    'mp4' => 'video/mp4',
    'mov' || 'm4v' => 'video/quicktime',
    'webm' => 'video/webm',
    _ => 'application/octet-stream',
  };

  String? get validationMessage {
    if (bytes.isEmpty) return 'The selected file is empty.';
    if (bytes.lengthInBytes > 100 * 1024 * 1024) {
      return 'Choose a file smaller than 100 MB.';
    }
    const allowed = {
      'pdf',
      'doc',
      'docx',
      'xls',
      'xlsx',
      'csv',
      'ppt',
      'pptx',
      'dwg',
      'dxf',
      'svg',
      'jpg',
      'jpeg',
      'png',
      'webp',
      'heic',
      'gif',
      'mp4',
      'mov',
      'm4v',
      'webm',
    };
    if (!allowed.contains(extension)) {
      return 'Supported files: PDF, Office, CAD, SVG, images, and video.';
    }
    return null;
  }
}

class DocumentPermissions {
  const DocumentPermissions({required this.role});

  final String role;

  bool get isContractor => role.trim().toUpperCase() == 'CONTRACTOR';
  bool get isSupervisor => role.trim().toUpperCase() == 'SUPERVISOR';
  bool get canUpload => isContractor || isSupervisor;
  bool get canDelete => isContractor;
  bool get canShare => isContractor;
}

Map<String, dynamic> _map(Object? value) => value is Map
    ? Map<String, dynamic>.from(value)
    : <String, dynamic>{};

List<Map<String, dynamic>> _maps(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false)
    : const [];

String _string(Object? value) => value == null ? '' : '$value'.trim();

String? _nullableString(Object? value) {
  final result = _string(value);
  return result.isEmpty ? null : result;
}

int _int(Object? value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}

DateTime? _date(Object? value) => value == null
    ? null
    : DateTime.tryParse('$value')?.toLocal();
