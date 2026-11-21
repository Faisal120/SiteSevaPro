import '../../../core/network/api_service.dart';

abstract interface class AssistantRemoteDataSource {
  Future<Map<String, dynamic>> fetchConversation();
  Future<Map<String, dynamic>> sendMessage(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> requestInsight(Map<String, dynamic> payload);
}

class HttpAssistantRemoteDataSource implements AssistantRemoteDataSource {
  const HttpAssistantRemoteDataSource();

  @override
  Future<Map<String, dynamic>> fetchConversation() => ApiService.getAiAssistantConversation();

  @override
  Future<Map<String, dynamic>> sendMessage(Map<String, dynamic> payload) =>
      ApiService.sendAiAssistantMessage(payload);

  @override
  Future<Map<String, dynamic>> requestInsight(Map<String, dynamic> payload) =>
      ApiService.getAiInsight(payload);
}
