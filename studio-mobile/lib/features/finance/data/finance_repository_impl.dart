import '../../../core/media/app_image_picker.dart';
import '../../../core/network/api_service.dart';
import '../../sites/models/site_models.dart';
import '../models/finance_models.dart';
import '../repository/finance_repository.dart';
import 'finance_cache.dart';
import 'finance_remote_data_source.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  const FinanceRepositoryImpl({
    required FinanceRemoteDataSource remote,
    required FinanceCache cache,
    required String userId,
    required FinanceAudience audience,
    DateTime Function()? clock,
  }) : _remote = remote,
       _cache = cache,
       _userId = userId,
       _audience = audience,
       _clock = clock ?? DateTime.now;

  final FinanceRemoteDataSource _remote;
  final FinanceCache _cache;
  final String _userId;
  final FinanceAudience _audience;
  final DateTime Function() _clock;

  @override
  Future<FinanceStudioData> fetchStudio() async {
    try {
      final sites = await _remote.fetchSites();
      final siteIds = sites
          .map((site) => '${site['id'] ?? ''}')
          .where((id) => id.isNotEmpty)
          .toList(growable: false);
      final paymentsFuture = switch (_audience) {
        FinanceAudience.contractor => _remote.fetchPayments(),
        FinanceAudience.client => _fetchPaymentsPerSite(siteIds),
        FinanceAudience.supervisor => Future.value(
          const <Map<String, dynamic>>[],
        ),
      };
      final expensesFuture = switch (_audience) {
        FinanceAudience.contractor => _remote.fetchExpenses(),
        FinanceAudience.supervisor => _fetchExpensesPerSite(siteIds),
        FinanceAudience.client => Future.value(const <Map<String, dynamic>>[]),
      };
      final reportFuture = _audience == FinanceAudience.contractor
          ? _remote.fetchExpenseReport()
          : Future.value(<String, dynamic>{});
      final results = await Future.wait<Object>([
        paymentsFuture,
        expensesFuture,
        reportFuture,
      ]);
      final payload = <String, dynamic>{
        'sites': sites,
        'payments': results[0],
        'expenses': results[1],
        'expense_report': results[2],
      };
      await _cache.writeStudio(_userId, payload);
      return _parse(payload, _clock());
    } on ApiException catch (error) {
      if (!error.isConnectivityFailure) rethrow;
      final cached = await _cache.readStudio(_userId);
      if (cached == null) rethrow;
      return _parse(
        cached.payload,
        cached.cachedAt,
        referenceDate: _clock(),
        isOffline: true,
      );
    }
  }

  @override
  Future<PaymentRecord> createPayment(PaymentBrief brief) async {
    _guard(
      _audience == FinanceAudience.contractor,
      'Only contractors can record project payments.',
    );
    final validation = brief.validationMessage(_clock());
    if (validation != null) _invalid(validation);
    await _validateSite(brief.siteId);
    return PaymentRecord.fromJson(
      await _remote.createPayment(brief.toApiJson()),
    );
  }

  @override
  Future<ExpenseRecord> createExpense(ExpenseBrief brief) async {
    _guard(
      _audience != FinanceAudience.client,
      'Clients have read-only access to received payments.',
    );
    final validation = brief.validationMessage(_clock());
    if (validation != null) _invalid(validation);
    await _validateSite(brief.siteId);
    return ExpenseRecord.fromJson(
      await _remote.createExpense(brief.toApiJson()),
    );
  }

  @override
  Future<String> uploadAttachment(AppImageAsset asset) async {
    _guard(
      _audience != FinanceAudience.client,
      'Clients cannot upload finance attachments.',
    );
    final validation = asset.validationMessage;
    if (validation != null) _invalid(validation);
    final payload = await _remote.uploadAttachment(asset);
    final url = '${payload['secure_url'] ?? payload['url'] ?? ''}'.trim();
    if (!url.startsWith('https://')) {
      throw const ApiException(
        'The media service did not return a secure attachment URL.',
        kind: ApiErrorKind.invalidResponse,
      );
    }
    return url;
  }

  Future<List<Map<String, dynamic>>> _fetchPaymentsPerSite(
    List<String> siteIds,
  ) async {
    if (siteIds.isEmpty) return const [];
    final pages = await Future.wait(
      siteIds.map((siteId) => _remote.fetchPayments(siteId: siteId)),
    );
    return _dedupe(pages.expand((page) => page));
  }

  Future<List<Map<String, dynamic>>> _fetchExpensesPerSite(
    List<String> siteIds,
  ) async {
    if (siteIds.isEmpty) return const [];
    final pages = await Future.wait(
      siteIds.map((siteId) => _remote.fetchExpenses(siteId: siteId)),
    );
    return _dedupe(pages.expand((page) => page));
  }

  Future<void> _validateSite(String siteId) async {
    final sites = (await _remote.fetchSites()).map(SiteSummary.fromJson);
    if (!sites.any((site) => site.id == siteId)) {
      throw const ApiException(
        'The selected project is not assigned to this account.',
        statusCode: 403,
        kind: ApiErrorKind.authentication,
      );
    }
  }

  FinanceStudioData _parse(
    Map<String, dynamic> payload,
    DateTime fetchedAt, {
    DateTime? referenceDate,
    bool isOffline = false,
  }) {
    final sites = _maps(payload['sites'])
        .map(SiteSummary.fromJson)
        .where((site) => site.id.isNotEmpty)
        .toList(growable: false);
    final assignedIds = sites.map((site) => site.id).toSet();
    var payments = _maps(payload['payments'])
        .map(PaymentRecord.fromJson)
        .where(
          (payment) =>
              payment.id.isNotEmpty &&
              payment.siteId.isNotEmpty &&
              payment.amount >= 0,
        )
        .toList(growable: false);
    var expenses = _maps(payload['expenses'])
        .map(ExpenseRecord.fromJson)
        .where(
          (expense) =>
              expense.id.isNotEmpty &&
              expense.siteId.isNotEmpty &&
              expense.amount >= 0,
        )
        .toList(growable: false);
    if (_audience != FinanceAudience.contractor) {
      payments = payments
          .where((payment) => assignedIds.contains(payment.siteId))
          .toList(growable: false);
      expenses = expenses
          .where((expense) => assignedIds.contains(expense.siteId))
          .toList(growable: false);
    }
    if (_audience == FinanceAudience.client) {
      payments = payments
          .where((payment) => payment.type == PaymentType.clientReceived)
          .toList(growable: false);
      expenses = const [];
    }
    if (_audience == FinanceAudience.supervisor) payments = const [];
    final initialWorkspace = switch (_audience) {
      FinanceAudience.contractor => FinanceWorkspace.overview,
      FinanceAudience.supervisor => FinanceWorkspace.overview,
      FinanceAudience.client => FinanceWorkspace.payments,
    };
    return FinanceStudioData(
      payments: payments,
      expenses: expenses,
      expenseReport: ExpenseReport.fromJson(_map(payload['expense_report'])),
      sites: sites,
      audience: _audience,
      fetchedAt: fetchedAt,
      referenceDate: referenceDate ?? fetchedAt,
      isOffline: isOffline,
      workspace: initialWorkspace,
    );
  }

  void _guard(bool allowed, String message) {
    if (!allowed) {
      throw ApiException(
        message,
        statusCode: 403,
        kind: ApiErrorKind.authentication,
      );
    }
  }

  Never _invalid(String message) => throw ApiException(
    message,
    statusCode: 422,
    kind: ApiErrorKind.invalidResponse,
  );
}

List<Map<String, dynamic>> _dedupe(Iterable<Map<String, dynamic>> records) {
  final unique = <String, Map<String, dynamic>>{};
  for (final record in records) {
    final id = '${record['id'] ?? ''}';
    final key = id.isEmpty
        ? '${record['site_id']}::${record['date']}::${record['amount']}::${record['description']}'
        : id;
    unique[key] = record;
  }
  return unique.values.toList(growable: false);
}

List<Map<String, dynamic>> _maps(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false)
    : const [];

Map<String, dynamic> _map(Object? value) => value is Map
    ? value.map((key, value) => MapEntry('$key', value))
    : <String, dynamic>{};
