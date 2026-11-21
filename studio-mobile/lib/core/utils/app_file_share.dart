import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

abstract final class AppFileShare {
  static Future<void> bytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String subject,
  }) => Share.shareXFiles([
    XFile.fromData(bytes, mimeType: mimeType, name: fileName),
  ], subject: subject);
}
