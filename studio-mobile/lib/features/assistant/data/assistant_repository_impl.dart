import '../../../core/network/api_service.dart';
import '../../auth/models/auth_user.dart';
import '../models/assistant_models.dart';
import '../repository/assistant_repository.dart';
import 'assistant_remote_data_source.dart';

class AssistantRepositoryImpl implements AssistantRepository {
  const AssistantRepositoryImpl({required AssistantRemoteDataSource remote, required AuthUser? user})
      : _remote = remote,
        _user = user;

  final AssistantRemoteDataSource _remote;
  final AuthUser? _user;

  @override
  Future<AssistantWorkspaceData> fetchWorkspace() async {
    final user = _requireUser();
    try {
      return AssistantWorkspaceData.fromJson(user, await _remote.fetchConversation());
    } on ApiException catch (error) {
      if (error.statusCode == 404) return AssistantWorkspaceData.ready(user);
      rethrow;
    }
  }

  @override
  Future<AssistantMessage> sendPrompt(AssistantPrompt prompt) async {
    final validation = prompt.validationMessage;
    if (validation != null) throw ApiException(validation, kind: ApiErrorKind.invalidResponse);
    try {
      final payload = await _remote.sendMessage(prompt.toJson());
      return AssistantMessage.fromJson(payload['message'] is Map
          ? (payload['message'] as Map).map((key, value) => MapEntry('$key', value))
          : payload);
    } on ApiException catch (error) {
      if (error.statusCode != 404) rethrow;
      final payload = await _remote.requestInsight({
        'kind': _insightKind(prompt.text),
        'context': {'request': prompt.text.trim()},
      });
      return AssistantMessage.fromJson({
        ...payload,
        'id': payload['id'] ?? 'insight-${DateTime.now().microsecondsSinceEpoch}',
        'role': 'ASSISTANT',
      });
    }
  }

  AuthUser _requireUser() => _user ?? (throw const ApiException('Sign in again to use SiteSeva AI.', statusCode: 401, kind: ApiErrorKind.authentication));

  String _insightKind(String prompt) {
    final query = prompt.toLowerCase();
    if (query.contains('material') || query.contains('cement') || query.contains('steel')) {
      return 'material_estimate';
    }
    if (query.contains('delay') || query.contains('late') || query.contains('risk')) {
      return 'delay_prediction';
    }
    if (query.contains('expense') || query.contains('profit') || query.contains('cash')) {
      return 'expense_analysis';
    }
    return 'progress_summary';
  }
}
