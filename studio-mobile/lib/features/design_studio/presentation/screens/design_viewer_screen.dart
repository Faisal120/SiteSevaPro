import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_file_share.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/design_models.dart';
import '../../providers/design_studio_provider.dart';
import '../widgets/design_brief_sheet.dart';
import '../widgets/design_viewer_widgets.dart';

class DesignViewerScreen extends ConsumerStatefulWidget {
  const DesignViewerScreen({super.key, required this.designId});

  final String designId;

  @override
  ConsumerState<DesignViewerScreen> createState() => _DesignViewerScreenState();
}

class _DesignViewerScreenState extends ConsumerState<DesignViewerScreen> {
  int floorNumber = 1;
  DesignDrawingType drawingType = DesignDrawingType.floor;
  DesignViewMode mode = DesignViewMode.drawing;

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(designDetailControllerProvider(widget.designId));
    final studio = ref.watch(designStudioControllerProvider).valueOrNull;
    final user = ref.watch(authControllerProvider).valueOrNull;
    final canManage = user?.isContractor == true;
    final action = ref.watch(designActionControllerProvider);
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: detail.when(
          loading: () => const _ViewerSkeleton(),
          error: (error, stackTrace) => _ViewerError(
            error: error,
            onBack: () => context.go('/'),
            onRetry: () => ref
                .read(designDetailControllerProvider(widget.designId).notifier)
                .load(),
          ),
          data: (design) {
            final selectedFloor = _validFloor(design);
            final siteName =
                studio?.siteFor(design.siteId)?.name ?? 'Project site';
            return LayoutBuilder(
              builder: (context, constraints) => ListView(
                key: PageStorageKey('design-viewer-${widget.designId}'),
                primary: false,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  constraints.maxWidth >= 900 ? 30 : 18,
                  14,
                  constraints.maxWidth >= 900 ? 30 : 18,
                  124,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1320),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ViewerHeader(
                            design: design,
                            canManage: canManage,
                            actionLoading: action.isLoading,
                            onBack: () => context.go('/'),
                            onRefresh: () => ref
                                .read(
                                  designDetailControllerProvider(
                                    widget.designId,
                                  ).notifier,
                                )
                                .refresh(),
                            onVariation: studio == null
                                ? null
                                : () => _generateVariation(design, studio),
                            onDelete: () => _delete(design),
                          ),
                          const SizedBox(height: 16),
                          DesignViewerHero(design: design, siteName: siteName)
                              .animate()
                              .fadeIn(duration: 280.ms)
                              .slideY(begin: .04, end: 0),
                          if (action.isLoading || action.value.hasError) ...[
                            const SizedBox(height: 14),
                            _ActionNotice(action: action),
                          ],
                          const SizedBox(height: 18),
                          if (!design.isReady)
                            _UnavailableDesign(design: design)
                          else ...[
                            DesignFloorSelector(
                              floors: design.outputs.floorPlans,
                              selectedFloor: selectedFloor,
                              onSelected: (value) => setState(() {
                                floorNumber = value;
                                drawingType = DesignDrawingType.floor;
                                mode = DesignViewMode.drawing;
                              }),
                            ),
                            const SizedBox(height: 12),
                            _ModeAndExportBar(
                              mode: mode,
                              hasThreeD: design.outputs.threeD.containsKey(
                                selectedFloor,
                              ),
                              canManage: canManage,
                              loading: action.isLoading,
                              onDrawing: () =>
                                  setState(() => mode = DesignViewMode.drawing),
                              onThreeD: () =>
                                  _selectThreeD(design, selectedFloor),
                              onSvg: () => _exportSvg(design, selectedFloor),
                              onPdf: mode == DesignViewMode.threeD
                                  ? null
                                  : () => _exportPdf(design, selectedFloor),
                            ),
                            const SizedBox(height: 12),
                            _ViewerWorkspace(
                              design: design,
                              floorNumber: selectedFloor,
                              drawingType: drawingType,
                              mode: mode,
                              canManage: canManage,
                              loading: action.isLoading,
                              onDrawing: (type) => _selectDrawing(design, type),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  int _validFloor(DesignRecord design) {
    final floors = design.outputs.floorPlans;
    if (floors.any((floor) => floor.floorNumber == floorNumber)) {
      return floorNumber;
    }
    return floors.firstOrNull?.floorNumber ?? 1;
  }

  Future<void> _selectDrawing(
    DesignRecord design,
    DesignDrawingType type,
  ) async {
    if (!type.isTechnical ||
        design.outputs.technicalDrawings.containsKey(type)) {
      setState(() {
        drawingType = type;
        mode = DesignViewMode.drawing;
      });
      return;
    }
    final confirmed = await _confirmCredits(
      title: 'Generate ${type.label}?',
      message:
          'This technical layer uses ${type.creditCost} design credits and is derived from the approved base floor plan.',
    );
    if (!confirmed) return;
    final result = await ref
        .read(designActionControllerProvider.notifier)
        .generateTechnical(design.id, type);
    if (result != null && mounted) {
      setState(() {
        drawingType = type;
        mode = DesignViewMode.drawing;
      });
    }
  }

  Future<void> _selectThreeD(DesignRecord design, int floor) async {
    if (design.outputs.threeD.containsKey(floor)) {
      setState(() => mode = DesignViewMode.threeD);
      return;
    }
    final confirmed = await _confirmCredits(
      title: 'Generate furnished 3D?',
      message:
          'This creates an open-top furnished concept for the selected floor and uses 25 design credits. A Pro or Enterprise plan is required.',
    );
    if (!confirmed) return;
    final result = await ref
        .read(designActionControllerProvider.notifier)
        .generateThreeD(design.id, floor);
    if (result != null && mounted) setState(() => mode = DesignViewMode.threeD);
  }

  Future<void> _exportSvg(DesignRecord design, int floor) async {
    final svg = _activeSvg(design, floor);
    if (svg.isEmpty) return;
    await ref.read(designActionControllerProvider.notifier).export(() async {
      await AppFileShare.bytes(
        bytes: Uint8List.fromList(utf8.encode(svg)),
        fileName:
            '${_fileStem(design.projectName)}-${_viewSlug()}-floor-$floor.svg',
        mimeType: 'image/svg+xml',
        subject: '${design.projectName} · ${_activeTitle(design, floor)}',
      );
      return true;
    });
  }

  Future<void> _exportPdf(DesignRecord design, int floor) async {
    await ref.read(designActionControllerProvider.notifier).export(() async {
      final bytes = await ref
          .read(designStudioRepositoryProvider)
          .downloadPdf(design.id, drawingType, floor);
      await AppFileShare.bytes(
        bytes: bytes,
        fileName:
            '${_fileStem(design.projectName)}-${drawingType.apiValue.toLowerCase()}-floor-$floor.pdf',
        mimeType: 'application/pdf',
        subject: '${design.projectName} · ${drawingType.label}',
      );
      return true;
    });
  }

  Future<void> _generateVariation(
    DesignRecord design,
    DesignStudioData data,
  ) async {
    final id = await showDesignBriefSheet(
      context,
      ref,
      data: data,
      source: design,
    );
    if (id != null && mounted) context.go('/design-studio/design/$id');
  }

  Future<void> _delete(DesignRecord design) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete design version?'),
        content: Text(
          '${design.projectName} and its generated drawing outputs will be removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete version',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await ref
        .read(designActionControllerProvider.notifier)
        .delete(design.id);
    if (deleted && mounted) context.go('/design-studio');
  }

  Future<bool> _confirmCredits({
    required String title,
    required String message,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Generate'),
            ),
          ],
        ),
      ) ??
      false;

  String _activeSvg(DesignRecord design, int floor) {
    if (mode == DesignViewMode.threeD) {
      return design.outputs.threeD[floor]?.svg ?? '';
    }
    return design.outputs.svgFor(drawingType, floor);
  }

  String _activeTitle(DesignRecord design, int floor) {
    if (mode == DesignViewMode.threeD) {
      return design.outputs.threeD[floor]?.label ?? '3D concept';
    }
    final floorLabel = design.outputs.floorPlans
        .where((item) => item.floorNumber == floor)
        .map((item) => item.label)
        .firstOrNull;
    return '${drawingType.label} · ${floorLabel ?? 'Floor $floor'}';
  }

  String _viewSlug() => mode == DesignViewMode.threeD
      ? '3d-concept'
      : drawingType.apiValue.toLowerCase();
}

class _ViewerHeader extends StatelessWidget {
  const _ViewerHeader({
    required this.design,
    required this.canManage,
    required this.actionLoading,
    required this.onBack,
    required this.onRefresh,
    required this.onVariation,
    required this.onDelete,
  });
  final DesignRecord design;
  final bool canManage;
  final bool actionLoading;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback? onVariation;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton.filledTonal(
        tooltip: 'Back to home',
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              design.projectName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.5,
              ),
            ),
            Text(
              'Design command center · ${design.status.label}',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Refresh design',
        onPressed: actionLoading ? null : onRefresh,
        icon: const Icon(Icons.refresh_rounded),
      ),
      if (canManage)
        PopupMenuButton<String>(
          enabled: !actionLoading,
          onSelected: (value) {
            if (value == 'variation') onVariation?.call();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'variation',
              enabled: onVariation != null,
              child: const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.auto_awesome_rounded),
                title: Text('Generate variation'),
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.danger,
                ),
                title: Text(
                  'Delete version',
                  style: TextStyle(color: AppTheme.danger),
                ),
              ),
            ),
          ],
        ),
    ],
  );
}

class _ModeAndExportBar extends StatelessWidget {
  const _ModeAndExportBar({
    required this.mode,
    required this.hasThreeD,
    required this.canManage,
    required this.loading,
    required this.onDrawing,
    required this.onThreeD,
    required this.onSvg,
    required this.onPdf,
  });
  final DesignViewMode mode;
  final bool hasThreeD;
  final bool canManage;
  final bool loading;
  final VoidCallback onDrawing;
  final VoidCallback onThreeD;
  final VoidCallback onSvg;
  final VoidCallback? onPdf;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.all(10),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _ModeButton(
          label: '2D drawings',
          icon: Icons.grid_4x4_rounded,
          selected: mode == DesignViewMode.drawing,
          onTap: loading ? null : onDrawing,
        ),
        _ModeButton(
          label: hasThreeD
              ? 'Furnished 3D'
              : canManage
              ? 'Generate 3D · 25 cr'
              : '3D unavailable',
          icon: hasThreeD
              ? Icons.view_in_ar_rounded
              : Icons.lock_outline_rounded,
          selected: mode == DesignViewMode.threeD,
          onTap: loading || (!hasThreeD && !canManage) ? null : onThreeD,
        ),
        const SizedBox(width: 4),
        OutlinedButton.icon(
          onPressed: loading ? null : onSvg,
          icon: const Icon(Icons.code_rounded, size: 17),
          label: const Text('Share SVG'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42)),
        ),
        OutlinedButton.icon(
          onPressed: loading ? null : onPdf,
          icon: const Icon(Icons.picture_as_pdf_rounded, size: 17),
          label: const Text('Share PDF'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42)),
        ),
      ],
    ),
  );
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected
        ? AppTheme.orange.withValues(alpha: .11)
        : Colors.transparent,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? AppTheme.orange : AppTheme.muted,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? AppTheme.orange : null,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ViewerWorkspace extends StatelessWidget {
  const _ViewerWorkspace({
    required this.design,
    required this.floorNumber,
    required this.drawingType,
    required this.mode,
    required this.canManage,
    required this.loading,
    required this.onDrawing,
  });
  final DesignRecord design;
  final int floorNumber;
  final DesignDrawingType drawingType;
  final DesignViewMode mode;
  final bool canManage;
  final bool loading;
  final ValueChanged<DesignDrawingType> onDrawing;

  @override
  Widget build(BuildContext context) {
    final floor = design.outputs.floorPlans
        .where((item) => item.floorNumber == floorNumber)
        .firstOrNull;
    final svg = mode == DesignViewMode.threeD
        ? design.outputs.threeD[floorNumber]?.svg ?? ''
        : design.outputs.svgFor(drawingType, floorNumber);
    final title = mode == DesignViewMode.threeD
        ? design.outputs.threeD[floorNumber]?.label ?? 'Furnished 3D concept'
        : '${drawingType.label} · ${floor?.label ?? 'Floor $floorNumber'}';
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 940;
        final canvas = SizedBox(
          height: wide ? 660 : 500,
          child: DesignCanvas(
            svg: svg,
            title: title,
            mode: mode,
            heroTag: 'design-preview-${design.id}',
          ),
        );
        final side = Column(
          children: [
            DesignDisciplinePanel(
              design: design,
              selected: drawingType,
              canManage: canManage,
              loading: loading,
              onSelected: onDrawing,
            ),
            const SizedBox(height: 12),
            DesignRoomSchedule(layout: floor?.layout ?? design.outputs.layout),
          ],
        );
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 300, child: side),
              const SizedBox(width: 14),
              Expanded(child: canvas),
            ],
          );
        }
        return Column(children: [canvas, const SizedBox(height: 12), side]);
      },
    );
  }
}

class _ActionNotice extends StatelessWidget {
  const _ActionNotice({required this.action});
  final DesignActionState action;

  @override
  Widget build(BuildContext context) {
    final failed = action.value.hasError;
    final tone = failed ? AppTheme.danger : AppTheme.blue;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tone.withValues(alpha: .2)),
      ),
      child: Row(
        children: [
          if (action.isLoading)
            SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: tone),
            )
          else
            Icon(Icons.error_outline_rounded, color: tone, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              failed ? '${action.value.error}' : action.message,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: tone,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableDesign extends StatelessWidget {
  const _UnavailableDesign({required this.design});
  final DesignRecord design;

  @override
  Widget build(BuildContext context) => EmptyPanel(
    title: switch (design.status) {
      DesignStatus.failed => 'Generation failed',
      DesignStatus.processing => 'Generation is processing',
      DesignStatus.queued => 'Generation is queued',
      DesignStatus.completed => 'Drawing output unavailable',
    },
    message: design.error?.isNotEmpty == true
        ? design.error!
        : 'Refresh this version to retrieve the latest backend generation status.',
    icon: design.status == DesignStatus.failed
        ? Icons.error_outline_rounded
        : Icons.hourglass_top_rounded,
  );
}

class _ViewerSkeleton extends StatelessWidget {
  const _ViewerSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: const [
      AppSkeleton(height: 50),
      SizedBox(height: 16),
      AppSkeleton(height: 190, radius: 30),
      SizedBox(height: 16),
      AppSkeleton(height: 560),
    ],
  );
}

class _ViewerError extends StatelessWidget {
  const _ViewerError({
    required this.error,
    required this.onBack,
    required this.onRetry,
  });
  final Object error;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Row(
        children: [
          IconButton.filledTonal(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ],
      ),
      const SizedBox(height: 50),
      EmptyPanel(
        title: 'Design version unavailable',
        message: '$error',
        icon: Icons.cloud_off_rounded,
        actionLabel: 'Try again',
        onAction: onRetry,
      ),
    ],
  );
}

String _fileStem(String value) {
  final normalized = value.trim().toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]+'),
    '-',
  );
  return normalized.replaceAll(RegExp(r'^-+|-+$'), '').isEmpty
      ? 'siteseva-design'
      : normalized.replaceAll(RegExp(r'^-+|-+$'), '');
}
