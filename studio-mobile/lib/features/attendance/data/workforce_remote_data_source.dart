import '../../../core/network/api_service.dart';

abstract interface class WorkforceRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchSites();
  Future<List<Map<String, dynamic>>> fetchLabour({String? siteId});
  Future<Map<String, dynamic>> createLabour(Map<String, dynamic> payload);
  Future<void> deleteLabour(String labourId);
  Future<Map<String, dynamic>> fetchAttendanceDay({
    required String siteId,
    required String date,
  });
  Future<List<Map<String, dynamic>>> fetchAttendanceHistory(String siteId);
  Future<Map<String, dynamic>> markAttendance(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> fetchWalletSummary({String? siteId});
  Future<Map<String, dynamic>> fetchWorkforceDetail(String labourId);
  Future<Map<String, dynamic>> settleWallet(Map<String, dynamic> payload);
  Future<List<Map<String, dynamic>>> fetchPayroll(String month);
  Future<Map<String, dynamic>> generatePayroll(String labourId, String month);
}

class HttpWorkforceRemoteDataSource implements WorkforceRemoteDataSource {
  const HttpWorkforceRemoteDataSource();

  @override
  Future<Map<String, dynamic>> createLabour(Map<String, dynamic> payload) =>
      ApiService.createLabour(payload);

  @override
  Future<void> deleteLabour(String labourId) =>
      ApiService.deleteLabour(labourId);

  @override
  Future<Map<String, dynamic>> fetchAttendanceDay({
    required String siteId,
    required String date,
  }) => ApiService.getAttendanceDay(siteId: siteId, date: date);

  @override
  Future<List<Map<String, dynamic>>> fetchAttendanceHistory(String siteId) =>
      ApiService.getAttendanceHistory(siteId);

  @override
  Future<List<Map<String, dynamic>>> fetchLabour({String? siteId}) =>
      ApiService.getLabour(siteId: siteId);

  @override
  Future<List<Map<String, dynamic>>> fetchPayroll(String month) =>
      ApiService.getPayrollSummary(month);

  @override
  Future<List<Map<String, dynamic>>> fetchSites() => ApiService.getSites();

  @override
  Future<Map<String, dynamic>> fetchWalletSummary({String? siteId}) =>
      ApiService.getWalletSummary(siteId: siteId);

  @override
  Future<Map<String, dynamic>> fetchWorkforceDetail(String labourId) =>
      ApiService.getWorkforceDetail(labourId);

  @override
  Future<Map<String, dynamic>> generatePayroll(String labourId, String month) =>
      ApiService.generatePayroll(labourId, month);

  @override
  Future<Map<String, dynamic>> markAttendance(Map<String, dynamic> payload) =>
      ApiService.markAttendance(payload);

  @override
  Future<Map<String, dynamic>> settleWallet(Map<String, dynamic> payload) =>
      ApiService.settleWallet(payload);
}
