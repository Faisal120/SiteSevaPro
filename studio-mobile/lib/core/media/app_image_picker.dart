import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class AppImageAsset {
  const AppImageAsset({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;

  String? get validationMessage {
    if (bytes.isEmpty) return 'The selected image is empty.';
    if (bytes.lengthInBytes > 10 * 1024 * 1024) {
      return 'Choose an image smaller than 10 MB.';
    }
    final normalized = filename.toLowerCase();
    if (!normalized.endsWith('.jpg') &&
        !normalized.endsWith('.jpeg') &&
        !normalized.endsWith('.png') &&
        !normalized.endsWith('.webp') &&
        !normalized.endsWith('.heic')) {
      return 'Choose a JPG, PNG, WEBP, or HEIC image.';
    }
    return null;
  }
}

abstract interface class AppImagePicker {
  Future<List<AppImageAsset>> pickGallery({int limit = 8});
  Future<AppImageAsset?> pickCamera();
  Future<List<AppImageAsset>> recoverInterruptedSelection();
}

class DeviceAppImagePicker implements AppImagePicker {
  DeviceAppImagePicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<List<AppImageAsset>> pickGallery({int limit = 8}) async => _assets(
    await _picker.pickMultiImage(
      imageQuality: 84,
      maxWidth: 2200,
      maxHeight: 2200,
      limit: limit,
    ),
  );

  @override
  Future<AppImageAsset?> pickCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 84,
      maxWidth: 2200,
      maxHeight: 2200,
    );
    if (file == null) return null;
    return (await _assets([file])).single;
  }

  @override
  Future<List<AppImageAsset>> recoverInterruptedSelection() async {
    final response = await _picker.retrieveLostData();
    if (response.isEmpty) return const [];
    return _assets(response.files ?? const []);
  }

  Future<List<AppImageAsset>> _assets(List<XFile> files) async {
    final assets = <AppImageAsset>[];
    for (final file in files) {
      var filename = file.name.trim();
      if (!filename.contains('.')) filename = '$filename.jpg';
      assets.add(
        AppImageAsset(bytes: await file.readAsBytes(), filename: filename),
      );
    }
    return assets;
  }
}
