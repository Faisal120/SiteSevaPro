import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/site_models.dart';
import '../../providers/sites_provider.dart';
import 'site_widgets.dart';

Future<SiteDetail?> showSiteFormSheet(
  BuildContext context,
  WidgetRef ref, {
  SiteDetail? initial,
}) {
  ref.invalidate(siteMutationControllerProvider);
  return showModalBottomSheet<SiteDetail>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _SiteFormSheet(initial: initial),
  );
}

class _SiteFormSheet extends ConsumerStatefulWidget {
  const _SiteFormSheet({this.initial});

  final SiteDetail? initial;

  @override
  ConsumerState<_SiteFormSheet> createState() => _SiteFormSheetState();
}

class _SiteFormSheetState extends ConsumerState<_SiteFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _location;
  late final TextEditingController _budget;
  late final TextEditingController _floors;
  late final TextEditingController _description;
  late final TextEditingController _coverImage;
  late DateTime _startDate;
  late DateTime _endDate;
  late SiteStatus _status;
  late double _progress;
  late bool _hasBoring;
  late bool _hasSepticTank;
  late bool _hasSoakPit;
  late bool _hasMumty;
  late Set<String> _supervisorIds;
  String? _clientId;

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final site = widget.initial;
    final now = DateTime.now();
    _name = TextEditingController(text: site?.name);
    _location = TextEditingController(text: site?.location);
    _budget = TextEditingController(
      text: site == null ? '' : site.budget.toStringAsFixed(0),
    );
    _floors = TextEditingController(text: '${site?.floors ?? 1}');
    _description = TextEditingController(text: site?.description);
    _coverImage = TextEditingController(text: site?.coverImage);
    _startDate = site?.startDate ?? now;
    _endDate = site?.endDate ?? now.add(const Duration(days: 180));
    _status = site?.status ?? SiteStatus.active;
    _progress = (site?.progress ?? 0).toDouble();
    _hasBoring = site?.hasBoring ?? false;
    _hasSepticTank = site?.hasSepticTank ?? true;
    _hasSoakPit = site?.hasSoakPit ?? true;
    _hasMumty = site?.hasMumty ?? true;
    _supervisorIds = {...?site?.supervisorIds};
    _clientId = site?.clientId;
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _budget.dispose();
    _floors.dispose();
    _description.dispose();
    _coverImage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mutation = ref.watch(siteMutationControllerProvider);
    final team = ref.watch(siteTeamProvider);
    final busy = mutation.isLoading;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 24, 12, bottomInset + 12),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 760,
            maxHeight: MediaQuery.sizeOf(context).height * .92,
          ),
          child: Material(
            color: Theme.of(context).cardColor,
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(32),
            child: Column(
              children: [
                _FormHeader(editing: _editing),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (mutation.hasError) ...[
                            _FormError(message: '${mutation.error}'),
                            const SizedBox(height: 16),
                          ],
                          const _FormSectionLabel('PROJECT IDENTITY'),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _name,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Site name',
                              hintText: 'e.g. Orchid Residence',
                              prefixIcon: Icon(Icons.apartment_outlined),
                            ),
                            validator: _required('Site name'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _location,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Location',
                              hintText: 'Area, city',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                            validator: _required('Location'),
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final stacked = constraints.maxWidth < 480;
                              final budget = TextFormField(
                                controller: _budget,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Approved budget',
                                  prefixText: 'INR  ',
                                ),
                                validator: _positiveNumber('Budget'),
                              );
                              final floors = TextFormField(
                                controller: _floors,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Floors',
                                  prefixIcon: Icon(Icons.layers_outlined),
                                ),
                                validator: (value) {
                                  final parsed = int.tryParse(value ?? '');
                                  if (parsed == null || parsed < 1) {
                                    return 'Enter at least 1';
                                  }
                                  return null;
                                },
                              );
                              if (stacked) {
                                return Column(
                                  children: [
                                    budget,
                                    const SizedBox(height: 12),
                                    floors,
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  Expanded(flex: 2, child: budget),
                                  const SizedBox(width: 12),
                                  Expanded(child: floors),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _description,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Project brief',
                              hintText:
                                  'Scope, build type and delivery context',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _coverImage,
                            keyboardType: TextInputType.url,
                            decoration: const InputDecoration(
                              labelText: 'Cover image URL',
                              hintText: 'Cloudinary HTTPS URL (optional)',
                              prefixIcon: Icon(Icons.image_outlined),
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) return null;
                              final uri = Uri.tryParse(text);
                              return uri != null && uri.hasScheme
                                  ? null
                                  : 'Enter a valid image URL';
                            },
                          ),
                          const SizedBox(height: 24),
                          const _FormSectionLabel('PROJECT TEAM'),
                          const SizedBox(height: 10),
                          _TeamAssignmentFields(
                            team: team,
                            supervisorIds: _supervisorIds,
                            clientId: _clientId,
                            enabled: !busy,
                            onSupervisorsChanged: (ids) =>
                                setState(() => _supervisorIds = ids),
                            onClientChanged: (id) =>
                                setState(() => _clientId = id),
                          ),
                          const SizedBox(height: 24),
                          const _FormSectionLabel('PROJECT SCHEDULE'),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _DateField(
                                  label: 'Start date',
                                  value: _startDate,
                                  onTap: () => _pickDate(start: true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DateField(
                                  label: 'Target date',
                                  value: _endDate,
                                  onTap: () => _pickDate(start: false),
                                ),
                              ),
                            ],
                          ),
                          if (_editing) ...[
                            const SizedBox(height: 24),
                            const _FormSectionLabel('DELIVERY STATUS'),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<SiteStatus>(
                              initialValue: _status,
                              decoration: const InputDecoration(
                                labelText: 'Project status',
                              ),
                              items: SiteStatus.values
                                  .map(
                                    (status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: busy
                                  ? null
                                  : (value) => setState(
                                      () => _status = value ?? _status,
                                    ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Text(
                                  'Verified progress',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const Spacer(),
                                Text(
                                  '${_progress.round()}%',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: AppTheme.orange,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _progress,
                              max: 100,
                              divisions: 100,
                              activeColor: AppTheme.orange,
                              onChanged: busy
                                  ? null
                                  : (value) =>
                                        setState(() => _progress = value),
                            ),
                          ],
                          const SizedBox(height: 20),
                          const _FormSectionLabel('SITE INFRASTRUCTURE'),
                          const SizedBox(height: 8),
                          _FeatureSwitch(
                            title: 'Boring',
                            subtitle: 'Include borewell work in default tasks',
                            value: _hasBoring,
                            onChanged: (value) =>
                                setState(() => _hasBoring = value),
                          ),
                          _FeatureSwitch(
                            title: 'Septic tank',
                            subtitle: 'Include septic tank construction',
                            value: _hasSepticTank,
                            onChanged: (value) =>
                                setState(() => _hasSepticTank = value),
                          ),
                          _FeatureSwitch(
                            title: 'Soak pit',
                            subtitle: 'Include soak pit construction',
                            value: _hasSoakPit,
                            onChanged: (value) =>
                                setState(() => _hasSoakPit = value),
                          ),
                          _FeatureSwitch(
                            title: 'Mumty',
                            subtitle: 'Include rooftop mumty work',
                            value: _hasMumty,
                            onChanged: (value) =>
                                setState(() => _hasMumty = value),
                          ),
                          const SizedBox(height: 22),
                          FilledButton.icon(
                            onPressed: busy ? null : _submit,
                            icon: busy
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    _editing
                                        ? Icons.check_rounded
                                        : Icons.add_rounded,
                                  ),
                            label: Text(
                              busy
                                  ? 'Saving project...'
                                  : _editing
                                  ? 'Save site changes'
                                  : 'Create live site',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? Function(String?) _required(String label) =>
      (value) =>
          value == null || value.trim().isEmpty ? '$label is required' : null;

  String? Function(String?) _positiveNumber(String label) => (value) {
    final parsed = double.tryParse(value ?? '');
    return parsed == null || parsed <= 0 ? 'Enter a valid $label' : null;
  };

  Future<void> _pickDate({required bool start}) async {
    final initial = start ? _startDate : _endDate;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (start) {
        _startDate = selected;
        if (_endDate.isBefore(selected)) {
          _endDate = selected.add(const Duration(days: 30));
        }
      } else {
        _endDate = selected;
      }
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Target date must follow the start date.'),
        ),
      );
      return;
    }
    final existing = widget.initial;
    final mutation = SiteMutation(
      name: _name.text,
      location: _location.text,
      budget: double.parse(_budget.text),
      startDate: _startDate,
      endDate: _endDate,
      description: _description.text,
      coverImage: _coverImage.text,
      floors: int.parse(_floors.text),
      hasBoring: _hasBoring,
      hasSepticTank: _hasSepticTank,
      hasSoakPit: _hasSoakPit,
      hasMumty: _hasMumty,
      status: _status,
      progress: _progress.round(),
      supervisorIds: _supervisorIds.toList(growable: false),
      clientId: _clientId,
    );
    final controller = ref.read(siteMutationControllerProvider.notifier);
    final saved = existing == null
        ? await controller.create(mutation)
        : await controller.update(existing.id, mutation);
    if (saved != null && mounted) Navigator.pop(context, saved);
  }
}

class _TeamAssignmentFields extends StatelessWidget {
  const _TeamAssignmentFields({
    required this.team,
    required this.supervisorIds,
    required this.clientId,
    required this.enabled,
    required this.onSupervisorsChanged,
    required this.onClientChanged,
  });

  final AsyncValue<List<SiteAssignee>> team;
  final Set<String> supervisorIds;
  final String? clientId;
  final bool enabled;
  final ValueChanged<Set<String>> onSupervisorsChanged;
  final ValueChanged<String?> onClientChanged;

  @override
  Widget build(BuildContext context) => team.when(
    loading: () => const _AssignmentState(
      icon: Icons.groups_outlined,
      message: 'Loading workspace team…',
    ),
    error: (error, _) => _AssignmentState(
      icon: Icons.cloud_off_rounded,
      message: 'Team assignment is unavailable. You can create this site and assign people later.',
      tone: AppTheme.warning,
    ),
    data: (members) {
      final supervisors = members.where((member) => member.isSupervisor).toList();
      final clients = members.where((member) => member.isClient).toList();
      if (supervisors.isEmpty && clients.isEmpty) {
        return const _AssignmentState(
          icon: Icons.person_search_outlined,
          message: 'No eligible supervisor or client accounts are returned by the workspace team API.',
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assign people now so their dashboard only shows this project.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            'Site supervisors',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (supervisors.isEmpty)
            const _AssignmentState(
              icon: Icons.badge_outlined,
              message: 'No supervisor accounts are available.',
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: supervisors
                  .map(
                    (member) => FilterChip(
                      selected: supervisorIds.contains(member.id),
                      onSelected: !enabled
                          ? null
                          : (selected) {
                              final next = {...supervisorIds};
                              if (selected) {
                                next.add(member.id);
                              } else {
                                next.remove(member.id);
                              }
                              onSupervisorsChanged(next);
                            },
                      avatar: const Icon(Icons.engineering_outlined, size: 17),
                      label: Text(member.displayName),
                    ),
                  )
                  .toList(growable: false),
            ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: clients.any((member) => member.id == clientId)
                ? clientId
                : null,
            decoration: const InputDecoration(
              labelText: 'Project client',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Assign later'),
              ),
              ...clients.map(
                (member) => DropdownMenuItem<String>(
                  value: member.id,
                  child: Text(member.displayName),
                ),
              ),
            ],
            onChanged: enabled ? onClientChanged : null,
          ),
        ],
      );
    },
  );
}

class _AssignmentState extends StatelessWidget {
  const _AssignmentState({
    required this.icon,
    required this.message,
    this.tone = AppTheme.muted,
  });

  final IconData icon;
  final String message;
  final Color tone;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: tone.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: tone),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tone,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

class _FormHeader extends StatelessWidget {
  const _FormHeader({required this.editing});

  final bool editing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 18, 14, 14),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.orange.withValues(alpha: .11),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            editing ? Icons.edit_location_alt_outlined : Icons.add_location_alt,
            color: AppTheme.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                editing ? 'Edit site workspace' : 'Create site workspace',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.4,
                ),
              ),
              Text(
                editing
                    ? 'Update the backend project contract.'
                    : 'Creates the site and default construction task plan.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    ),
  );
}

class _FormSectionLabel extends StatelessWidget {
  const _FormSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppTheme.muted,
      fontWeight: FontWeight.w800,
      letterSpacing: .85,
    ),
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_month_outlined),
      ),
      child: Text(
        siteDate(value),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}

class _FeatureSwitch extends StatelessWidget {
  const _FeatureSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    contentPadding: EdgeInsets.zero,
    title: Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    subtitle: Text(
      subtitle,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
    ),
    activeTrackColor: AppTheme.orange,
    value: value,
    onChanged: onChanged,
  );
}

class _FormError extends StatelessWidget {
  const _FormError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: AppTheme.danger.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.danger.withValues(alpha: .2)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: AppTheme.danger),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
