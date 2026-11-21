import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../sites/models/site_models.dart';
import '../../sites/providers/sites_provider.dart';
import '../data/report_image_picker.dart';
import '../data/reports_cache.dart';
import '../data/reports_remote_data_source.dart';
import '../data/reports_repository_impl.dart';
import '../models/report_models.dart';
import '../repository/reports_repository.dart';

final reportsRemoteDataSourceProvider = Provider<ReportsRemoteDataSource>(
  (ref) => const HttpReportsRemoteDataSource(),
);

final reportsCacheProvider = Provider<ReportsCache>(
  (ref) => HiveReportsCache(),
);

final reportImagePickerProvider = Provider<ReportImagePicker>(
  (ref) => DeviceReportImagePicker(),
);

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  final supportedRole =
      user?.isContractor == true ||
      user?.isSupervisor == true ||
      user?.isClient == true;
  final fieldRole = user?.isContractor == true || user?.isSupervisor == true;
  return ReportsRepositoryImpl(
    remote: ref.watch(reportsRemoteDataSourceProvider),
    cache: ref.watch(reportsCacheProvider),
    userId: user?.id ?? '',
    canView: supportedRole,
    canCreate: fieldRole,
    restrictToAssignedSites:
        user?.isSupervisor == true || user?.isClient == true,
  );
});

final reportsStudioControllerProvider =
    StateNotifierProvider<
      ReportsStudioController,
      AsyncValue<ReportsStudioData>
    >((ref) {
      final controller = ReportsStudioController(
        ref.watch(reportsRepositoryProvider),
      );
      unawaited(controller.load());
      return controller;
    });

final dailyReportBriefProvider =
    StateNotifierProvider.autoDispose<
      DailyReportBriefController,
      DailyReportBrief
    >((ref) => DailyReportBriefController());

final reportsActionControllerProvider =
    StateNotifierProvider.autoDispose<
      ReportsActionController,
      AsyncValue<void>
    >(
      (ref) => ReportsActionController(
        repository: ref.watch(reportsRepositoryProvider),
        refreshStudio: () =>
            ref.read(reportsStudioControllerProvider.notifier).refresh(),
        onCreated: (siteId) async {
          ref.invalidate(siteReportsProvider(siteId));
          ref.invalidate(siteDetailControllerProvider(siteId));
          unawaited(ref.read(dashboardControllerProvider.notifier).refresh());
        },
      ),
    );

class ReportsStudioController
    extends StateNotifier<AsyncValue<ReportsStudioData>> {
  ReportsStudioController(this._repository) : super(const AsyncValue.loading());

  final ReportsRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.fetchStudio);
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    try {
      final fresh = await _repository.fetchStudio();
      final previousSite = previous?.siteFilter;
      final retainedSite =
          previousSite != null && fresh.site(previousSite) != null
          ? previousSite
          : null;
      state = AsyncValue.data(
        fresh.copyWith(
          workspace: previous?.workspace,
          period: previous?.period,
          query: previous?.query,
          siteFilter: retainedSite,
          clearSite: retainedSite == null,
        ),
      );
    } catch (error, stackTrace) {
      if (previous == null) state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  void setWorkspace(ReportsWorkspace workspace) {
    final data = state.valueOrNull;
    if (data != null) {
      state = AsyncValue.data(data.copyWith(workspace: workspace, query: ''));
    }
  }

  void setQuery(String query) {
    final data = state.valueOrNull;
    if (data != null) state = AsyncValue.data(data.copyWith(query: query));
  }

  void setPeriod(ReportsPeriod period) {
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
}

class DailyReportBriefController extends StateNotifier<DailyReportBrief> {
  DailyReportBriefController()
    : super(DailyReportBrief.initial(referenceDate: DateTime.now()));

  void reset(ReportsStudioData data, {String? initialSiteId}) {
    SiteSummary? selected;
    if (initialSiteId != null) selected = data.site(initialSiteId);
    selected ??= data.sites.isEmpty ? null : data.sites.first;
    state = DailyReportBrief.initial(
      site: selected,
      referenceDate: data.referenceDate,
    );
  }

  void setSite(SiteSummary site) => state = state.copyWith(
    siteId: site.id,
    currentSiteProgress: site.progress,
    progress: site.progress,
  );

  void setDate(DateTime date) => state = state.copyWith(date: date);
  void setProgress(double progress) =>
      state = state.copyWith(progress: progress.round());
  void setWeather(String weather) => state = state.copyWith(weather: weather);
  void setNotes(String notes) => state = state.copyWith(notes: notes);
  void setNextDayPlan(String plan) => state = state.copyWith(nextDayPlan: plan);

  void addCompletedTask(String task) {
    final normalized = task.trim();
    if (normalized.isEmpty ||
        state.completedTasks.any(
          (item) => item.toLowerCase() == normalized.toLowerCase(),
        )) {
      return;
    }
    state = state.copyWith(
      completedTasks: [...state.completedTasks, normalized],
    );
  }

  void removeCompletedTask(String task) => state = state.copyWith(
    completedTasks: state.completedTasks.where((item) => item != task).toList(),
  );

  void addIssue(String issue) {
    final normalized = issue.trim();
    if (normalized.isEmpty ||
        state.issues.any(
          (item) => item.toLowerCase() == normalized.toLowerCase(),
        )) {
      return;
    }
    state = state.copyWith(issues: [...state.issues, normalized]);
  }

  void removeIssue(String issue) => state = state.copyWith(
    issues: state.issues.where((item) => item != issue).toList(),
  );

  void addMedia(ReportMedia media) {
    if (state.media.length >= 8 ||
        state.media.any((item) => item.url == media.url)) {
      return;
    }
    state = state.copyWith(media: [...state.media, media]);
  }

  void removeMedia(ReportMedia media) => state = state.copyWith(
    media: state.media.where((item) => item.url != media.url).toList(),
  );
}

class ReportsActionController extends StateNotifier<AsyncValue<void>> {
  ReportsActionController({
    required ReportsRepository repository,
    required Future<void> Function() refreshStudio,
    required Future<void> Function(String siteId) onCreated,
  }) : _repository = repository,
       _refreshStudio = refreshStudio,
       _onCreated = onCreated,
       super(const AsyncValue.data(null));

  final ReportsRepository _repository;
  final Future<void> Function() _refreshStudio;
  final Future<void> Function(String siteId) _onCreated;

  Future<ReportMedia?> uploadPhoto(ReportPhotoUpload upload) async {
    state = const AsyncValue.loading();
    try {
      final media = await _repository.uploadPhoto(upload);
      state = const AsyncValue.data(null);
      return media;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  Future<bool> createReport(DailyReportBrief brief) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createReport(brief);
      state = const AsyncValue.data(null);
      try {
        await _refreshStudio();
        await _onCreated(brief.siteId);
      } catch (_) {
        // The report is already committed; follow-up refresh can retry safely.
      }
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  void clearError() => state = const AsyncValue.data(null);
}
