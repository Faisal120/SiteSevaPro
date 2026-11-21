import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/features/assistant/models/assistant_models.dart';
import 'package:siteseva/features/auth/models/auth_user.dart';

void main() {
  const user = AuthUser(id: 'u1', email: 'a@s.test', fullName: 'Aarav', role: 'CONTRACTOR', siteIds: [], blocked: false);

  test('assistant workspace uses only returned messages', () {
    final data = AssistantWorkspaceData.fromJson(user, {
      'messages': [
        {'id': 'm1', 'role': 'ASSISTANT', 'content': 'Live backend response'},
      ],
    });
    expect(data.messages.single.isAssistant, isTrue);
    expect(data.messages.single.content, 'Live backend response');
  });

  test('empty assistant prompt cannot be sent', () {
    expect(const AssistantPrompt(' ').validationMessage, isNotNull);
  });
}
