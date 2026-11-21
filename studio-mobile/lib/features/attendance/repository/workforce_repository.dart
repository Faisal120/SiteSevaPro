import '../models/attendance_models.dart';
import '../models/workforce_models.dart';

abstract interface class WorkforceRepository {
  Future<AttendanceBoardData> fetchAttendance({
    String? siteId,
    required String date,
  });
  Future<AttendanceDocument> saveAttendance(AttendanceDraft draft);
  Future<WorkforceStudioData> fetchWorkforce();
  Future<WorkforceMember> createMember(WorkforceCreationBrief brief);
  Future<void> deleteMember(String labourId);
  Future<WorkforceDetail> fetchDetail(String labourId);
  Future<void> settleWallet(WalletSettlementBrief brief);
  Future<PayrollData> fetchPayroll(String month);
  Future<PayrollRecord> generatePayroll(String labourId, String month);
}
