import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/planning_models.dart';
import '../../providers/planning_provider.dart';

class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({super.key});
  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends ConsumerState<PlanningScreen> {
  PlanningTab _tab = PlanningTab.tasks;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(planningControllerProvider);
    return AppPage(
      title: 'Planning',
      subtitle: 'Tasks, schedule and approvals across active construction sites.',
      actions: [
        IconButton(onPressed: () => ref.read(planningControllerProvider.notifier).load(), icon: const Icon(Icons.refresh_rounded)),
        if (_canCreate(ref))
          IconButton.filled(
            tooltip: _tab == PlanningTab.tasks ? 'Create task' : 'Create schedule',
            onPressed: _tab == PlanningTab.approvals ? null : () => _openCreateSheet(context),
            icon: const Icon(Icons.add_rounded),
            style: IconButton.styleFrom(backgroundColor: AppTheme.blue),
          ),
      ],
      child: state.when(
        loading: () => ListView(padding: const EdgeInsets.all(20), children: const [AppSkeleton(height: 170), SizedBox(height: 14), AppSkeleton(height: 220)]),
        error: (error, _) => ListView(padding: const EdgeInsets.all(20), children: [EmptyPanel(title: 'Planning unavailable', message: '$error', icon: Icons.event_note_outlined, actionLabel: 'Retry', onAction: () => ref.read(planningControllerProvider.notifier).load())]),
        data: _body,
      ),
    );
  }

  bool _canCreate(WidgetRef ref) {
    final user = ref.read(planningControllerProvider).valueOrNull?.user;
    return user?.isContractor == true || user?.isSupervisor == true;
  }

  Future<void> _openCreateSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreatePlanningSheet(tab: _tab),
    );
  }

  Widget _body(PlanningWorkspaceData data) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
    children: [
      _PlanningHero(data: data).animate().fadeIn(duration: 260.ms).slideY(begin: .05, end: 0),
      const SizedBox(height: 16),
      _Tabs(selected: _tab, onChanged: (value) => setState(() => _tab = value)),
      const SizedBox(height: 16),
      if (!data.apiAvailable)
        EmptyPanel(title: 'Planning backend pending', message: data.apiMessage ?? 'Planning is unavailable.', icon: Icons.hub_outlined)
      else if (data.forTab(_tab).isEmpty)
        EmptyPanel(title: 'No ${_tab.label.toLowerCase()} returned', message: 'This workspace has no ${_tab.label.toLowerCase()} records from the backend.', icon: _icon(_tab), actionLabel: _canCreate(ref) && _tab != PlanningTab.approvals ? 'Create ${_tab == PlanningTab.tasks ? 'task' : 'schedule'}' : null, onAction: _canCreate(ref) && _tab != PlanningTab.approvals ? () => _openCreateSheet(context) : null)
      else
        SurfaceCard(padding: EdgeInsets.zero, child: Column(children: data.forTab(_tab).map((record) => _Record(record: record, tab: _tab)).toList(growable: false))),
    ],
  );

  IconData _icon(PlanningTab tab) => switch (tab) { PlanningTab.tasks => Icons.task_alt_rounded, PlanningTab.schedule => Icons.calendar_month_outlined, PlanningTab.approvals => Icons.verified_user_outlined };
}

class _PlanningHero extends StatelessWidget {
  const _PlanningHero({required this.data});
  final PlanningWorkspaceData data;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), gradient: const LinearGradient(colors: [Color(0xFF0A1323), Color(0xFF1C3763)])),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.account_tree_outlined, color: Color(0xFFBBD8FF), size: 30),
      const SizedBox(height: 20),
      Text(data.apiAvailable ? '${data.tasks.length} tasks · ${data.approvals.length} approvals' : 'One connected planning command center', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      Text('Only role-authorized records returned from FastAPI are shown here.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFFCCDDF7))),
    ]),
  );
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.selected, required this.onChanged});
  final PlanningTab selected;
  final ValueChanged<PlanningTab> onChanged;
  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.all(5),
    child: Row(
      children: PlanningTab.values
          .map(
            (tab) => Expanded(
              child: InkWell(
                onTap: () => onChanged(tab),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: selected == tab ? AppTheme.ink : Colors.transparent,
                  ),
                  child: Text(
                    tab.label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected == tab ? Colors.white : AppTheme.muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    ),
  );
}

class _Record extends ConsumerWidget {
  const _Record({required this.record, required this.tab});
  final PlanningRecord record;
  final PlanningTab tab;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    leading: Icon(switch (tab) { PlanningTab.tasks => Icons.task_alt_rounded, PlanningTab.schedule => Icons.calendar_month_outlined, PlanningTab.approvals => Icons.verified_user_outlined }, color: AppTheme.blue),
    title: Text(record.title, style: const TextStyle(fontWeight: FontWeight.w800)),
    subtitle: Text([if (record.siteName != null) record.siteName!, if (record.dueAt != null) appDate(record.dueAt)].join(' · ')),
    trailing: tab == PlanningTab.approvals && _canDecide(ref)
        ? PopupMenuButton<bool>(
            tooltip: 'Decide approval',
            onSelected: (approved) => _decide(context, ref, approved),
            itemBuilder: (context) => const [
              PopupMenuItem(value: true, child: Text('Approve')),
              PopupMenuItem(value: false, child: Text('Reject')),
            ],
            child: StatusBadge(label: record.status),
          )
        : StatusBadge(label: record.status),
  );

  bool _canDecide(WidgetRef ref) {
    final user = ref.read(planningControllerProvider).valueOrNull?.user;
    return user?.isContractor == true || user?.isClient == true;
  }

  Future<void> _decide(BuildContext context, WidgetRef ref, bool approved) async {
    final completed = await ref.read(planningActionControllerProvider.notifier).decideApproval(record.id, ApprovalDecisionInput(approved: approved));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(completed ? 'Approval ${approved ? 'approved' : 'rejected'}.' : '${ref.read(planningActionControllerProvider).error ?? 'Could not submit the decision.'}')));
  }
}

class _CreatePlanningSheet extends ConsumerStatefulWidget {
  const _CreatePlanningSheet({required this.tab});
  final PlanningTab tab;
  @override
  ConsumerState<_CreatePlanningSheet> createState() => _CreatePlanningSheetState();
}

class _CreatePlanningSheetState extends ConsumerState<_CreatePlanningSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  String? _siteId;
  DateTime? _date;
  @override
  void dispose() { _title.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final sites = ref.watch(planningSitesProvider);
    final action = ref.watch(planningActionControllerProvider);
    final isTask = widget.tab == PlanningTab.tasks;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: SurfaceCard(
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isTask ? 'Create live task' : 'Schedule site event', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('This is saved directly to the role-scoped planning API.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.muted)),
            const SizedBox(height: 16),
            sites.when(
              loading: () => const AppSkeleton(height: 56, radius: 18),
              error: (error, _) => Text('Sites could not be loaded: $error', style: const TextStyle(color: AppTheme.danger)),
              data: (items) => DropdownButtonFormField<String>(
                initialValue: _siteId,
                decoration: const InputDecoration(labelText: 'Site'),
                items: items.map((site) => DropdownMenuItem(value: site.id, child: Text(site.name))).toList(growable: false),
                validator: (value) => value == null ? 'Choose a site.' : null,
                onChanged: action.isLoading ? null : (value) => setState(() => _siteId = value),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _title, decoration: InputDecoration(labelText: isTask ? 'Task title' : 'Event title'), validator: (value) => value == null || value.trim().length < 2 ? 'Enter a meaningful title.' : null),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: action.isLoading ? null : _pickDate, icon: const Icon(Icons.calendar_month_outlined), label: Text(_date == null ? (isTask ? 'Optional due date' : 'Choose event date') : appDate(_date))),
            const SizedBox(height: 18),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.blue),
              onPressed: action.isLoading ? null : () => _submit(isTask),
              icon: action.isLoading ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cloud_upload_outlined),
              label: Text(action.isLoading ? 'Saving...' : isTask ? 'Create task' : 'Schedule event'),
            )),
          ]),
        ),
      ),
    );
  }
  Future<void> _pickDate() async { final date = await showDatePicker(context: context, initialDate: _date ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100)); if (date != null && mounted) setState(() => _date = date); }
  Future<void> _submit(bool isTask) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final input = PlanningCreateInput(siteId: _siteId!, title: _title.text, date: _date);
    final controller = ref.read(planningActionControllerProvider.notifier);
    final success = isTask ? await controller.createTask(input) : await controller.createSchedule(input);
    if (success && mounted) Navigator.of(context).pop();
  }
}
