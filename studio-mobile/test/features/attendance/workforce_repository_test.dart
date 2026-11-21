import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/core/network/api_service.dart';
import 'package:siteseva/features/attendance/data/workforce_cache.dart';
import 'package:siteseva/features/attendance/data/workforce_remote_data_source.dart';
import 'package:siteseva/features/attendance/data/workforce_repository_impl.dart';
import 'package:siteseva/features/attendance/models/attendance_models.dart';
import 'package:siteseva/features/attendance/models/workforce_models.dart';

void main() {
  group('WorkforceRepositoryImpl', () {
    test('loads and caches the contractor attendance workspace', () async {
      final remote = _FakeWorkforceRemote();
      final cache = _MemoryWorkforceCache();
      final repository = _repository(remote: remote, cache: cache);

      final board = await repository.fetchAttendance(date: '2026-08-06');

      expect(board.selectedSite?.name, 'Orchid Residence');
      expect(board.members.single.displayName, 'Ramesh Kumar');
      expect(board.document?.presentCount, 1);
      expect(board.history.single.id, 'attendance-1');
      expect(board.canViewMemberDetails, isTrue);
      expect(remote.labourRequests, 1);
      expect(cache.attendance['contractor-1::auto::2026-08-06'], isNotNull);
      expect(cache.attendance['contractor-1::site-1::2026-08-06'], isNotNull);
    });

    test('client attendance skips restricted labour endpoint', () async {
      final remote = _FakeWorkforceRemote();
      final repository = _repository(
        remote: remote,
        cache: _MemoryWorkforceCache(),
        canEditAttendance: false,
        canViewMembers: false,
        canManageMembers: false,
        canViewWallet: false,
        canManageWallet: false,
      );

      final board = await repository.fetchAttendance(
        siteId: 'site-1',
        date: '2026-08-06',
      );

      expect(remote.labourRequests, 0);
      expect(board.members, isEmpty);
      expect(board.canViewMemberDetails, isFalse);
      expect(board.draft?.entries.keys, contains('labour-1'));
      expect(
        repository.saveAttendance(board.draft!),
        throwsA(isA<ApiException>()),
      );
    });

    test('uses attendance cache only for connectivity failures', () async {
      final cache = _MemoryWorkforceCache()
        ..attendance['contractor-1::auto::2026-08-06'] = CachedWorkforcePayload(
          payload: _cachedAttendancePayload,
          cachedAt: DateTime(2026, 8, 6, 9),
        );
      final repository = _repository(
        remote: _FakeWorkforceRemote(
          error: const ApiException('offline', kind: ApiErrorKind.network),
        ),
        cache: cache,
      );

      final board = await repository.fetchAttendance(date: '2026-08-06');

      expect(board.isOffline, isTrue);
      expect(board.siteId, 'site-1');
      expect(board.fetchedAt, DateTime(2026, 8, 6, 9));
    });

    test('does not hide authorization failures behind cache', () async {
      final cache = _MemoryWorkforceCache()
        ..attendance['contractor-1::auto::2026-08-06'] = CachedWorkforcePayload(
          payload: _cachedAttendancePayload,
          cachedAt: DateTime(2026, 8, 6),
        );
      final repository = _repository(
        remote: _FakeWorkforceRemote(
          error: const ApiException(
            'forbidden',
            statusCode: 403,
            kind: ApiErrorKind.authentication,
          ),
        ),
        cache: cache,
      );

      expect(
        repository.fetchAttendance(date: '2026-08-06'),
        throwsA(isA<ApiException>()),
      );
    });

    test(
      'submits exact attendance, labour, delete, and settlement inputs',
      () async {
        final remote = _FakeWorkforceRemote();
        final repository = _repository(
          remote: remote,
          cache: _MemoryWorkforceCache(),
        );
        const draft = AttendanceDraft(
          siteId: 'site-1',
          date: '2026-08-06',
          entries: {
            'labour-1': AttendanceEntry(
              labourId: 'labour-1',
              status: AttendanceStatus.present,
              overtimeHours: 2,
              advance: 300,
            ),
          },
        );
        const memberBrief = WorkforceCreationBrief(
          fullName: 'Ramesh Kumar',
          mobile: '9876543210',
          trade: 'Mason',
          dailyWage: 950,
          siteId: 'site-1',
          aadhaar: '',
          address: '',
        );
        const settlement = WalletSettlementBrief(
          labourId: 'labour-1',
          amount: 5000,
          paymentMode: LabourPaymentMode.upi,
          remarks: 'August settlement',
        );

        await repository.saveAttendance(draft);
        await repository.createMember(memberBrief);
        await repository.deleteMember('labour-1');
        await repository.settleWallet(settlement);

        expect(remote.lastAttendance, draft.toApiJson());
        expect(remote.lastCreate, memberBrief.toApiJson());
        expect(remote.deletedLabourId, 'labour-1');
        expect(remote.lastSettlement, settlement.toApiJson());
      },
    );

    test(
      'joins workforce, project, and wallet responses without fake metrics',
      () async {
        final cache = _MemoryWorkforceCache();
        final repository = _repository(
          remote: _FakeWorkforceRemote(),
          cache: cache,
        );

        final data = await repository.fetchWorkforce();

        expect(data.members.single.id, 'labour-1');
        expect(data.sites.single.id, 'site-1');
        expect(data.walletSummary.totalEarned, 25000);
        expect(data.walletSummary.walletFor('labour-1').balance, 14000);
        expect(data.dailyWageExposure, 950);
        expect(cache.studios['contractor-1'], isNotNull);
      },
    );

    test(
      'loads wallet detail and monthly payroll from endpoint shapes',
      () async {
        final remote = _FakeWorkforceRemote();
        final repository = _repository(
          remote: remote,
          cache: _MemoryWorkforceCache(),
        );

        final detail = await repository.fetchDetail('labour-1');
        final payroll = await repository.fetchPayroll('2026-08');
        final generated = await repository.generatePayroll(
          'labour-1',
          '2026-08',
        );

        expect(detail.wallet.balance, 14000);
        expect(detail.ledger.single.type, LabourLedgerType.earning);
        expect(payroll.records.single.labourName, 'Ramesh Kumar');
        expect(payroll.members.single.id, 'labour-1');
        expect(generated.month, '2026-08');
        expect(remote.generatedRequest, ('labour-1', '2026-08'));
      },
    );

    test('enforces the three-role capability boundary in the repository', () {
      final repository = _repository(
        remote: _FakeWorkforceRemote(),
        cache: _MemoryWorkforceCache(),
        canViewAttendance: true,
        canEditAttendance: false,
        canViewMembers: false,
        canManageMembers: false,
        canViewWallet: false,
        canManageWallet: false,
      );

      expect(repository.fetchWorkforce(), throwsA(isA<ApiException>()));
      expect(
        repository.createMember(WorkforceCreationBrief.initial()),
        throwsA(isA<ApiException>()),
      );
      expect(repository.fetchDetail('labour-1'), throwsA(isA<ApiException>()));
      expect(repository.fetchPayroll('2026-08'), throwsA(isA<ApiException>()));
      expect(
        repository.settleWallet(WalletSettlementBrief.initial('labour-1')),
        throwsA(isA<ApiException>()),
      );
    });
  });
}

WorkforceRepositoryImpl _repository({
  required WorkforceRemoteDataSource remote,
  required WorkforceCache cache,
  bool canViewAttendance = true,
  bool canEditAttendance = true,
  bool canViewMembers = true,
  bool canManageMembers = true,
  bool canViewWallet = true,
  bool canManageWallet = true,
}) => WorkforceRepositoryImpl(
  remote: remote,
  cache: cache,
  userId: 'contractor-1',
  canViewAttendance: canViewAttendance,
  canEditAttendance: canEditAttendance,
  canViewMembers: canViewMembers,
  canManageMembers: canManageMembers,
  canViewWallet: canViewWallet,
  canManageWallet: canManageWallet,
);

class _FakeWorkforceRemote implements WorkforceRemoteDataSource {
  _FakeWorkforceRemote({this.error});

  final ApiException? error;
  int labourRequests = 0;
  Map<String, dynamic>? lastAttendance;
  Map<String, dynamic>? lastCreate;
  Map<String, dynamic>? lastSettlement;
  String? deletedLabourId;
  (String, String)? generatedRequest;

  void _throwIfNeeded() {
    if (error != null) throw error!;
  }

  @override
  Future<Map<String, dynamic>> createLabour(
    Map<String, dynamic> payload,
  ) async {
    _throwIfNeeded();
    lastCreate = payload;
    return Map<String, dynamic>.from(_memberPayload);
  }

  @override
  Future<void> deleteLabour(String labourId) async {
    _throwIfNeeded();
    deletedLabourId = labourId;
  }

  @override
  Future<Map<String, dynamic>> fetchAttendanceDay({
    required String siteId,
    required String date,
  }) async {
    _throwIfNeeded();
    return Map<String, dynamic>.from(_attendancePayload);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAttendanceHistory(
    String siteId,
  ) async {
    _throwIfNeeded();
    return [_attendancePayload];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchLabour({String? siteId}) async {
    _throwIfNeeded();
    labourRequests += 1;
    return [_memberPayload];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPayroll(String month) async {
    _throwIfNeeded();
    return [_payrollPayload];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSites() async {
    _throwIfNeeded();
    return [_sitePayload];
  }

  @override
  Future<Map<String, dynamic>> fetchWalletSummary({String? siteId}) async {
    _throwIfNeeded();
    return Map<String, dynamic>.from(_walletSummaryPayload);
  }

  @override
  Future<Map<String, dynamic>> fetchWorkforceDetail(String labourId) async {
    _throwIfNeeded();
    return Map<String, dynamic>.from(_detailPayload);
  }

  @override
  Future<Map<String, dynamic>> generatePayroll(
    String labourId,
    String month,
  ) async {
    _throwIfNeeded();
    generatedRequest = (labourId, month);
    return Map<String, dynamic>.from(_payrollPayload);
  }

  @override
  Future<Map<String, dynamic>> markAttendance(
    Map<String, dynamic> payload,
  ) async {
    _throwIfNeeded();
    lastAttendance = payload;
    return Map<String, dynamic>.from(_attendancePayload);
  }

  @override
  Future<Map<String, dynamic>> settleWallet(
    Map<String, dynamic> payload,
  ) async {
    _throwIfNeeded();
    lastSettlement = payload;
    return {'wallet': _walletPayload, 'ledger': _ledgerPayload};
  }
}

class _MemoryWorkforceCache implements WorkforceCache {
  final attendance = <String, CachedWorkforcePayload>{};
  final studios = <String, CachedWorkforcePayload>{};
  final details = <String, CachedWorkforcePayload>{};
  final payroll = <String, CachedWorkforcePayload>{};

  @override
  Future<CachedWorkforcePayload?> readAttendance(
    String userId,
    String siteKey,
    String date,
  ) async => attendance['$userId::$siteKey::$date'];

  @override
  Future<CachedWorkforcePayload?> readDetail(
    String userId,
    String labourId,
  ) async => details['$userId::$labourId'];

  @override
  Future<CachedWorkforcePayload?> readPayroll(
    String userId,
    String month,
  ) async => payroll['$userId::$month'];

  @override
  Future<CachedWorkforcePayload?> readStudio(String userId) async =>
      studios[userId];

  @override
  Future<void> writeAttendance(
    String userId,
    String siteKey,
    String date,
    Map<String, dynamic> payload,
  ) async {
    attendance['$userId::$siteKey::$date'] = CachedWorkforcePayload(
      payload: payload,
      cachedAt: DateTime.now(),
    );
  }

  @override
  Future<void> writeDetail(
    String userId,
    String labourId,
    Map<String, dynamic> payload,
  ) async {
    details['$userId::$labourId'] = CachedWorkforcePayload(
      payload: payload,
      cachedAt: DateTime.now(),
    );
  }

  @override
  Future<void> writePayroll(
    String userId,
    String month,
    Map<String, dynamic> payload,
  ) async {
    payroll['$userId::$month'] = CachedWorkforcePayload(
      payload: payload,
      cachedAt: DateTime.now(),
    );
  }

  @override
  Future<void> writeStudio(String userId, Map<String, dynamic> payload) async {
    studios[userId] = CachedWorkforcePayload(
      payload: payload,
      cachedAt: DateTime.now(),
    );
  }
}

const _sitePayload = <String, dynamic>{
  'id': 'site-1',
  'name': 'Orchid Residence',
  'location': 'Sector 57, Gurugram',
  'status': 'ACTIVE',
  'progress': 64,
};

const _memberPayload = <String, dynamic>{
  'id': 'labour-1',
  'company_id': 'company-1',
  'full_name': 'Ramesh Kumar',
  'mobile': '9876543210',
  'trade': 'Mason',
  'daily_wage': 950,
  'site_id': 'site-1',
  'active': true,
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
      'overtime_hours': 2,
      'advance': 300,
    },
  ],
};

const _walletPayload = <String, dynamic>{
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
};

const _ledgerPayload = <String, dynamic>{
  'id': 'ledger-1',
  'company_id': 'company-1',
  'labour_id': 'labour-1',
  'site_id': 'site-1',
  'type': 'EARNING',
  'amount': 950,
  'date': '2026-08-06',
  'note': 'Attendance earning',
  'created_at': '2026-08-06T12:00:00Z',
};

const _walletSummaryPayload = <String, dynamic>{
  'total_earned': 25000,
  'total_paid': 10000,
  'total_balance': 14000,
  'rows': [
    {..._memberPayload, 'wallet': _walletPayload},
  ],
};

const _detailPayload = <String, dynamic>{
  'labour': _memberPayload,
  'wallet': _walletPayload,
  'ledger': [_ledgerPayload],
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
};

const _cachedAttendancePayload = <String, dynamic>{
  'sites': [_sitePayload],
  'site_id': 'site-1',
  'date': '2026-08-06',
  'members': [_memberPayload],
  'document': _attendancePayload,
  'history': [_attendancePayload],
};
