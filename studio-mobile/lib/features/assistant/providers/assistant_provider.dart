import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/assistant_remote_data_source.dart';
import '../data/assistant_repository_impl.dart';
import '../models/assistant_models.dart';
import '../repository/assistant_repository.dart';

final assistantRemoteDataSourceProvider = Provider<AssistantRemoteDataSource>(
  (ref) => const HttpAssistantRemoteDataSource(),
);

final assistantRepositoryProvider = Provider<AssistantRepository>(
  (ref) => AssistantRepositoryImpl(
    remote: ref.watch(assistantRemoteDataSourceProvider),
    user: ref.watch(authControllerProvider).valueOrNull,
  ),
);

final assistantControllerProvider =
    StateNotifierProvider.autoDispose<
      AssistantController,
      AsyncValue<AssistantWorkspaceData>
    >((ref) {
      final controller = AssistantController(
        ref.watch(assistantRepositoryProvider),
      );
      unawaited(controller.load());
      return controller;
    });

class AssistantController
    extends StateNotifier<AsyncValue<AssistantWorkspaceData>> {
  AssistantController(this._repository) : super(const AsyncValue.loading());
  final AssistantRepository _repository;

  Future<void> load() async {
    state = await AsyncValue.guard(_repository.fetchWorkspace);
  }

  Future<void> send(AssistantPrompt prompt) async {
    final previous = state.valueOrNull;
    if (previous == null || !previous.apiAvailable) return;
    final reply = await _repository.sendPrompt(prompt);
    final sent = AssistantMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      content: prompt.text.trim(),
      isAssistant: false,
      createdAt: DateTime.now(),
    );
    state = AsyncValue.data(
      AssistantWorkspaceData(
        user: previous.user,
        messages: [...previous.messages, sent, reply],
        apiAvailable: true,
      ),
    );
  }
}
