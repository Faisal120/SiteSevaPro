import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../data/site_cache.dart';
import '../data/site_remote_data_source.dart';
import '../data/site_repository_impl.dart';
import '../models/site_models.dart';
import '../models/site_records.dart';
import '../repository/site_repository.dart';

final siteRemoteDataSourceProvider = Provider<SiteRemoteDataSource>(
  (ref) => const HttpSiteRemoteDataSource(),
);

final siteCacheProvider = Provider<SiteCache>((ref) => HiveSiteCache());

final siteRepositoryProvider = Provider<SiteRepository>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  return SiteRepositoryImpl(
    remote: ref.watch(siteRemoteDataSourceProvider),
    cache: ref.watch(siteCacheProvider),
    userId: user?.id ?? '',
  );
});

final sitesControllerProvider =
    StateNotifierProvider<SitesController, AsyncValue<SiteCollection>>((ref) {
      final controller = SitesController(ref.watch(siteRepositoryProvider));
      unawaited(controller.load());
      return controller;
    });

final siteDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<SiteDetailController, AsyncValue<SiteDetail>, String>((
      ref,
      siteId,
    ) {
      final controller = SiteDetailController(
        repository: ref.watch(siteRepositoryProvider),
        siteId: siteId,
      );
      unawaited(controller.load());
      return controller;
    });

final siteLabourProvider = FutureProvider.autoDispose
    .family<List<SiteLabour>, String>(
      (ref, siteId) => ref.watch(siteRepositoryProvider).fetchLabour(siteId),
    );

final siteMaterialsProvider = FutureProvider.autoDispose
    .family<List<SiteMaterial>, String>(
      (ref, siteId) => ref.watch(siteRepositoryProvider).fetchMaterials(siteId),
    );

final sitePaymentsProvider = FutureProvider.autoDispose
    .family<List<SitePayment>, String>(
      (ref, siteId) => ref.watch(siteRepositoryProvider).fetchPayments(siteId),
    );

final siteReportsProvider = FutureProvider.autoDispose
    .family<List<SiteReport>, String>(
      (ref, siteId) => ref.watch(siteRepositoryProvider).fetchReports(siteId),
    );

final siteAttendanceProvider = FutureProvider.autoDispose
    .family<List<SiteAttendanceDay>, String>(
      (ref, siteId) =>
          ref.watch(siteRepositoryProvider).fetchAttendance(siteId),
    );

final siteTeamProvider = FutureProvider.autoDispose<List<SiteAssignee>>(
  (ref) => ref.watch(siteRepositoryProvider).fetchTeam(),
);

final siteMutationControllerProvider =
    StateNotifierProvider.autoDispose<
      SiteMutationController,
      AsyncValue<SiteDetail?>
    >((ref) {
      return SiteMutationController(
        repository: ref.watch(siteRepositoryProvider),
        onChanged: (siteId) async {
          try {
            await ref.read(sitesControllerProvider.notifier).refresh();
          } catch (_) {
            // The server mutation already succeeded; a follow-up refresh can retry.
          }
          if (siteId != null) {
            ref.invalidate(siteDetailControllerProvider(siteId));
          }
          unawaited(ref.read(dashboardControllerProvider.notifier).refresh());
        },
      );
    });

class SitesController extends StateNotifier<AsyncValue<SiteCollection>> {
  SitesController(this._repository) : super(const AsyncValue.loading());

  final SiteRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.fetchSites);
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    try {
      final fresh = await _repository.fetchSites();
      state = AsyncValue.data(
        fresh.copyWith(query: previous?.query, filter: previous?.filter),
      );
    } catch (error, stackTrace) {
      if (previous == null) state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  void setQuery(String value) {
    final collection = state.valueOrNull;
    if (collection == null) return;
    state = AsyncValue.data(collection.copyWith(query: value));
  }

  void setFilter(SiteStatus? value) {
    final collection = state.valueOrNull;
    if (collection == null) return;
    state = AsyncValue.data(
      collection.copyWith(filter: value, clearFilter: value == null),
    );
  }
}

class SiteDetailController extends StateNotifier<AsyncValue<SiteDetail>> {
  SiteDetailController({
    required SiteRepository repository,
    required this.siteId,
  }) : _repository = repository,
       super(const AsyncValue.loading());

  final SiteRepository _repository;
  final String siteId;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.fetchSite(siteId));
  }

  Future<void> refresh() async {
    try {
      state = AsyncValue.data(await _repository.fetchSite(siteId));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class SiteMutationController extends StateNotifier<AsyncValue<SiteDetail?>> {
  SiteMutationController({
    required SiteRepository repository,
    required Future<void> Function(String? siteId) onChanged,
  }) : _repository = repository,
       _onChanged = onChanged,
       super(const AsyncValue.data(null));

  final SiteRepository _repository;
  final Future<void> Function(String? siteId) _onChanged;

  Future<SiteDetail?> create(SiteMutation mutation) async {
    state = const AsyncValue.loading();
    try {
      final site = await _repository.createSite(mutation);
      state = AsyncValue.data(site);
      await _onChanged(site.id);
      return site;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  Future<SiteDetail?> update(String siteId, SiteMutation mutation) async {
    state = const AsyncValue.loading();
    try {
      final site = await _repository.updateSite(siteId, mutation);
      state = AsyncValue.data(site);
      await _onChanged(siteId);
      return site;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  Future<bool> delete(String siteId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteSite(siteId);
      state = const AsyncValue.data(null);
      await _onChanged(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  Future<bool> assignSupervisor(String siteId, String userId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.assignSupervisor(siteId, userId);
      state = const AsyncValue.data(null);
      await _onChanged(siteId);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  Future<bool> assignClient(String siteId, String userId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.assignClient(siteId, userId);
      state = const AsyncValue.data(null);
      await _onChanged(siteId);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
}
