import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/document_cache.dart';
import '../data/document_file_picker.dart';
import '../data/document_remote_data_source.dart';
import '../data/document_repository_impl.dart';
import '../models/document_models.dart';
import '../repository/document_repository.dart';

final documentRemoteDataSourceProvider = Provider<DocumentRemoteDataSource>(
  (ref) => const HttpDocumentRemoteDataSource(),
);

final documentCacheProvider = Provider<DocumentCache>(
  (ref) => HiveDocumentCache(),
);

final documentFilePickerProvider = Provider<DocumentFilePicker>(
  (ref) => const DeviceDocumentFilePicker(),
);

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  return DocumentRepositoryImpl(
    remote: ref.watch(documentRemoteDataSourceProvider),
    cache: ref.watch(documentCacheProvider),
    userId: user?.id ?? '',
    role: user?.role ?? '',
  );
});

final documentControllerProvider = StateNotifierProvider<
  DocumentController,
  AsyncValue<DocumentsWorkspaceData>
>((ref) {
  final controller = DocumentController(ref.watch(documentRepositoryProvider));
  unawaited(controller.load());
  return controller;
});

final documentActionControllerProvider = StateNotifierProvider.autoDispose<
  DocumentActionController,
  DocumentActionState
>((ref) => DocumentActionController(
  repository: ref.watch(documentRepositoryProvider),
  onChanged: () => ref.read(documentControllerProvider.notifier).refresh(),
));

class DocumentController
    extends StateNotifier<AsyncValue<DocumentsWorkspaceData>> {
  DocumentController(this._repository) : super(const AsyncValue.loading());

  final DocumentRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.fetchWorkspace);
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    try {
      final fresh = await _repository.fetchWorkspace();
      state = AsyncValue.data(
        fresh.copyWith(
          query: previous?.query,
          kind: previous?.kind,
          siteId: previous?.siteId,
          clearKind: previous?.kind == null,
          clearSite: previous?.siteId == null,
        ),
      );
    } catch (error, stackTrace) {
      if (previous == null) state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  void setQuery(String query) {
    final data = state.valueOrNull;
    if (data != null) state = AsyncValue.data(data.copyWith(query: query));
  }

  void setKind(DocumentKind? kind) {
    final data = state.valueOrNull;
    if (data != null) {
      state = AsyncValue.data(
        data.copyWith(kind: kind, clearKind: kind == null),
      );
    }
  }

  void setSite(String? siteId) {
    final data = state.valueOrNull;
    if (data != null) {
      state = AsyncValue.data(
        data.copyWith(siteId: siteId, clearSite: siteId == null),
      );
    }
  }
}

enum DocumentActionPhase { idle, uploading, mutating, downloading }

class DocumentActionState {
  const DocumentActionState({
    this.phase = DocumentActionPhase.idle,
    this.value = const AsyncValue.data(null),
  });

  final DocumentActionPhase phase;
  final AsyncValue<Object?> value;

  bool get isLoading => value.isLoading;
}

class DocumentActionController extends StateNotifier<DocumentActionState> {
  DocumentActionController({required this.repository, required this.onChanged})
    : super(const DocumentActionState());

  final DocumentRepository repository;
  final Future<void> Function() onChanged;

  Future<bool> upload(
    DocumentFileAsset asset,
    DocumentUploadInput input,
  ) async {
    final result = await _run(
      () async {
        await repository.upload(asset, input);
        await onChanged();
      },
      phase: DocumentActionPhase.uploading,
    );
    return result;
  }

  Future<bool> delete(String id) async => _run(
    () async {
      await repository.delete(id);
      await onChanged();
    },
    phase: DocumentActionPhase.mutating,
  );

  Future<bool> updateSharing(String id, bool sharedWithClient) async => _run(
    () async {
      await repository.updateSharing(id, sharedWithClient);
      await onChanged();
    },
    phase: DocumentActionPhase.mutating,
  );

  Future<Uint8List?> download(DocumentRecord document) async {
    state = const DocumentActionState(
      phase: DocumentActionPhase.downloading,
      value: AsyncValue.loading(),
    );
    try {
      final bytes = await repository.download(document);
      state = const DocumentActionState(
        phase: DocumentActionPhase.downloading,
        value: AsyncValue.data(true),
      );
      return bytes;
    } catch (error, stackTrace) {
      state = DocumentActionState(
        phase: DocumentActionPhase.downloading,
        value: AsyncValue.error(error, stackTrace),
      );
      return null;
    }
  }

  Future<bool> _run(
    Future<void> Function() action, {
    required DocumentActionPhase phase,
  }) async {
    state = DocumentActionState(
      phase: phase,
      value: const AsyncValue.loading(),
    );
    try {
      await action();
      state = DocumentActionState(
        phase: phase,
        value: const AsyncValue.data(true),
      );
      return true;
    } catch (error, stackTrace) {
      state = DocumentActionState(
        phase: phase,
        value: AsyncValue.error(error, stackTrace),
      );
      return false;
    }
  }
}
