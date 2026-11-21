import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/core/media/app_image_picker.dart';
import 'package:siteseva/core/network/api_service.dart';
import 'package:siteseva/features/finance/data/finance_cache.dart';
import 'package:siteseva/features/finance/data/finance_remote_data_source.dart';
import 'package:siteseva/features/finance/data/finance_repository_impl.dart';
import 'package:siteseva/features/finance/models/finance_models.dart';

void main() {
  group('FinanceRepositoryImpl', () {
    test(
      'contractor loads unscoped finance ledger and expense report',
      () async {
        final remote = _FakeFinanceRemote();
        final cache = _MemoryFinanceCache();
        final repository = _repository(remote: remote, cache: cache);

        final data = await repository.fetchStudio();

        expect(data.audience, FinanceAudience.contractor);
        expect(data.payments.single.id, 'payment-1');
        expect(data.expenses.single.id, 'expense-1');
        expect(data.expenseReport.byCategory.single.total, 4200);
        expect(remote.unscopedPaymentRequests, 1);
        expect(remote.unscopedExpenseRequests, 1);
        expect(remote.reportRequests, 1);
        expect(cache.studios['user-1'], isNotNull);
      },
    );

    test(
      'supervisor fetches expenses per assigned site and rejects leaked rows',
      () async {
        final remote = _FakeFinanceRemote(includeLeakedRows: true);
        final repository = _repository(
          remote: remote,
          cache: _MemoryFinanceCache(),
          audience: FinanceAudience.supervisor,
        );

        final data = await repository.fetchStudio();

        expect(remote.paymentSiteRequests, isEmpty);
        expect(remote.unscopedExpenseRequests, 0);
        expect(remote.expenseSiteRequests, ['site-1']);
        expect(remote.reportRequests, 0);
        expect(data.payments, isEmpty);
        expect(data.expenses.map((item) => item.siteId).toSet(), {'site-1'});
      },
    );

    test(
      'client fetches receipts per site and removes outflow and leaked sites',
      () async {
        final remote = _FakeFinanceRemote(includeLeakedRows: true);
        final repository = _repository(
          remote: remote,
          cache: _MemoryFinanceCache(),
          audience: FinanceAudience.client,
        );

        final data = await repository.fetchStudio();

        expect(remote.paymentSiteRequests, ['site-1']);
        expect(remote.unscopedExpenseRequests, 0);
        expect(data.payments.map((item) => item.id), ['payment-1']);
        expect(data.expenses, isEmpty);
        expect(data.availableWorkspaces, [FinanceWorkspace.payments]);
      },
    );

    test('uses offline cache only for connectivity failures', () async {
      final cache = _MemoryFinanceCache()
        ..studios['user-1'] = CachedFinanceStudio(
          payload: _cachedPayload,
          cachedAt: DateTime(2026, 8, 6, 9),
        );
      final repository = _repository(
        remote: _FakeFinanceRemote(
          error: const ApiException('offline', kind: ApiErrorKind.network),
        ),
        cache: cache,
      );

      final data = await repository.fetchStudio();

      expect(data.isOffline, isTrue);
      expect(data.payments.single.id, 'payment-1');
      expect(data.fetchedAt, DateTime(2026, 8, 6, 9));
    });

    test('does not hide authorization failures behind cache', () async {
      final cache = _MemoryFinanceCache()
        ..studios['user-1'] = CachedFinanceStudio(
          payload: _cachedPayload,
          cachedAt: DateTime(2026, 8, 6),
        );
      final repository = _repository(
        remote: _FakeFinanceRemote(
          error: const ApiException(
            'forbidden',
            statusCode: 403,
            kind: ApiErrorKind.authentication,
          ),
        ),
        cache: cache,
      );

      expect(repository.fetchStudio(), throwsA(isA<ApiException>()));
    });

    test(
      'submits exact PaymentIn and ExpenseIn payloads after site validation',
      () async {
        final remote = _FakeFinanceRemote();
        final contractor = _repository(
          remote: remote,
          cache: _MemoryFinanceCache(),
        );
        final payment = PaymentBrief.initial(referenceDate: _now()).copyWith(
          siteId: 'site-1',
          amount: 250000,
          description: 'Foundation milestone receipt',
          party: 'Ananya Rao',
        );
        final expense = ExpenseBrief.initial(referenceDate: _now()).copyWith(
          siteId: 'site-1',
          category: ExpenseCategory.fuel,
          amount: 4200,
          description: 'Excavator diesel refill',
          paidBy: 'Ravi Kumar',
        );

        await contractor.createPayment(payment);
        await contractor.createExpense(expense);

        expect(remote.lastPayment, payment.toApiJson());
        expect(remote.lastExpense, expense.toApiJson());
        expect(
          contractor.createPayment(payment.copyWith(siteId: 'site-unknown')),
          throwsA(isA<ApiException>()),
        );
      },
    );

    test('enforces role mutation boundaries', () {
      final client = _repository(
        remote: _FakeFinanceRemote(),
        cache: _MemoryFinanceCache(),
        audience: FinanceAudience.client,
      );
      final supervisor = _repository(
        remote: _FakeFinanceRemote(),
        cache: _MemoryFinanceCache(),
        audience: FinanceAudience.supervisor,
      );
      final payment = PaymentBrief.initial(referenceDate: _now());
      final expense = ExpenseBrief.initial(referenceDate: _now());

      expect(client.createPayment(payment), throwsA(isA<ApiException>()));
      expect(client.createExpense(expense), throwsA(isA<ApiException>()));
      expect(supervisor.createPayment(payment), throwsA(isA<ApiException>()));
    });

    test(
      'uploads only validated images and returns secure media URL',
      () async {
        final repository = _repository(
          remote: _FakeFinanceRemote(),
          cache: _MemoryFinanceCache(),
        );

        final url = await repository.uploadAttachment(
          AppImageAsset(
            bytes: Uint8List.fromList([1, 2, 3]),
            filename: 'receipt.jpg',
          ),
        );

        expect(url, startsWith('https://'));
        expect(
          repository.uploadAttachment(
            AppImageAsset(bytes: Uint8List(0), filename: 'empty.jpg'),
          ),
          throwsA(isA<ApiException>()),
        );
      },
    );
  });
}

DateTime _now() => DateTime(2026, 8, 7);

FinanceRepositoryImpl _repository({
  required FinanceRemoteDataSource remote,
  required FinanceCache cache,
  FinanceAudience audience = FinanceAudience.contractor,
}) => FinanceRepositoryImpl(
  remote: remote,
  cache: cache,
  userId: 'user-1',
  audience: audience,
  clock: _now,
);

class _FakeFinanceRemote implements FinanceRemoteDataSource {
  _FakeFinanceRemote({this.error, this.includeLeakedRows = false});

  final ApiException? error;
  final bool includeLeakedRows;
  int unscopedPaymentRequests = 0;
  int unscopedExpenseRequests = 0;
  int reportRequests = 0;
  final paymentSiteRequests = <String>[];
  final expenseSiteRequests = <String>[];
  Map<String, dynamic>? lastPayment;
  Map<String, dynamic>? lastExpense;

  void _throwIfNeeded() {
    if (error != null) throw error!;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSites() async {
    _throwIfNeeded();
    return [Map<String, dynamic>.from(_sitePayload)];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPayments({String? siteId}) async {
    _throwIfNeeded();
    if (siteId == null) {
      unscopedPaymentRequests++;
    } else {
      paymentSiteRequests.add(siteId);
    }
    return [
      Map<String, dynamic>.from(_paymentPayload),
      if (includeLeakedRows)
        {..._paymentPayload, 'id': 'payment-outflow', 'type': 'MATERIAL'},
      if (includeLeakedRows)
        {..._paymentPayload, 'id': 'payment-leaked', 'site_id': 'site-leaked'},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchExpenses({String? siteId}) async {
    _throwIfNeeded();
    if (siteId == null) {
      unscopedExpenseRequests++;
    } else {
      expenseSiteRequests.add(siteId);
    }
    return [
      Map<String, dynamic>.from(_expensePayload),
      if (includeLeakedRows)
        {..._expensePayload, 'id': 'expense-leaked', 'site_id': 'site-leaked'},
    ];
  }

  @override
  Future<Map<String, dynamic>> fetchExpenseReport({String? siteId}) async {
    _throwIfNeeded();
    reportRequests++;
    return Map<String, dynamic>.from(_reportPayload);
  }

  @override
  Future<Map<String, dynamic>> createPayment(
    Map<String, dynamic> payload,
  ) async {
    _throwIfNeeded();
    lastPayment = payload;
    return Map<String, dynamic>.from(_paymentPayload);
  }

  @override
  Future<Map<String, dynamic>> createExpense(
    Map<String, dynamic> payload,
  ) async {
    _throwIfNeeded();
    lastExpense = payload;
    return Map<String, dynamic>.from(_expensePayload);
  }

  @override
  Future<Map<String, dynamic>> uploadAttachment(AppImageAsset asset) async {
    _throwIfNeeded();
    return {'secure_url': 'https://res.cloudinary.com/site/${asset.filename}'};
  }
}

class _MemoryFinanceCache implements FinanceCache {
  final studios = <String, CachedFinanceStudio>{};

  @override
  Future<CachedFinanceStudio?> readStudio(String userId) async =>
      studios[userId];

  @override
  Future<void> writeStudio(String userId, Map<String, dynamic> payload) async {
    studios[userId] = CachedFinanceStudio(payload: payload, cachedAt: _now());
  }
}

const _sitePayload = <String, dynamic>{
  'id': 'site-1',
  'name': 'Orchid Residence',
  'location': 'Gurugram',
  'status': 'ACTIVE',
  'progress': 64,
};

const _paymentPayload = <String, dynamic>{
  'id': 'payment-1',
  'company_id': 'company-1',
  'site_id': 'site-1',
  'type': 'CLIENT_RECEIVED',
  'amount': 250000,
  'description': 'Foundation milestone receipt',
  'party': 'Ananya Rao',
  'date': '2026-08-07',
};

const _expensePayload = <String, dynamic>{
  'id': 'expense-1',
  'company_id': 'company-1',
  'site_id': 'site-1',
  'category': 'FUEL',
  'amount': 4200,
  'description': 'Excavator diesel refill',
  'paid_by': 'Ravi Kumar',
  'date': '2026-08-07',
};

const _reportPayload = <String, dynamic>{
  'by_category': [
    {'_id': 'FUEL', 'total': 4200, 'count': 1},
  ],
  'monthly': [
    {'_id': '2026-08', 'total': 4200},
  ],
};

const _cachedPayload = <String, dynamic>{
  'sites': [_sitePayload],
  'payments': [_paymentPayload],
  'expenses': [_expensePayload],
  'expense_report': _reportPayload,
};
