import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/design_models.dart';
import '../../providers/design_studio_provider.dart';

Future<String?> showDesignBriefSheet(
  BuildContext context,
  WidgetRef ref, {
  required DesignStudioData data,
  DesignRecord? source,
}) {
  var brief = source == null
      ? DesignBrief.initial()
      : DesignBrief.fromDesign(source);
  if (brief.siteId.isEmpty && data.sites.length == 1) {
    brief = brief.copyWith(siteId: data.sites.single.id);
  }
  ref.read(designBriefControllerProvider.notifier).reset(brief);
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppTheme.ink.withValues(alpha: .55),
    builder: (_) => _DesignBriefSheet(data: data, isVariation: source != null),
  );
}

class _DesignBriefSheet extends ConsumerWidget {
  const _DesignBriefSheet({required this.data, required this.isVariation});

  final DesignStudioData data;
  final bool isVariation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brief = ref.watch(designBriefControllerProvider);
    final controller = ref.read(designBriefControllerProvider.notifier);
    final action = ref.watch(designActionControllerProvider);
    final availableCredits = data.wallet?.credits ?? 0;
    final canGenerate =
        !action.isLoading &&
        !data.isOffline &&
        data.sites.isNotEmpty &&
        availableCredits >= 10;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Container(
          height: MediaQuery.sizeOf(context).height * .94,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              _BriefHeader(
                isVariation: isVariation,
                credits: availableCredits,
                onClose: () => Navigator.pop(context),
              ),
              if (action.isLoading)
                LinearProgressIndicator(
                  minHeight: 3,
                  color: AppTheme.orange,
                  backgroundColor: AppTheme.orange.withValues(alpha: .1),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                  children: [
                    if (action.isLoading) ...[
                      _GenerationProgress(message: action.message),
                      const SizedBox(height: 16),
                    ],
                    _SectionLabel(
                      icon: Icons.apartment_rounded,
                      label: 'PROJECT & PLOT',
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: brief.siteId.isEmpty ? null : brief.siteId,
                      decoration: const InputDecoration(
                        labelText: 'Construction site',
                        prefixIcon: Icon(Icons.location_city_rounded),
                      ),
                      items: data.sites
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
                      onChanged: action.isLoading
                          ? null
                          : (value) {
                              if (value != null) controller.setSite(value);
                            },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: brief.projectName,
                      enabled: !action.isLoading,
                      textCapitalization: TextCapitalization.words,
                      onChanged: controller.setProjectName,
                      decoration: const InputDecoration(
                        labelText: 'Project name',
                        hintText: 'e.g. Orchid Residence Concept',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth >= 540;
                        final fields = [
                          Expanded(
                            child: TextFormField(
                              initialValue: _number(brief.plotWidth),
                              enabled: !action.isLoading,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: controller.setPlotWidth,
                              decoration: const InputDecoration(
                                labelText: 'Plot width (ft)',
                                prefixIcon: Icon(Icons.straighten_rounded),
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              initialValue: _number(brief.plotLength),
                              enabled: !action.isLoading,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: controller.setPlotLength,
                              decoration: const InputDecoration(
                                labelText: 'Plot length (ft)',
                                prefixIcon: Icon(Icons.height_rounded),
                              ),
                            ),
                          ),
                        ];
                        if (width) {
                          return Row(
                            children: [
                              fields[0],
                              const SizedBox(width: 12),
                              fields[1],
                            ],
                          );
                        }
                        return Column(
                          children: [
                            Row(children: [fields[0]]),
                            const SizedBox(height: 12),
                            Row(children: [fields[1]]),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: brief.facing,
                      decoration: const InputDecoration(
                        labelText: 'Plot facing',
                        prefixIcon: Icon(Icons.explore_rounded),
                      ),
                      items: const ['North', 'East', 'South', 'West']
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: action.isLoading
                          ? null
                          : (value) {
                              if (value != null) controller.setFacing(value);
                            },
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const Expanded(
                          child: _SectionLabel(
                            icon: Icons.layers_rounded,
                            label: 'FLOOR REQUIREMENTS',
                          ),
                        ),
                        _FloorCountControl(
                          value: brief.floors,
                          enabled: !action.isLoading,
                          onChanged: controller.setFloors,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...brief.floorRequirements.indexed.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child:
                            _FloorRequirementCard(
                                  floor: entry.$2,
                                  enabled: !action.isLoading,
                                  initiallyExpanded: entry.$1 == 0,
                                  onChanged: (update) => controller.updateFloor(
                                    entry.$2.floorNumber,
                                    update,
                                  ),
                                )
                                .animate(delay: (entry.$1 * 45).ms)
                                .fadeIn(duration: 220.ms)
                                .slideY(begin: .04, end: 0),
                      ),
                    ),
                    SurfaceCard(
                      child: SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: brief.garden,
                        onChanged: action.isLoading
                            ? null
                            : controller.setGarden,
                        title: const Text('Garden / open space'),
                        subtitle: const Text(
                          'Reserve an outdoor zone in the ground-floor concept.',
                        ),
                        secondary: const Icon(
                          Icons.park_rounded,
                          color: AppTheme.success,
                        ),
                      ),
                    ),
                    if (brief.validationMessage != null) ...[
                      const SizedBox(height: 14),
                      _InlineMessage(
                        message: brief.validationMessage!,
                        tone: AppTheme.warning,
                      ),
                    ],
                    if (action.value.hasError) ...[
                      const SizedBox(height: 14),
                      _InlineMessage(
                        message: '${action.value.error}',
                        tone: AppTheme.danger,
                      ),
                    ],
                    if (data.isOffline) ...[
                      const SizedBox(height: 14),
                      const _InlineMessage(
                        message:
                            'Reconnect before generating. Cached designs remain available for review.',
                        tone: AppTheme.warning,
                      ),
                    ] else if (availableCredits < 10) ...[
                      const SizedBox(height: 14),
                      const _InlineMessage(
                        message:
                            'At least 10 design credits are required for a 2D generation.',
                        tone: AppTheme.warning,
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: canGenerate
                          ? () => _generate(context, ref, brief)
                          : null,
                      icon: action.isLoading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                      label: Text(
                        action.isLoading
                            ? 'Design engine is working'
                            : isVariation
                            ? 'Generate next variation · 10 credits'
                            : 'Generate floor plan · 10 credits',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Conceptual output only. Verify dimensions and construction suitability with a licensed architect or engineer.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.muted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generate(
    BuildContext context,
    WidgetRef ref,
    DesignBrief brief,
  ) async {
    final design = await ref
        .read(designActionControllerProvider.notifier)
        .generate(brief);
    if (design != null && context.mounted) Navigator.pop(context, design.id);
  }
}

class _BriefHeader extends StatelessWidget {
  const _BriefHeader({
    required this.isVariation,
    required this.credits,
    required this.onClose,
  });
  final bool isVariation;
  final int credits;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 14, 10),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.orange, AppTheme.orangeBright],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.architecture_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isVariation ? 'Generate variation' : 'New floor plan',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
              Text(
                '$credits credits available · structured site brief',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
              ),
            ],
          ),
        ),
        IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
      ],
    ),
  );
}

class _GenerationProgress extends StatelessWidget {
  const _GenerationProgress({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0C1728), Color(0xFF1A3150)],
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        const SizedBox.square(
          dimension: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppTheme.orangeBright,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generation in progress',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFC2CEDD),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: AppTheme.orange),
      const SizedBox(width: 7),
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.muted,
          fontWeight: FontWeight.w800,
          letterSpacing: .75,
        ),
      ),
    ],
  );
}

class _FloorCountControl extends StatelessWidget {
  const _FloorCountControl({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 38,
    decoration: BoxDecoration(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          onPressed: enabled && value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_rounded, size: 17),
        ),
        Text(
          '$value ${value == 1 ? 'floor' : 'floors'}',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          onPressed: enabled && value < 12 ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_rounded, size: 17),
        ),
      ],
    ),
  );
}

class _FloorRequirementCard extends StatelessWidget {
  const _FloorRequirementCard({
    required this.floor,
    required this.enabled,
    required this.initiallyExpanded,
    required this.onChanged,
  });
  final DesignFloorRequirement floor;
  final bool enabled;
  final bool initiallyExpanded;
  final ValueChanged<
    DesignFloorRequirement Function(DesignFloorRequirement floor)
  >
  onChanged;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).cardTheme.color,
    borderRadius: BorderRadius.circular(22),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.line),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        shape: const RoundedRectangleBorder(),
        collapsedShape: const RoundedRectangleBorder(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.blue.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Center(
            child: Text(
              '${floor.floorNumber}',
              style: const TextStyle(
                color: AppTheme.blue,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        title: Text(
          floor.label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${floor.bedrooms} bed · ${floor.bathrooms} bath',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: _RoomCount(
                  label: 'Bedrooms',
                  value: floor.bedrooms,
                  enabled: enabled,
                  onChanged: (value) =>
                      onChanged((current) => current.copyWith(bedrooms: value)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RoomCount(
                  label: 'Bathrooms',
                  value: floor.bathrooms,
                  enabled: enabled,
                  onChanged: (value) => onChanged(
                    (current) => current.copyWith(bathrooms: value),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RequirementChip(
                label: 'Living',
                selected: floor.living,
                enabled: enabled,
                onChanged: (value) =>
                    onChanged((current) => current.copyWith(living: value)),
              ),
              _RequirementChip(
                label: 'Dining',
                selected: floor.dining,
                enabled: enabled,
                onChanged: (value) =>
                    onChanged((current) => current.copyWith(dining: value)),
              ),
              _RequirementChip(
                label: 'Kitchen',
                selected: floor.kitchen,
                enabled: enabled,
                onChanged: (value) =>
                    onChanged((current) => current.copyWith(kitchen: value)),
              ),
              _RequirementChip(
                label: 'Staircase',
                selected: floor.staircase,
                enabled: enabled,
                onChanged: (value) =>
                    onChanged((current) => current.copyWith(staircase: value)),
              ),
              if (floor.floorNumber == 1)
                _RequirementChip(
                  label: 'Parking',
                  selected: floor.parking,
                  enabled: enabled,
                  onChanged: (value) =>
                      onChanged((current) => current.copyWith(parking: value)),
                ),
              _RequirementChip(
                label: 'Balcony',
                selected: floor.balcony,
                enabled: enabled,
                onChanged: (value) =>
                    onChanged((current) => current.copyWith(balcony: value)),
              ),
              _RequirementChip(
                label: 'Pooja room',
                selected: floor.poojaRoom,
                enabled: enabled,
                onChanged: (value) =>
                    onChanged((current) => current.copyWith(poojaRoom: value)),
              ),
              _RequirementChip(
                label: 'Study',
                selected: floor.studyRoom,
                enabled: enabled,
                onChanged: (value) =>
                    onChanged((current) => current.copyWith(studyRoom: value)),
              ),
              _RequirementChip(
                label: 'Store',
                selected: floor.storeRoom,
                enabled: enabled,
                onChanged: (value) =>
                    onChanged((current) => current.copyWith(storeRoom: value)),
              ),
              _RequirementChip(
                label: 'Utility',
                selected: floor.utilityRoom,
                enabled: enabled,
                onChanged: (value) => onChanged(
                  (current) => current.copyWith(utilityRoom: value),
                ),
              ),
              _RequirementChip(
                label: 'Lift',
                selected: floor.lift,
                enabled: enabled,
                onChanged: (value) =>
                    onChanged((current) => current.copyWith(lift: value)),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _RoomCount extends StatelessWidget {
  const _RoomCount({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });
  final String label;
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 8, 5, 8),
    decoration: BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
              ),
              Text(
                '$value',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        Column(
          children: [
            InkWell(
              onTap: enabled && value < 20 ? () => onChanged(value + 1) : null,
              child: const Icon(Icons.keyboard_arrow_up_rounded, size: 19),
            ),
            InkWell(
              onTap: enabled && value > 0 ? () => onChanged(value - 1) : null,
              child: const Icon(Icons.keyboard_arrow_down_rounded, size: 19),
            ),
          ],
        ),
      ],
    ),
  );
}

class _RequirementChip extends StatelessWidget {
  const _RequirementChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });
  final String label;
  final bool selected;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text(label),
    selected: selected,
    onSelected: enabled ? onChanged : null,
    selectedColor: AppTheme.orange.withValues(alpha: .11),
    checkmarkColor: AppTheme.orange,
    side: BorderSide(color: selected ? AppTheme.orange : AppTheme.line),
  );
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message, required this.tone});
  final String message;
  final Color tone;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: tone.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: tone.withValues(alpha: .2)),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline_rounded, color: tone, size: 18),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tone,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

String _number(double value) =>
    value == value.roundToDouble() ? '${value.round()}' : '$value';
