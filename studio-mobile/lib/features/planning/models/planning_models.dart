import '../../auth/models/auth_user.dart';

enum PlanningTab { tasks('Tasks'), schedule('Schedule'), approvals('Approvals');
  const PlanningTab(this.label);
  final String label;
}

class PlanningRecord {
  const PlanningRecord({required this.id, required this.title, required this.status, this.siteName, this.dueAt});
  factory PlanningRecord.fromJson(Map<String, dynamic> json) => PlanningRecord(
    id: '${json['id'] ?? ''}',
    title: '${json['title'] ?? json['name'] ?? json['subject'] ?? ''}'.trim(),
    status: '${json['status'] ?? 'PENDING'}'.trim(),
    siteName: _text(json['site_name'] ?? json['project_name']),
    dueAt: DateTime.tryParse('${json['due_at'] ?? json['scheduled_at'] ?? ''}')?.toLocal(),
  );
  final String id;
  final String title;
  final String status;
  final String? siteName;
  final DateTime? dueAt;
}

class PlanningSite {
  const PlanningSite({required this.id, required this.name});
  factory PlanningSite.fromJson(Map<String, dynamic> json) => PlanningSite(
    id: '${json['id'] ?? ''}',
    name: '${json['name'] ?? 'Unnamed site'}',
  );
  final String id;
  final String name;
}

class PlanningCreateInput {
  const PlanningCreateInput({
    required this.siteId,
    required this.title,
    this.date,
  });
  final String siteId;
  final String title;
  final DateTime? date;
  String? get validationMessage => siteId.trim().isEmpty
      ? 'Choose a site.'
      : title.trim().length < 2
      ? 'Enter a meaningful title.'
      : null;
  Map<String, dynamic> taskJson() => {
    'site_id': siteId,
    'title': title.trim(),
    if (date != null) 'due_at': date!.toUtc().toIso8601String(),
  };
  Map<String, dynamic> scheduleJson() => {
    'site_id': siteId,
    'title': title.trim(),
    'scheduled_at': (date ?? DateTime.now()).toUtc().toIso8601String(),
  };
}

class ApprovalDecisionInput {
  const ApprovalDecisionInput({required this.approved, this.note});
  final bool approved;
  final String? note;
  Map<String, dynamic> toJson() => {
    'decision': approved ? 'APPROVED' : 'REJECTED',
    if (note?.trim().isNotEmpty == true) 'note': note!.trim(),
  };
}

class PlanningWorkspaceData {
  const PlanningWorkspaceData({required this.user, required this.tasks, required this.schedule, required this.approvals, required this.apiAvailable, this.apiMessage});
  factory PlanningWorkspaceData.fromJson(AuthUser user, Map<String, dynamic> json) => PlanningWorkspaceData(
    user: user,
    tasks: _list(json['tasks']),
    schedule: _list(json['schedule'] ?? json['events']),
    approvals: _list(json['approvals']),
    apiAvailable: true,
  );
  factory PlanningWorkspaceData.unavailable(AuthUser user) => PlanningWorkspaceData(
    user: user, tasks: const [], schedule: const [], approvals: const [], apiAvailable: false,
    apiMessage: 'Tasks, schedule and approvals are not enabled by the backend yet.',
  );
  final AuthUser user;
  final List<PlanningRecord> tasks;
  final List<PlanningRecord> schedule;
  final List<PlanningRecord> approvals;
  final bool apiAvailable;
  final String? apiMessage;
  List<PlanningRecord> forTab(PlanningTab tab) => switch (tab) { PlanningTab.tasks => tasks, PlanningTab.schedule => schedule, PlanningTab.approvals => approvals };
}

List<PlanningRecord> _list(Object? value) => value is List
    ? value.whereType<Map>().map((item) => PlanningRecord.fromJson(item.map((key, value) => MapEntry('$key', value)))).where((item) => item.title.isNotEmpty).toList(growable: false)
    : const [];
String? _text(Object? value) { final text = '${value ?? ''}'.trim(); return text.isEmpty ? null : text; }
