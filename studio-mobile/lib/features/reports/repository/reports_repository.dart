import '../models/report_models.dart';

abstract interface class ReportsRepository {
  Future<ReportsStudioData> fetchStudio();
  Future<DailyReport> createReport(DailyReportBrief brief);
  Future<ReportMedia> uploadPhoto(ReportPhotoUpload upload);
}
