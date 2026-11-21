import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/report_models.dart';
import '../../providers/reports_provider.dart';

Future<bool> showDailyReportComposer(
  BuildContext context,
  WidgetRef ref,
  ReportsStudioData data, {
  String? initialSiteId,
}) async {
  ref
      .read(dailyReportBriefProvider.notifier)
      .reset(data, initialSiteId: initialSiteId);
  ref.read(reportsActionControllerProvider.notifier).clearError();
  final created = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DailyReportComposer(data: data),
  );
  return created == true;
}

class _DailyReportComposer extends ConsumerStatefulWidget {
  const _DailyReportComposer({required this.data});
  final ReportsStudioData data;

  @override
  ConsumerState<_DailyReportComposer> createState() =>
      _DailyReportComposerState();
}

class _DailyReportComposerState extends ConsumerState<_DailyReportComposer> {
  final completedController = TextEditingController();
  final issueController = TextEditingController();
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recoverMedia());
  }

  @override
  void dispose() {
    completedController.dispose();
    issueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brief = ref.watch(dailyReportBriefProvider);
    final controller = ref.read(dailyReportBriefProvider.notifier);
    final action = ref.watch(reportsActionControllerProvider);
    final busy = action.isLoading || uploading;
    final error = action.hasError ? action.error : null;
    final selectedSite = widget.data.site(brief.siteId);
    return FractionallySizedBox(
      heightFactor: .96,
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20,
                  14,
                  20,
                  MediaQuery.viewInsetsOf(context).bottom + 28,
                ),
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppTheme.line,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ComposerHeader(onClose: () => Navigator.pop(context)),
                  const SizedBox(height: 20),
                  _ComposerSection(
                    number: '01',
                    title: 'Project day',
                    subtitle: 'Select the assigned site and report date.',
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final project = DropdownButtonFormField<String>(
                          initialValue: brief.siteId.isEmpty
                              ? null
                              : brief.siteId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Project site',
                            prefixIcon: Icon(Icons.apartment_rounded),
                          ),
                          items: widget.data.sites
                              .map(
                                (site) => DropdownMenuItem(
                                  value: site.id,
                                  child: Text(
                                    site.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: busy
                              ? null
                              : (value) {
                                  final site = value == null
                                      ? null
                                      : widget.data.site(value);
                                  if (site != null) controller.setSite(site);
                                },
                        );
                        final date = _DateField(
                          date: brief.date,
                          onTap: busy ? null : () => _pickDate(brief),
                        );
                        if (constraints.maxWidth >= 600) {
                          return Row(
                            children: [
                              Expanded(flex: 3, child: project),
                              const SizedBox(width: 12),
                              Expanded(flex: 2, child: date),
                            ],
                          );
                        }
                        return Column(
                          children: [project, const SizedBox(height: 12), date],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 13),
                  _ComposerSection(
                    number: '02',
                    title: 'Progress & conditions',
                    subtitle:
                        'Progress updates the live site record on submit.',
                    child: Column(
                      children: [
                        _ProgressControl(
                          progress: brief.progress,
                          currentProgress: selectedSite?.progress ?? 0,
                          onChanged: busy ? null : controller.setProgress,
                        ),
                        const SizedBox(height: 17),
                        _WeatherSelector(
                          value: brief.weather,
                          enabled: !busy,
                          onChanged: controller.setWeather,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  _ComposerSection(
                    number: '03',
                    title: 'Field narrative',
                    subtitle:
                        'Capture what happened without rewriting it later.',
                    child: TextFormField(
                      enabled: !busy,
                      minLines: 3,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: controller.setNotes,
                      decoration: const InputDecoration(
                        labelText: 'Site notes',
                        hintText:
                            'Summarise today’s execution, inspections and constraints.',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  _ComposerSection(
                    number: '04',
                    title: 'Completed work',
                    subtitle: 'Add specific, auditable work items.',
                    child: _ListEditor(
                      controller: completedController,
                      values: brief.completedTasks,
                      hint: 'Example: First-floor slab reinforcement completed',
                      tone: AppTheme.success,
                      icon: Icons.task_alt_rounded,
                      enabled: !busy,
                      onAdd: () {
                        controller.addCompletedTask(completedController.text);
                        completedController.clear();
                      },
                      onRemove: controller.removeCompletedTask,
                    ),
                  ),
                  const SizedBox(height: 13),
                  _ComposerSection(
                    number: '05',
                    title: 'Issues & blockers',
                    subtitle:
                        'Record observations accurately; resolution tracking needs a future API.',
                    child: _ListEditor(
                      controller: issueController,
                      values: brief.issues,
                      hint:
                          'Example: M20 concrete delivery delayed by 90 minutes',
                      tone: AppTheme.danger,
                      icon: Icons.report_problem_outlined,
                      enabled: !busy,
                      onAdd: () {
                        controller.addIssue(issueController.text);
                        issueController.clear();
                      },
                      onRemove: controller.removeIssue,
                    ),
                  ),
                  const SizedBox(height: 13),
                  _ComposerSection(
                    number: '06',
                    title: 'Next-day handoff',
                    subtitle: 'Keep the next field shift aligned.',
                    child: TextFormField(
                      enabled: !busy,
                      minLines: 2,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: controller.setNextDayPlan,
                      decoration: const InputDecoration(
                        labelText: 'Next-day plan',
                        hintText:
                            'Planned work, expected deliveries and inspections.',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  _ComposerSection(
                    number: '07',
                    title: 'Progress evidence',
                    subtitle:
                        'Photos upload securely through the backend-signed Cloudinary flow.',
                    child: _EvidenceComposer(
                      media: brief.media,
                      busy: busy,
                      uploading: uploading,
                      onCamera: () => _pickMedia(camera: true),
                      onGallery: () => _pickMedia(camera: false),
                      onRemove: controller.removeMedia,
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 14),
                    _ComposerError(error: error),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: busy ? null : () => _submit(brief),
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_done_outlined),
                    label: Text(
                      uploading
                          ? 'Uploading evidence...'
                          : action.isLoading
                          ? 'Submitting report...'
                          : 'Submit daily report',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Submission creates an immutable DailyReportIn record and updates project progress.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(DailyReportBrief brief) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: brief.date,
      firstDate: DateTime(brief.referenceDate.year - 5),
      lastDate: brief.referenceDate,
    );
    if (selected != null) {
      ref.read(dailyReportBriefProvider.notifier).setDate(selected);
    }
  }

  Future<void> _pickMedia({required bool camera}) async {
    final remaining = 8 - ref.read(dailyReportBriefProvider).media.length;
    if (remaining <= 0) {
      _message('A report can contain up to 8 photos.');
      return;
    }
    try {
      final picker = ref.read(reportImagePickerProvider);
      final uploads = camera
          ? await picker.pickCamera()
          : await picker.pickGallery();
      await _upload(uploads.take(remaining));
      if (uploads.length > remaining) {
        _message('Only the first $remaining selected photos were attached.');
      }
    } catch (error) {
      _message('Photo selection failed: $error');
    }
  }

  Future<void> _recoverMedia() async {
    try {
      final recovered = await ref
          .read(reportImagePickerProvider)
          .recoverInterruptedSelection();
      if (recovered.isNotEmpty) await _upload(recovered.take(8));
    } catch (_) {
      // Recovery is best-effort and must not block report creation.
    }
  }

  Future<void> _upload(Iterable<ReportPhotoUpload> uploads) async {
    if (uploads.isEmpty || !mounted) return;
    setState(() => uploading = true);
    try {
      for (final upload in uploads) {
        final media = await ref
            .read(reportsActionControllerProvider.notifier)
            .uploadPhoto(upload);
        if (media == null) break;
        ref.read(dailyReportBriefProvider.notifier).addMedia(media);
      }
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> _submit(DailyReportBrief brief) async {
    final validation = brief.validationMessage;
    if (validation != null) {
      _message(validation);
      return;
    }
    if (widget.data.containsReportFor(brief.siteId, brief.date)) {
      _message('A daily report already exists for this site and date.');
      return;
    }
    final created = await ref
        .read(reportsActionControllerProvider.notifier)
        .createReport(brief);
    if (created && mounted) Navigator.pop(context, true);
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}

class _ComposerHeader extends StatelessWidget {
  const _ComposerHeader({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF173A68), Color(0xFF257CB4)],
          ),
          borderRadius: BorderRadius.circular(17),
        ),
        child: const Icon(Icons.fact_check_outlined, color: Colors.white),
      ),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create daily report',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.8,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'A field-first record connected to the live project API.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Close report composer',
        onPressed: onClose,
        icon: const Icon(Icons.close_rounded),
      ),
    ],
  );
}

class _ComposerSection extends StatelessWidget {
  const _ComposerSection({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String number;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.blue.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                number,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.blue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.muted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 17),
        child,
      ],
    ),
  );
}

class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onTap});
  final DateTime date;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).inputDecorationTheme.fillColor,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Report date',
          prefixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Text(appDate(date)),
      ),
    ),
  );
}

class _ProgressControl extends StatelessWidget {
  const _ProgressControl({
    required this.progress,
    required this.currentProgress,
    required this.onChanged,
  });

  final int progress;
  final int currentProgress;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: AppTheme.blue.withValues(alpha: .055),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.blue.withValues(alpha: .1)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Project progress',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Current API value: $currentProgress%',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
                  ),
                ],
              ),
            ),
            Text(
              '$progress%',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.blue,
                fontWeight: FontWeight.w800,
                letterSpacing: -.8,
              ),
            ),
          ],
        ),
        Slider(
          value: progress.toDouble(),
          min: 0,
          max: 100,
          divisions: 100,
          onChanged: currentProgress >= 100
              ? null
              : (value) {
                  if (value >= currentProgress) onChanged?.call(value);
                },
        ),
      ],
    ),
  );
}

class _WeatherSelector extends StatelessWidget {
  const _WeatherSelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const values = ['', 'Clear', 'Cloudy', 'Rain', 'Hot', 'Windy'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Observed weather',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map(
                (weather) => ChoiceChip(
                  label: Text(weather.isEmpty ? 'Not recorded' : weather),
                  selected: weather == value,
                  onSelected: enabled ? (_) => onChanged(weather) : null,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _ListEditor extends StatelessWidget {
  const _ListEditor({
    required this.controller,
    required this.values,
    required this.hint,
    required this.tone,
    required this.icon,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
  });

  final TextEditingController controller;
  final List<String> values;
  final String hint;
  final Color tone;
  final IconData icon;
  final bool enabled;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextFormField(
        controller: controller,
        enabled: enabled && values.length < 20,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => onAdd(),
        decoration: InputDecoration(
          labelText: 'Add item',
          hintText: hint,
          suffixIcon: IconButton(
            tooltip: 'Add item',
            onPressed: enabled && values.length < 20 ? onAdd : null,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ),
      ),
      if (values.isNotEmpty) ...[
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values
                .map(
                  (value) => InputChip(
                    avatar: Icon(icon, color: tone, size: 16),
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Text(value, overflow: TextOverflow.ellipsis),
                    ),
                    onDeleted: enabled ? () => onRemove(value) : null,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    ],
  );
}

class _EvidenceComposer extends StatelessWidget {
  const _EvidenceComposer({
    required this.media,
    required this.busy,
    required this.uploading,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
  });

  final List<ReportMedia> media;
  final bool busy;
  final bool uploading;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final ValueChanged<ReportMedia> onRemove;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: busy || media.length >= 8 ? null : onCamera,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Camera'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: busy || media.length >= 8 ? null : onGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Gallery'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 9),
      Row(
        children: [
          Expanded(
            child: Text(
              uploading
                  ? 'Compressing and uploading secure evidence...'
                  : '${media.length}/8 photos attached  |  10 MB maximum each',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: uploading ? AppTheme.blue : AppTheme.muted,
                fontWeight: uploading ? FontWeight.w700 : null,
              ),
            ),
          ),
          if (uploading)
            const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
      if (media.isNotEmpty) ...[
        const SizedBox(height: 13),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 560 ? 4 : 2;
            final width = (constraints.maxWidth - (columns - 1) * 9) / columns;
            return Wrap(
              spacing: 9,
              runSpacing: 9,
              children: media
                  .map(
                    (item) => SizedBox(
                      width: width,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AspectRatio(
                              aspectRatio: 1.2,
                              child: Image.network(
                                item.url,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: AppTheme.line,
                                      child: const Icon(
                                        Icons.broken_image_outlined,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 5,
                            top: 5,
                            child: Material(
                              color: AppTheme.ink.withValues(alpha: .78),
                              shape: const CircleBorder(),
                              child: InkWell(
                                onTap: busy ? null : () => onRemove(item),
                                customBorder: const CircleBorder(),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    ],
  );
}

class _ComposerError extends StatelessWidget {
  const _ComposerError({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: AppTheme.danger.withValues(alpha: .075),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.danger.withValues(alpha: .18)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: AppTheme.danger,
          size: 18,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            error is ApiException ? (error as ApiException).message : '$error',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.danger,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
