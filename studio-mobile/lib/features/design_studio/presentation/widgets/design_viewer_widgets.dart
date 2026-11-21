import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/design_models.dart';
import 'design_studio_widgets.dart';

enum DesignViewMode { drawing, threeD }

class DesignViewerHero extends StatelessWidget {
  const DesignViewerHero({
    super.key,
    required this.design,
    required this.siteName,
  });

  final DesignRecord design;
  final String siteName;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 188),
    padding: const EdgeInsets.all(22),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      gradient: const LinearGradient(
        colors: [Color(0xFF091321), Color(0xFF173252), Color(0xFF75401F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusBadge(
                  label: design.status.label,
                  tone: designStatusColor(design.status),
                ),
                const SizedBox(width: 8),
                Text(
                  'VERSION ${designDate(design.createdAt).toUpperCase()}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFBFCBDC),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              design.projectName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -.9,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.apartment_rounded,
                  size: 15,
                  color: Color(0xFFBFCBDC),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    siteName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFBFCBDC),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
        final metrics = _DesignMetrics(design: design);
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 20), metrics],
          );
        }
        return Row(
          children: [
            Expanded(flex: 3, child: title),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: metrics),
          ],
        );
      },
    ),
  );
}

class _DesignMetrics extends StatelessWidget {
  const _DesignMetrics({required this.design});
  final DesignRecord design;

  @override
  Widget build(BuildContext context) {
    final layout =
        design.outputs.floorPlans.firstOrNull?.layout ?? design.outputs.layout;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .075),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Row(
        children: [
          _Metric(value: '${design.floorCount}', label: 'Floors'),
          _Metric(
            value: layout.plotArea == 0 ? '-' : '${layout.plotArea.round()}',
            label: 'Sq ft plot',
          ),
          _Metric(value: '${design.creditsUsed}', label: 'Credits'),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFFBFCBDC),
            fontSize: 8,
            letterSpacing: .5,
          ),
        ),
      ],
    ),
  );
}

class DesignDisciplinePanel extends StatelessWidget {
  const DesignDisciplinePanel({
    super.key,
    required this.design,
    required this.selected,
    required this.canManage,
    required this.loading,
    required this.onSelected,
  });

  final DesignRecord design;
  final DesignDrawingType selected;
  final bool canManage;
  final bool loading;
  final ValueChanged<DesignDrawingType> onSelected;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Drawing disciplines',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          'Switch issued layers or generate a missing technical drawing.',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
        ),
        const SizedBox(height: 14),
        ...DesignDrawingType.values.map((type) {
          final generated =
              !type.isTechnical ||
              design.outputs.technicalDrawings.containsKey(type);
          return Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Material(
              color: selected == type
                  ? AppTheme.orange.withValues(alpha: .09)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              child: InkWell(
                onTap: loading || (!generated && !canManage)
                    ? null
                    : () => onSelected(type),
                borderRadius: BorderRadius.circular(15),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _disciplineIcon(type),
                        size: 18,
                        color: selected == type
                            ? AppTheme.orange
                            : AppTheme.muted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          type.label,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: selected == type
                                    ? AppTheme.orange
                                    : null,
                              ),
                        ),
                      ),
                      if (generated)
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 17,
                          color: AppTheme.success,
                        )
                      else if (canManage)
                        Text(
                          '${type.creditCost} cr',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppTheme.blue,
                                fontWeight: FontWeight.w800,
                              ),
                        )
                      else
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: AppTheme.muted,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    ),
  );
}

class DesignFloorSelector extends StatelessWidget {
  const DesignFloorSelector({
    super.key,
    required this.floors,
    required this.selectedFloor,
    required this.onSelected,
  });
  final List<DesignFloorPlan> floors;
  final int selectedFloor;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: floors.map((floor) {
        final selected = floor.floorNumber == selectedFloor;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(floor.label),
            selected: selected,
            onSelected: (_) => onSelected(floor.floorNumber),
            selectedColor: AppTheme.orange.withValues(alpha: .11),
            side: BorderSide(color: selected ? AppTheme.orange : AppTheme.line),
            labelStyle: TextStyle(
              color: selected ? AppTheme.orange : AppTheme.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }).toList(),
    ),
  );
}

class DesignCanvas extends StatefulWidget {
  const DesignCanvas({
    super.key,
    required this.svg,
    required this.title,
    required this.mode,
    required this.heroTag,
  });
  final String svg;
  final String title;
  final DesignViewMode mode;
  final String heroTag;

  @override
  State<DesignCanvas> createState() => _DesignCanvasState();
}

class _DesignCanvasState extends State<DesignCanvas> {
  final transformation = TransformationController();
  int quarterTurns = 0;

  @override
  void didUpdateWidget(covariant DesignCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.svg != widget.svg) {
      transformation.value = Matrix4.identity();
      quarterTurns = 0;
    }
  }

  @override
  void dispose() {
    transformation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 13, 10, 10),
          child: Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: widget.mode == DesignViewMode.threeD
                      ? AppTheme.blue
                      : AppTheme.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              _CanvasButton(
                tooltip: 'Zoom out',
                icon: Icons.remove_rounded,
                onTap: () => _scale(.8),
              ),
              _CanvasButton(
                tooltip: 'Reset view',
                icon: Icons.center_focus_strong_rounded,
                onTap: _reset,
              ),
              _CanvasButton(
                tooltip: 'Zoom in',
                icon: Icons.add_rounded,
                onTap: () => _scale(1.25),
              ),
              _CanvasButton(
                tooltip: 'Rotate',
                icon: Icons.rotate_right_rounded,
                onTap: () =>
                    setState(() => quarterTurns = (quarterTurns + 1) % 4),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: AppTheme.line),
        Expanded(
          child: Container(
            color: widget.mode == DesignViewMode.threeD
                ? const Color(0xFFD7D3CD)
                : const Color(0xFFF8FAF8),
            child: widget.svg.isEmpty
                ? const Center(
                    child: EmptyPanel(
                      title: 'Drawing not generated',
                      message:
                          'Generate this view from the approved floor plan to inspect it here.',
                      icon: Icons.layers_clear_rounded,
                    ),
                  )
                : Hero(
                    tag: widget.heroTag,
                    child: InteractiveViewer(
                      transformationController: transformation,
                      minScale: .25,
                      maxScale: 8,
                      boundaryMargin: const EdgeInsets.all(220),
                      constrained: true,
                      child: Center(
                        child: RotatedBox(
                          quarterTurns: quarterTurns,
                          child: SvgPicture.string(
                            widget.svg,
                            fit: BoxFit.contain,
                            placeholderBuilder: (_) => const AppSkeleton(),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    ),
  );

  void _scale(double factor) {
    final current = transformation.value.getMaxScaleOnAxis();
    final next = (current * factor).clamp(.25, 8.0);
    transformation.value = Matrix4.identity()..scaleByDouble(next, next, 1, 1);
  }

  void _reset() => setState(() {
    transformation.value = Matrix4.identity();
    quarterTurns = 0;
  });
}

class _CanvasButton extends StatelessWidget {
  const _CanvasButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
    onPressed: onTap,
    icon: Icon(icon, size: 18),
  );
}

class DesignRoomSchedule extends StatelessWidget {
  const DesignRoomSchedule({super.key, required this.layout});
  final DesignLayout layout;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Room schedule',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          '${layout.rooms.length} spaces · ${layout.facing.isEmpty ? 'facing unavailable' : '${layout.facing} facing'}',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
        ),
        const SizedBox(height: 12),
        if (layout.rooms.isEmpty)
          Text(
            'Room geometry is unavailable for this version.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
          )
        else
          ...layout.rooms
              .take(12)
              .map(
                (room) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          room.name.replaceAll('_', ' '),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '${room.width.toStringAsFixed(1)} × ${room.height.toStringAsFixed(1)} ft',
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
              ),
      ],
    ),
  );
}

IconData _disciplineIcon(DesignDrawingType type) => switch (type) {
  DesignDrawingType.floor => Icons.grid_4x4_rounded,
  DesignDrawingType.electrical => Icons.electrical_services_rounded,
  DesignDrawingType.plumbing => Icons.plumbing_rounded,
  DesignDrawingType.column => Icons.view_column_rounded,
  DesignDrawingType.structural => Icons.account_tree_rounded,
  DesignDrawingType.foundation => Icons.foundation_rounded,
  DesignDrawingType.doorWindow => Icons.door_sliding_rounded,
};
