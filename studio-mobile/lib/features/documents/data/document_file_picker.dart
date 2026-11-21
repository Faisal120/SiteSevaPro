import 'package:file_picker/file_picker.dart';

import '../models/document_models.dart';

abstract interface class DocumentFilePicker {
  Future<List<DocumentFileAsset>> pickFiles();
}

class DeviceDocumentFilePicker implements DocumentFilePicker {
  const DeviceDocumentFilePicker();

  @override
  Future<List<DocumentFileAsset>> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const [
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
      ],
    );
    if (result == null) return const [];
    final assets = <DocumentFileAsset>[];
    for (final file in result.files) {
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) continue;
      assets.add(
        DocumentFileAsset(bytes: bytes, filename: file.name),
      );
    }
    return assets;
  }
}
