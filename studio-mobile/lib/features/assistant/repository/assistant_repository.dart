import '../models/assistant_models.dart';

abstract interface class AssistantRepository {
  Future<AssistantWorkspaceData> fetchWorkspace();
  Future<AssistantMessage> sendPrompt(AssistantPrompt prompt);
}
