import '../../auth/models/auth_user.dart';

class AssistantMessage {
  const AssistantMessage({
    required this.id,
    required this.content,
    required this.isAssistant,
    this.createdAt,
  });

  factory AssistantMessage.fromJson(Map<String, dynamic> json) =>
      AssistantMessage(
        id: '${json['id'] ?? ''}',
        content:
            '${json['content'] ?? json['message'] ?? json['insight'] ?? json['response'] ?? json['result'] ?? ''}'
                .trim(),
        isAssistant: '${json['role'] ?? json['sender'] ?? ''}'
            .toUpperCase()
            .contains('ASSISTANT'),
        createdAt: DateTime.tryParse('${json['created_at'] ?? ''}')?.toLocal(),
      );

  final String id;
  final String content;
  final bool isAssistant;
  final DateTime? createdAt;
}

class AssistantWorkspaceData {
  const AssistantWorkspaceData({
    required this.user,
    required this.messages,
    required this.apiAvailable,
    this.apiMessage,
  });

  factory AssistantWorkspaceData.fromJson(AuthUser user, Map<String, dynamic> json) =>
      AssistantWorkspaceData(
        user: user,
        messages: _maps(json['messages'])
            .map(AssistantMessage.fromJson)
            .where((message) => message.content.isNotEmpty)
            .toList(growable: false),
        apiAvailable: true,
      );

  factory AssistantWorkspaceData.unavailable(AuthUser user) =>
      AssistantWorkspaceData(
        user: user,
        messages: const [],
        apiAvailable: false,
        apiMessage: 'The AI Assistant service is not enabled by the backend yet.',
      );

  factory AssistantWorkspaceData.ready(AuthUser user) =>
      AssistantWorkspaceData(
        user: user,
        messages: const [],
        apiAvailable: true,
      );

  final AuthUser user;
  final List<AssistantMessage> messages;
  final bool apiAvailable;
  final String? apiMessage;
}

class AssistantPrompt {
  const AssistantPrompt(this.text);
  final String text;

  String? get validationMessage => text.trim().isEmpty ? 'Enter a question for SiteSeva AI.' : null;
  Map<String, dynamic> toJson() => {'message': text.trim()};
}

List<Map<String, dynamic>> _maps(Object? value) => value is List
    ? value.whereType<Map>().map((item) => item.map((key, value) => MapEntry('$key', value))).toList(growable: false)
    : const [];
