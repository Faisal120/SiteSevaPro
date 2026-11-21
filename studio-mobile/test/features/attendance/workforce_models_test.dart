import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/features/attendance/models/attendance_models.dart';
import 'package:siteseva/features/attendance/models/workforce_models.dart';
import 'package:siteseva/features/sites/models/site_models.dart';

void main() {
  group('Attendance contracts', () {
    test('parses the attendance document map and server metrics', () {
      final document = AttendanceDocument.fromJson(_attendancePayload);

      expect(document.isMarked, isTrue);
      expect(document.presentCount, 1);
      expect(document.halfDayCount, 1);
      expect(document.absentCount, 1);
      expect(document.leaveCount, 1);
      expect(document.checkedInCount, 2);
      expect(document.overtimeHours, 2.5);
      expect(document.advances, 700);
      expect(document.attendanceRate, .5);
    });

    test('builds an immutable exact AttendanceIn payload', () {
      final document = AttendanceDocument.fromJson(_attendancePayload);
      final draft =
          AttendanceDraft.fromBoard(
                siteId: 'site-1',
                date: '2026-08-06',
                members: [_member, _secondMember],
                document: document,
              )
              .updateStatus('labour-1', AttendanceStatus.halfDay)
              .updateOvertime('labour-1', 3)
              .updateAdvance('labour-1', 450);

      expect(draft.validationMessage, isNull);
      expect(draft.entries['labour-1']?.status, AttendanceStatus.halfDay);
      expect(draft.toApiJson(), {
        'site_id': 'site-1',
        'date': '2026-08-06',
        'entries': [
          {
            'labour_id': 'labour-1',
            'status': 'HALF_DAY',
            'overtime_hours': 3.0,
            'advance': 450.0,
          },
          {
            'labour_id': 'labour-2',
            'status': 'HALF_DAY',
            'overtime_hours': 0.0,
            'advance': 0.0,
          },
          {
            'labour_id': 'labour-3',
            'status': 'ABSENT',
            'overtime_hours': 0.0,
            'advance': 0.0,
          },
          {
            'labour_id': 'labour-4',
            'status': 'LEAVE',
            'overtime_hours': 0.0,
            'advance': 250.0,
          },
        ],
      });
    });

    test('rejects invalid overtime and negative advances', () {
      const invalidOvertime = AttendanceDraft(
        siteId: 'site-1',
        date: '2026-08-06',
        entries: {
          'labour-1': AttendanceEntry(
            labourId: 'labour-1',
            status: AttendanceStatus.present,
            overtimeHours: 25,
            advance: 0,
          ),
        },
      );
      final invalidAdvance = invalidOvertime
          .updateOvertime('labour-1', 0)
          .updateAdvance('labour-1', -1);

      expect(invalidOvertime.validationMessage, contains('0 and 24'));
      expect(invalidAdvance.validationMessage, contains('cannot be negative'));
    });

    test('formats API dates without locale ambiguity', () {
      expect(attendanceApiDate(DateTime(2026, 2, 3)), '2026-02-03');
    });
  });

  group('Workforce and payroll contracts', () {
    test('validates and serializes only LabourIn fields', () {
      const brief = WorkforceCreationBrief(
        fullName: '  Ramesh Kumar  ',
        mobile: '9876543210',
        trade: ' Mason ',
        dailyWage: 950,
        siteId: 'site-1',
        aadhaar: '',
        address: 'Sector 57, Gurugram',
      );

      expect(brief.validationMessage, isNull);
      expect(brief.toApiJson(), {
        'full_name': 'Ramesh Kumar',
        'mobile': '9876543210',
        'trade': 'Mason',
        'daily_wage': 950.0,
        'site_id': 'site-1',
        'aadhaar': null,
        'address': 'Sector 57, Gurugram',
      });
      expect(
        brief.copyWith(aadhaar: '1234').validationMessage,
        contains('12 digits'),
      );
    });

    test('normalizes both wallet endpoint schemas', () {
      final current = LabourWallet.fromJson({
        'labour_id': 'labour-1',
        'earned': 12000,
        'paid': 6000,
        'advance': 1000,
        'deduction': 250,
        'balance': 4750,
      });
      final summary = LabourWallet.fromJson({
        'labour_id': 'labour-1',
        'total_earned': '12000',
        'total_paid': '6000',
        'balance': '6000',
      });

      expect(current.earned, 12000);
      expect(current.totalOutflow, 7250);
      expect(summary.earned, 12000);
      expect(summary.paid, 6000);
    });

    test('filters real workforce data by site and searchable context', () {
      final data = WorkforceStudioData(
        members: [_member, _secondMember],
        sites: [_site, _secondSite],
        walletSummary: WorkforceWalletSummary.empty(),
        fetchedAt: DateTime(2026, 8, 6),
        query: 'orchid mason',
      );

      expect(data.activeCount, 2);
      expect(data.tradeCount, 2);
      expect(data.dailyWageExposure, 2050);
      expect(data.visibleMembers.single.id, 'labour-1');
      expect(data.copyWith(siteFilter: 'site-2').visibleMembers, isEmpty);
    });

    test('serializes exact settlement and aggregates payroll records', () {
      const settlement = WalletSettlementBrief(
        labourId: 'labour-1',
        amount: 5000,
        paymentMode: LabourPaymentMode.bank,
        remarks: 'August site settlement',
      );
      final payroll = PayrollData(
        month: '2026-08',
        records: [
          PayrollRecord.fromJson(_payrollPayload),
          PayrollRecord.fromJson({
            ..._payrollPayload,
            'id': 'payroll-2',
            'labour_id': 'labour-2',
            'labour_name': 'Suman Devi',
            'earned': 18000,
            'paid': 8000,
            'balance': 9000,
          }),
        ],
        members: [_member, _secondMember],
        fetchedAt: DateTime(2026, 8, 6),
      );

      expect(settlement.validationMessage, isNull);
      expect(settlement.toApiJson(), {
        'labour_id': 'labour-1',
        'amount': 5000.0,
        'payment_mode': 'BANK',
        'remarks': 'August site settlement',
      });
      expect(payroll.totalEarned, 43000);
      expect(payroll.totalPaid, 18000);
      expect(payroll.totalBalance, 23000);
      expect(payroll.generatedLabourIds, {'labour-1', 'labour-2'});
    });
  });
}

final _member = WorkforceMember.fromJson(_memberPayload);
final _secondMember = WorkforceMember.fromJson({
  ..._memberPayload,
  'id': 'labour-2',
  'full_name': 'Suman Devi',
  'trade': 'Electrician',
  'daily_wage': 1100,
  'site_id': 'site-2',
});

final _site = SiteSummary.fromJson({
  'id': 'site-1',
  'name': 'Orchid Residence',
  'location': 'Sector 57, Gurugram',
  'status': 'ACTIVE',
  'progress': 64,
});
final _secondSite = SiteSummary.fromJson({
  'id': 'site-2',
  'name': 'Lakeview Villas',
  'location': 'Noida Extension',
  'status': 'ACTIVE',
  'progress': 39,
});

const _memberPayload = <String, dynamic>{
  'id': 'labour-1',
  'company_id': 'company-1',
  'full_name': 'Ramesh Kumar',
  'mobile': '9876543210',
  'trade': 'Mason',
  'daily_wage': 950,
  'site_id': 'site-1',
  'active': true,
  'created_at': '2026-08-01T08:30:00Z',
};

const _attendancePayload = <String, dynamic>{
  'id': 'attendance-1',
  'company_id': 'company-1',
  'site_id': 'site-1',
  'date': '2026-08-06',
  'marked_by': 'supervisor-1',
  'entries': [
    {
      'labour_id': 'labour-1',
      'status': 'PRESENT',
      'overtime_hours': 2.5,
      'advance': 450,
    },
    {
      'labour_id': 'labour-2',
      'status': 'HALF_DAY',
      'overtime_hours': 0,
      'advance': 0,
    },
    {
      'labour_id': 'labour-3',
      'status': 'ABSENT',
      'overtime_hours': 0,
      'advance': 0,
    },
    {
      'labour_id': 'labour-4',
      'status': 'LEAVE',
      'overtime_hours': 0,
      'advance': 250,
    },
  ],
  'created_at': '2026-08-06T05:00:00Z',
};

const _payrollPayload = <String, dynamic>{
  'id': 'payroll-1',
  'company_id': 'company-1',
  'labour_id': 'labour-1',
  'labour_name': 'Ramesh Kumar',
  'month': '2026-08',
  'earned': 25000,
  'advance': 1000,
  'paid': 10000,
  'bonus': 0,
  'deduction': 0,
  'balance': 14000,
  'generated_at': '2026-08-31T12:00:00Z',
};
