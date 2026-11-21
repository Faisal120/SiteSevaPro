import '../../../core/media/app_image_picker.dart';
import '../models/report_models.dart';

abstract interface class ReportImagePicker {
  Future<List<ReportPhotoUpload>> pickGallery();
  Future<List<ReportPhotoUpload>> pickCamera();
  Future<List<ReportPhotoUpload>> recoverInterruptedSelection();
}

class DeviceReportImagePicker implements ReportImagePicker {
  DeviceReportImagePicker({AppImagePicker? picker})
    : _picker = picker ?? DeviceAppImagePicker();

  final AppImagePicker _picker;

  @override
  Future<List<ReportPhotoUpload>> pickGallery() async {
    return _uploads(await _picker.pickGallery());
  }

  @override
  Future<List<ReportPhotoUpload>> pickCamera() async {
    final file = await _picker.pickCamera();
    return file == null ? const [] : _uploads([file]);
  }

  @override
  Future<List<ReportPhotoUpload>> recoverInterruptedSelection() async {
    return _uploads(await _picker.recoverInterruptedSelection());
  }

  List<ReportPhotoUpload> _uploads(List<AppImageAsset> files) => files
      .map(
        (file) => ReportPhotoUpload(bytes: file.bytes, filename: file.filename),
      )
      .toList(growable: false);
}
