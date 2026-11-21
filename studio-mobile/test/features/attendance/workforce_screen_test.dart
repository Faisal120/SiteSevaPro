import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/core/theme/app_theme.dart';
import 'package:siteseva/features/attendance/models/attendance_models.dart';
import 'package:siteseva/features/attendance/models/workforce_models.dart';
import 'package:siteseva/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:siteseva/features/attendance/presentation/screens/payroll_screen.dart';
import 'package:siteseva/features/attendance/presentation/screens/workforce_detail_screen.dart';
import 'package:siteseva/features/attendance/presentation/screens/workforce_screen.dart';
import 'package:siteseva/features/attendance/providers/workforce_provider.dart';
import 'package:siteseva/features/attendance/repository/workforce_repository.dart';
import 'package:siteseva/features/auth/models/auth_user.dart';
import 'package:siteseva/features/auth/models/contractor_application.dart';
import 'package:siteseva/features/auth/providers/auth_provider.dart';
import 'package:siteseva/features/auth/repository/auth_repository.dart';
import 'package:siteseva/features/sites/models/site_models.dart';

void main() {
  testWidgets('desktop attendance renders live crew and payroll linkage', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(1440, 1000),
      user: _contractor,
      child: const AttendanceScreen(),
      overrides: [
        attendanceBoardControllerProvider.overrideWith(
          (ref) => _LoadedAttendanceController(_attendanceData, _repository),
        ),
      ],
    );

    expect(find.text('Field Attendance'), findsOneWidget);
    expect(find.text('SERVER-MARKED ATTENDANCE'), findsOneWidget);
    expect(find.text('Orchid Residence'), findsWidgets);
    expect(find.text('Ramesh Kumar'), findsOneWidget);
    expect(find.text('Submit day'), findsOneWidget);
    expect(find.text('Recent attendance'), findsOneWidget);
    _expectNoFlutterException(tester);
  });

  testWidgets('mobile attendance settles without responsive overflow', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(390, 844),
      user: _supervisor,
      child: const AttendanceScreen(),
      overrides: [
        attendanceBoardControllerProvider.overrideWith(
          (ref) => _LoadedAttendanceController(_attendanceData, _repository),
        ),
      ],
    );

    expect(find.text('Field Attendance'), findsOneWidget);
    expect(find.text('2026-08-06'), findsWidgets);
    expect(find.text('Mark all'), findsOneWidget);
    _expectNoFlutterException(tester);
  });

  testWidgets('client attendance is anonymized and read-only', (tester) async {
    await _pump(
      tester,
      size: const Size(390, 844),
      user: _client,
      child: const AttendanceScreen(),
      overrides: [
        attendanceBoardControllerProvider.overrideWith(
          (ref) =>
              _LoadedAttendanceController(_clientAttendanceData, _repository),
        ),
      ],
    );

    expect(
      find.text('Read-only attendance visibility for assigned projects.'),
      findsOneWidget,
    );
    expect(find.text('Workforce member 1'), findsOneWidget);
    expect(find.text('Member details restricted'), findsOneWidget);
    expect(find.text('Ramesh Kumar'), findsNothing);
    expect(find.text('Submit day'), findsNothing);
    expect(find.text('Mark all'), findsNothing);
    _expectNoFlutterException(tester);
  });

  testWidgets('workforce directory is responsive and uses server wallet data', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(390, 844),
      user: _contractor,
      child: const WorkforceScreen(),
      overrides: [
        workforceStudioControllerProvider.overrideWith(
          (ref) => _LoadedStudioController(_studioData, _repository),
        ),
      ],
    );

    expect(find.text('Workforce'), findsOneWidget);
    expect(find.text('Connected workforce workflow'), findsOneWidget);
    expect(find.text('Workforce directory'), findsOneWidget);
    expect(find.text('Ramesh Kumar'), findsOneWidget);
    expect(find.byTooltip('Add workforce member'), findsOneWidget);
    _expectNoFlutterException(tester);
  });

  testWidgets('worker wallet detail renders profile, balance, and ledger', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(1440, 1000),
      user: _contractor,
      child: const WorkforceDetailScreen(labourId: 'labour-1'),
      overrides: [
        workforceStudioControllerProvider.overrideWith(
          (ref) => _LoadedStudioController(_studioData, _repository),
        ),
        workforceDetailControllerProvider.overrideWith(
          (ref, labourId) =>
              _LoadedDetailController(_detail, _repository, labourId),
        ),
      ],
    );

    expect(find.text('Ramesh Kumar'), findsWidgets);
    expect(find.text('Wallet composition'), findsOneWidget);
    expect(find.text('Workforce profile'), findsOneWidget);
    expect(find.text('Wallet ledger'), findsOneWidget);
    expect(find.text('Settle wallet'), findsOneWidget);
    _expectNoFlutterException(tester);
  });

  testWidgets('mobile payroll renders generated records and queue', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(390, 844),
      user: _contractor,
      child: const PayrollScreen(),
      overrides: [
        payrollControllerProvider.overrideWith(
          (ref) => _LoadedPayrollController(_payrollData, _repository),
        ),
      ],
    );

    expect(find.text('Labour Payroll'), findsOneWidget);
    expect(find.text('Generated payroll'), findsOneWidget);
    expect(find.text('Generation queue'), findsOneWidget);
    expect(find.text('Ramesh Kumar'), findsWidgets);
    expect(find.text('Generated'), findsWidgets);
    _expectNoFlutterException(tester);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required AuthUser user,
  required Widget child,
  required List<Override> overrides,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          (ref) => _AuthenticatedController(user),
        ),
        workforceRepositoryProvider.overrideWithValue(_repository),
        ...overrides,
      ],
      child: MaterialApp(theme: AppTheme.light(), home: child),
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));
}

void _expectNoFlutterException(WidgetTester tester) {
  final exception = tester.takeException();
  if (exception case final FlutterError error) {
    debugPrint(error.toStringDeep());
  }
  expect(exception, isNull);
}

const _contractor = AuthUser(
  id: 'contractor-1',
  email: 'contractor@siteseva.test',
  fullName: 'Aarav Mehta',
  role: 'CONTRACTOR',
  companyId: 'company-1',
  companyName: 'Buildcraft Projects',
  siteIds: ['site-1'],
  blocked: false,
);

const _supervisor = AuthUser(
  id: 'supervisor-1',
  email: 'supervisor@siteseva.test',
  fullName: 'Priya Sharma',
  role: 'SUPERVISOR',
  companyId: 'company-1',
  companyName: 'Buildcraft Projects',
  siteIds: ['site-1'],
  blocked: false,
);

const _client = AuthUser(
  id: 'client-1',
  email: 'client@siteseva.test',
  fullName: 'Neha Kapoor',
  role: 'CLIENT',
  companyId: 'company-1',
  companyName: 'Buildcraft Projects',
  siteIds: ['site-1'],
  blocked: false,
);

final _site = SiteSummary.fromJson({
  'id': 'site-1',
  'name': 'Orchid Residence',
  'location': 'Sector 57, Gurugram',
  'status': 'ACTIVE',
  'progress': 64,
});

final _member = WorkforceMember.fromJson({
  'id': 'labour-1',
  'company_id': 'company-1',
  'full_name': 'Ramesh Kumar',
  'mobile': '9876543210',
  'trade': 'Mason',
  'daily_wage': 950,
  'site_id': 'site-1',
  'active': true,
});

final _attendanceDocument = AttendanceDocument.fromJson({
  'id': 'attendance-1',
  'company_id': 'company-1',
  'site_id': 'site-1',
  'date': '2026-08-06',
  'marked_by': 'supervisor-1',
  'entries': [
    {
      'labour_id': 'labour-1',
      'status': 'PRESENT',
      'overtime_hours': 2,
      'advance': 300,
    },
  ],
});

final _attendanceData = AttendanceBoardData(
  sites: [_site],
  siteId: 'site-1',
  date: '2026-08-06',
  members: [_member],
  document: _attendanceDocument,
  history: [_attendanceDocument],
  draft: AttendanceDraft.fromBoard(
    siteId: 'site-1',
    date: '2026-08-06',
    members: [_member],
    document: _attendanceDocument,
  ),
  fetchedAt: DateTime(2026, 8, 6, 12),
  canViewMemberDetails: true,
);

final _clientAttendanceData = AttendanceBoardData(
  sites: [_site],
  siteId: 'site-1',
  date: '2026-08-06',
  members: const [],
  document: _attendanceDocument,
  history: [_attendanceDocument],
  draft: AttendanceDraft.fromBoard(
    siteId: 'site-1',
    date: '2026-08-06',
    members: const [],
    document: _attendanceDocument,
  ),
  fetchedAt: DateTime(2026, 8, 6, 12),
  canViewMemberDetails: false,
);

final _wallet = LabourWallet.fromJson({
  'id': 'wallet-1',
  'company_id': 'company-1',
  'labour_id': 'labour-1',
  'site_id': 'site-1',
  'earned': 25000,
  'advance': 1000,
  'paid': 10000,
  'bonus': 0,
  'deduction': 0,
  'balance': 14000,
});

final _walletSummary = WorkforceWalletSummary(
  totalEarned: 25000,
  totalPaid: 10000,
  totalBalance: 14000,
  rows: [WorkforceWalletRow(member: _member, wallet: _wallet)],
);

final _studioData = WorkforceStudioData(
  members: [_member],
  sites: [_site],
  walletSummary: _walletSummary,
  fetchedAt: DateTime(2026, 8, 6, 12),
);

final _ledger = LabourLedgerEntry.fromJson({
  'id': 'ledger-1',
  'company_id': 'company-1',
  'labour_id': 'labour-1',
  'site_id': 'site-1',
  'type': 'EARNING',
  'amount': 950,
  'date': '2026-08-06',
  'note': 'Attendance earning',
  'created_at': '2026-08-06T12:00:00Z',
});

final _detail = WorkforceDetail(
  member: _member,
  wallet: _wallet,
  ledger: [_ledger],
  fetchedAt: DateTime(2026, 8, 6, 12),
);

final _payrollRecord = PayrollRecord.fromJson({
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
});

final _payrollData = PayrollData(
  month: '2026-08',
  records: [_payrollRecord],
  members: [_member],
  fetchedAt: DateTime(2026, 8, 6, 12),
);

const _repository = _FakeWorkforceRepository();

class _LoadedAttendanceController extends AttendanceBoardController {
  _LoadedAttendanceController(
    AttendanceBoardData data,
    WorkforceRepository repository,
  ) : super(repository) {
    state = AsyncValue.data(data);
  }
}

class _LoadedStudioController extends WorkforceStudioController {
  _LoadedStudioController(
    WorkforceStudioData data,
    WorkforceRepository repository,
  ) : super(repository) {
    state = AsyncValue.data(data);
  }
}

class _LoadedDetailController extends WorkforceDetailController {
  _LoadedDetailController(
    WorkforceDetail data,
    WorkforceRepository repository,
    String labourId,
  ) : super(repository: repository, labourId: labourId) {
    state = AsyncValue.data(data);
  }
}

class _LoadedPayrollController extends PayrollController {
  _LoadedPayrollController(PayrollData data, WorkforceRepository repository)
    : super(repository) {
    state = AsyncValue.data(data);
  }
}

class _FakeWorkforceRepository implements WorkforceRepository {
  const _FakeWorkforceRepository();

  @override
  Future<WorkforceMember> createMember(WorkforceCreationBrief brief) async =>
      _member;

  @override
  Future<void> deleteMember(String labourId) async {}

  @override
  Future<AttendanceBoardData> fetchAttendance({
    String? siteId,
    required String date,
  }) async => _attendanceData;

  @override
  Future<WorkforceDetail> fetchDetail(String labourId) async => _detail;

  @override
  Future<PayrollData> fetchPayroll(String month) async => _payrollData;

  @override
  Future<WorkforceStudioData> fetchWorkforce() async => _studioData;

  @override
  Future<PayrollRecord> generatePayroll(String labourId, String month) async =>
      _payrollRecord;

  @override
  Future<AttendanceDocument> saveAttendance(AttendanceDraft draft) async =>
      _attendanceDocument;

  @override
  Future<void> settleWallet(WalletSettlementBrief brief) async {}
}

class _AuthenticatedController extends AuthController {
  _AuthenticatedController(AuthUser user) : super(_FakeAuthRepository()) {
    state = AsyncValue.data(user);
  }
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthUser?> restoreSession() async => null;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
    required bool rememberSession,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<ContractorApplication> submitApplication(
    ContractorApplicationInput application,
  ) {
    throw UnimplementedError();
  }
}
