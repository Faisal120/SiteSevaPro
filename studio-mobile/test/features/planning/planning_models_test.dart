import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/features/auth/models/auth_user.dart';
import 'package:siteseva/features/planning/models/planning_models.dart';

void main() {
  const user = AuthUser(id: 'u1', email: 'a@s.test', fullName: 'Aarav', role: 'CONTRACTOR', siteIds: [], blocked: false);

  test('planning workspace separates tasks, schedule and approvals from backend payload', () {
    final data = PlanningWorkspaceData.fromJson(user, {
      'tasks': [{'id': 'task-1', 'title': 'Pour slab', 'status': 'OPEN'}],
      'schedule': [{'id': 'event-1', 'title': 'Inspection', 'status': 'SCHEDULED'}],
      'approvals': [{'id': 'approval-1', 'title': 'Approve BOQ', 'status': 'PENDING'}],
    });
    expect(data.forTab(PlanningTab.tasks).single.title, 'Pour slab');
    expect(data.forTab(PlanningTab.schedule).single.status, 'SCHEDULED');
    expect(data.forTab(PlanningTab.approvals).single.id, 'approval-1');
  });

  test('unavailable planning state has no fabricated records', () {
    final data = PlanningWorkspaceData.unavailable(user);
    expect(data.apiAvailable, isFalse);
    expect(data.tasks, isEmpty);
  });
}
