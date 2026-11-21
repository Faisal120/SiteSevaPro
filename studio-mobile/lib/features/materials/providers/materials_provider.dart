import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/materials_cache.dart';
import '../data/materials_remote_data_source.dart';
import '../data/materials_repository_impl.dart';
import '../models/material_models.dart';
import '../repository/materials_repository.dart';

final materialsRemoteDataSourceProvider = Provider<MaterialsRemoteDataSource>(
  (ref) => const HttpMaterialsRemoteDataSource(),
);

final materialsCacheProvider = Provider<MaterialsCache>(
  (ref) => HiveMaterialsCache(),
);

final materialsRepositoryProvider = Provider<MaterialsRepository>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  final fieldRole = user?.isContractor == true || user?.isSupervisor == true;
  return MaterialsRepositoryImpl(
    remote: ref.watch(materialsRemoteDataSourceProvider),
    cache: ref.watch(materialsCacheProvider),
    userId: user?.id ?? '',
    canView: fieldRole,
    canManageStock: fieldRole,
    canManageVendors: user?.isContractor == true,
    restrictMovementsToAssignedSites: user?.isSupervisor == true,
  );
});

final materialsStudioControllerProvider =
    StateNotifierProvider<
      MaterialsStudioController,
      AsyncValue<MaterialsStudioData>
    >((ref) {
      final controller = MaterialsStudioController(
        ref.watch(materialsRepositoryProvider),
      );
      unawaited(controller.load());
      return controller;
    });

final materialCreationBriefProvider =
    StateNotifierProvider.autoDispose<
      MaterialCreationBriefController,
      MaterialCreationBrief
    >((ref) => MaterialCreationBriefController());

final materialMovementBriefProvider = StateNotifierProvider.autoDispose
    .family<
      MaterialMovementBriefController,
      MaterialMovementBrief,
      MaterialItem
    >((ref, material) => MaterialMovementBriefController(material));

final materialVendorBriefProvider =
    StateNotifierProvider.autoDispose<
      MaterialVendorBriefController,
      MaterialVendorBrief
    >((ref) => MaterialVendorBriefController());

final materialsActionControllerProvider =
    StateNotifierProvider.autoDispose<
      MaterialsActionController,
      AsyncValue<void>
    >(
      (ref) => MaterialsActionController(
        repository: ref.watch(materialsRepositoryProvider),
        refreshStudio: () =>
            ref.read(materialsStudioControllerProvider.notifier).refresh(),
      ),
    );

class MaterialsStudioController
    extends StateNotifier<AsyncValue<MaterialsStudioData>> {
  MaterialsStudioController(this._repository)
    : super(const AsyncValue.loading());

  final MaterialsRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.fetchStudio);
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    try {
      final fresh = await _repository.fetchStudio();
      state = AsyncValue.data(
        fresh.copyWith(
          workspace: previous?.workspace,
          query: previous?.query,
          siteFilter: previous?.siteFilter,
          categoryFilter: previous?.categoryFilter,
          lowStockOnly: previous?.lowStockOnly,
        ),
      );
    } catch (error, stackTrace) {
      if (previous == null) state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  void setWorkspace(MaterialsWorkspace workspace) {
    final data = state.valueOrNull;
    if (data == null) return;
    state = AsyncValue.data(data.copyWith(workspace: workspace, query: ''));
  }

  void setQuery(String query) {
    final data = state.valueOrNull;
    if (data != null) state = AsyncValue.data(data.copyWith(query: query));
  }

  void setSite(String? siteId) {
    final data = state.valueOrNull;
    if (data == null) return;
    state = AsyncValue.data(
      data.copyWith(siteFilter: siteId, clearSite: siteId == null),
    );
  }

  void setCategory(MaterialCategory? category) {
    final data = state.valueOrNull;
    if (data == null) return;
    state = AsyncValue.data(
      data.copyWith(categoryFilter: category, clearCategory: category == null),
    );
  }

  void toggleLowStock() {
    final data = state.valueOrNull;
    if (data != null) {
      state = AsyncValue.data(data.copyWith(lowStockOnly: !data.lowStockOnly));
    }
  }
}

class MaterialCreationBriefController
    extends StateNotifier<MaterialCreationBrief> {
  MaterialCreationBriefController() : super(MaterialCreationBrief.initial());

  void reset() => state = MaterialCreationBrief.initial();
  void setSite(String value) => state = state.copyWith(siteId: value);
  void setName(String value) => state = state.copyWith(name: value);
  void setCategory(MaterialCategory value) =>
      state = state.copyWith(category: value);
  void setUnit(String value) => state = state.copyWith(unit: value);
  void setOpeningStock(String value) =>
      state = state.copyWith(openingStock: double.tryParse(value.trim()) ?? 0);
  void setThreshold(String value) => state = state.copyWith(
    lowStockThreshold: double.tryParse(value.trim()) ?? 0,
  );
  void setRate(String value) =>
      state = state.copyWith(rate: double.tryParse(value.trim()) ?? 0);
}

class MaterialMovementBriefController
    extends StateNotifier<MaterialMovementBrief> {
  MaterialMovementBriefController(MaterialItem material)
    : super(MaterialMovementBrief.initial(material));

  void setType(MaterialMovementType value) =>
      state = state.copyWith(type: value);
  void setQuantity(String value) =>
      state = state.copyWith(quantity: double.tryParse(value.trim()) ?? 0);
  void setRate(String value) =>
      state = state.copyWith(rate: double.tryParse(value.trim()) ?? 0);
  void setVendor(String value) => state = state.copyWith(vendor: value);
  void setNote(String value) => state = state.copyWith(note: value);
  void setInvoiceUrl(String value) => state = state.copyWith(invoiceUrl: value);
}

class MaterialVendorBriefController extends StateNotifier<MaterialVendorBrief> {
  MaterialVendorBriefController() : super(MaterialVendorBrief.initial());

  void reset() => state = MaterialVendorBrief.initial();
  void setName(String value) => state = state.copyWith(name: value);
  void setContact(String value) => state = state.copyWith(contact: value);
  void setGst(String value) => state = state.copyWith(gst: value);
  void setAddress(String value) => state = state.copyWith(address: value);
  void setPaymentTerms(String value) =>
      state = state.copyWith(paymentTerms: value);
  void setCategories(List<String> value) =>
      state = state.copyWith(categories: value);
}

class MaterialsActionController extends StateNotifier<AsyncValue<void>> {
  MaterialsActionController({
    required MaterialsRepository repository,
    required Future<void> Function() refreshStudio,
  }) : _repository = repository,
       _refreshStudio = refreshStudio,
       super(const AsyncValue.data(null));

  final MaterialsRepository _repository;
  final Future<void> Function() _refreshStudio;

  Future<bool> createMaterial(MaterialCreationBrief brief) =>
      _mutate(() => _repository.createMaterial(brief));

  Future<bool> createMovement(MaterialMovementBrief brief) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createMovement(brief);
      await _refreshStudio();
      state = const AsyncValue.data(null);
      return true;
    } catch (error, stackTrace) {
      // The current backend can mutate stock before returning an error. Refresh
      // once so the user sees server state and does not blindly retry.
      try {
        await _refreshStudio();
      } catch (_) {
        // Preserve the original mutation error, which is the actionable one.
      }
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  Future<bool> createVendor(MaterialVendorBrief brief) =>
      _mutate(() => _repository.createVendor(brief));

  Future<bool> deleteVendor(String vendorId) =>
      _mutate(() => _repository.deleteVendor(vendorId));

  Future<bool> _mutate(Future<Object?> Function() operation) async {
    state = const AsyncValue.loading();
    try {
      await operation();
      await _refreshStudio();
      state = const AsyncValue.data(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
}
