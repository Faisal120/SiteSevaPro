import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/media/app_image_picker.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../sites/models/site_models.dart';
import '../../sites/providers/sites_provider.dart';
import '../data/finance_cache.dart';
import '../data/finance_remote_data_source.dart';
import '../data/finance_repository_impl.dart';
import '../models/finance_models.dart';
import '../repository/finance_repository.dart';

final financeRemoteDataSourceProvider = Provider<FinanceRemoteDataSource>(
  (ref) => const HttpFinanceRemoteDataSource(),
);

final financeCacheProvider = Provider<FinanceCache>(
  (ref) => HiveFinanceCache(),
);

final financeImagePickerProvider = Provider<AppImagePicker>(
  (ref) => DeviceAppImagePicker(),
);

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  final audience = user?.isSupervisor == true
      ? FinanceAudience.supervisor
      : user?.isClient == true
      ? FinanceAudience.client
      : FinanceAudience.contractor;
  return FinanceRepositoryImpl(
    remote: ref.watch(financeRemoteDataSourceProvider),
    cache: ref.watch(financeCacheProvider),
    userId: user?.id ?? '',
    audience: audience,
  );
});

final financeStudioControllerProvider =
    StateNotifierProvider<
      FinanceStudioController,
      AsyncValue<FinanceStudioData>
    >((ref) {
      final controller = FinanceStudioController(
        ref.watch(financeRepositoryProvider),
      );
      unawaited(controller.load());
      return controller;
    });

final paymentBriefProvider =
    StateNotifierProvider.autoDispose<PaymentBriefController, PaymentBrief>(
      (ref) => PaymentBriefController(),
    );

final expenseBriefProvider =
    StateNotifierProvider.autoDispose<ExpenseBriefController, ExpenseBrief>(
      (ref) => ExpenseBriefController(),
    );

final financeActionControllerProvider =
    StateNotifierProvider.autoDispose<
      FinanceActionController,
      AsyncValue<void>
    >((ref) {
      return FinanceActionController(
        repository: ref.watch(financeRepositoryProvider),
        refreshStudio: () =>
            ref.read(financeStudioControllerProvider.notifier).refresh(),
        onCommitted: (siteId) async {
          ref.invalidate(sitePaymentsProvider(siteId));
          ref.invalidate(siteDetailControllerProvider(siteId));
          unawaited(ref.read(dashboardControllerProvider.notifier).refresh());
        },
      );
    });

class FinanceStudioController
    extends StateNotifier<AsyncValue<FinanceStudioData>> {
  FinanceStudioController(this._repository) : super(const AsyncValue.loading());

  final FinanceRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.fetchStudio);
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    try {
      final fresh = await _repository.fetchStudio();
      final retainedWorkspace =
          fresh.availableWorkspaces.contains(previous?.workspace)
          ? previous!.workspace
          : fresh.workspace;
      final retainedSite =
          previous?.siteFilter != null &&
              fresh.site(previous!.siteFilter!) != null
          ? previous.siteFilter
          : null;
      state = AsyncValue.data(
        fresh.copyWith(
          workspace: retainedWorkspace,
          period: previous?.period,
          query: previous?.query,
          siteFilter: retainedSite,
          clearSite: retainedSite == null,
          paymentTypeFilter: previous?.paymentTypeFilter,
          clearPaymentType: previous?.paymentTypeFilter == null,
          expenseCategoryFilter: previous?.expenseCategoryFilter,
          clearExpenseCategory: previous?.expenseCategoryFilter == null,
        ),
      );
    } catch (error, stackTrace) {
      if (previous == null) state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  void applyInitial({FinanceWorkspace? workspace, String? siteId}) {
    final data = state.valueOrNull;
    if (data == null) return;
    final targetWorkspace =
        workspace != null && data.availableWorkspaces.contains(workspace)
        ? workspace
        : data.workspace;
    final targetSite = siteId != null && data.site(siteId) != null
        ? siteId
        : null;
    state = AsyncValue.data(
      data.copyWith(
        workspace: targetWorkspace,
        siteFilter: targetSite,
        clearSite: targetSite == null,
      ),
    );
  }

  void setWorkspace(FinanceWorkspace workspace) {
    final data = state.valueOrNull;
    if (data == null || !data.availableWorkspaces.contains(workspace)) return;
    state = AsyncValue.data(
      data.copyWith(
        workspace: workspace,
        query: '',
        clearPaymentType: true,
        clearExpenseCategory: true,
      ),
    );
  }

  void setQuery(String query) {
    final data = state.valueOrNull;
    if (data != null) state = AsyncValue.data(data.copyWith(query: query));
  }

  void setPeriod(FinancePeriod period) {
    final data = state.valueOrNull;
    if (data != null) state = AsyncValue.data(data.copyWith(period: period));
  }

  void setSite(String? siteId) {
    final data = state.valueOrNull;
    if (data == null) return;
    state = AsyncValue.data(
      data.copyWith(siteFilter: siteId, clearSite: siteId == null),
    );
  }

  void setPaymentType(PaymentType? type) {
    final data = state.valueOrNull;
    if (data == null) return;
    state = AsyncValue.data(
      data.copyWith(paymentTypeFilter: type, clearPaymentType: type == null),
    );
  }

  void setExpenseCategory(ExpenseCategory? category) {
    final data = state.valueOrNull;
    if (data == null) return;
    state = AsyncValue.data(
      data.copyWith(
        expenseCategoryFilter: category,
        clearExpenseCategory: category == null,
      ),
    );
  }
}

class PaymentBriefController extends StateNotifier<PaymentBrief> {
  PaymentBriefController()
    : super(PaymentBrief.initial(referenceDate: DateTime.now()));

  void reset(FinanceStudioData data, {String? initialSiteId}) {
    final selected = _initialSite(data.sites, initialSiteId);
    state = PaymentBrief.initial(
      referenceDate: data.referenceDate,
    ).copyWith(siteId: selected?.id ?? '');
  }

  void setSite(String value) => state = state.copyWith(siteId: value);
  void setType(PaymentType value) => state = state.copyWith(type: value);
  void setAmount(String value) =>
      state = state.copyWith(amount: double.tryParse(value) ?? 0);
  void setDescription(String value) =>
      state = state.copyWith(description: value);
  void setDate(DateTime value) => state = state.copyWith(date: value);
  void setParty(String value) => state = state.copyWith(party: value);
  void setInvoiceUrl(String value) => state = state.copyWith(invoiceUrl: value);
}

class ExpenseBriefController extends StateNotifier<ExpenseBrief> {
  ExpenseBriefController()
    : super(ExpenseBrief.initial(referenceDate: DateTime.now()));

  void reset(FinanceStudioData data, {String? initialSiteId}) {
    final selected = _initialSite(data.sites, initialSiteId);
    state = ExpenseBrief.initial(
      referenceDate: data.referenceDate,
    ).copyWith(siteId: selected?.id ?? '');
  }

  void setSite(String value) => state = state.copyWith(siteId: value);
  void setCategory(ExpenseCategory value) =>
      state = state.copyWith(category: value);
  void setAmount(String value) =>
      state = state.copyWith(amount: double.tryParse(value) ?? 0);
  void setDescription(String value) =>
      state = state.copyWith(description: value);
  void setDate(DateTime value) => state = state.copyWith(date: value);
  void setPaidBy(String value) => state = state.copyWith(paidBy: value);
  void setReceiptUrl(String value) => state = state.copyWith(receiptUrl: value);
}

class FinanceActionController extends StateNotifier<AsyncValue<void>> {
  FinanceActionController({
    required FinanceRepository repository,
    required Future<void> Function() refreshStudio,
    required Future<void> Function(String siteId) onCommitted,
  }) : _repository = repository,
       _refreshStudio = refreshStudio,
       _onCommitted = onCommitted,
       super(const AsyncValue.data(null));

  final FinanceRepository _repository;
  final Future<void> Function() _refreshStudio;
  final Future<void> Function(String siteId) _onCommitted;

  Future<String?> uploadAttachment(AppImageAsset asset) async {
    state = const AsyncValue.loading();
    try {
      final url = await _repository.uploadAttachment(asset);
      state = const AsyncValue.data(null);
      return url;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  Future<bool> createPayment(PaymentBrief brief) =>
      _commit(() => _repository.createPayment(brief), siteId: brief.siteId);

  Future<bool> createExpense(ExpenseBrief brief) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createExpense(brief);
      await _afterCommit(brief.siteId);
      state = const AsyncValue.data(null);
      return true;
    } catch (error, stackTrace) {
      // The v2 endpoint writes the expense before creating its payment mirror.
      // Refresh server state so a partial commit is visible before any retry.
      try {
        await _refreshStudio();
      } catch (_) {
        // Keep the original mutation failure as the actionable error.
      }
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  Future<bool> _commit(
    Future<Object?> Function() operation, {
    required String siteId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await operation();
      await _afterCommit(siteId);
      state = const AsyncValue.data(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  Future<void> _afterCommit(String siteId) async {
    try {
      await _refreshStudio();
      await _onCommitted(siteId);
    } catch (_) {
      // The transaction is committed; synchronization can retry independently.
    }
  }

  void clearError() => state = const AsyncValue.data(null);
}

SiteSummary? _initialSite(List<SiteSummary> sites, String? preferredId) {
  if (preferredId != null) {
    for (final site in sites) {
      if (site.id == preferredId) return site;
    }
  }
  return sites.isEmpty ? null : sites.first;
}
