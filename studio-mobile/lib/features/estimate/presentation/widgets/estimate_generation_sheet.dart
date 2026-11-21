import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/estimate_models.dart';
import '../../providers/estimate_provider.dart';

Future<String?> showEstimateGenerationSheet(
  BuildContext context,
  WidgetRef ref, {
  required EstimateStudioData data,
}) {
  ref.read(estimateBriefProvider.notifier).reset();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _EstimateGenerationSheet(data: data),
  );
}

class _EstimateGenerationSheet extends ConsumerWidget {
  const _EstimateGenerationSheet({required this.data});
  final EstimateStudioData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brief = ref.watch(estimateBriefProvider);
    final action = ref.watch(estimateActionControllerProvider);
    final editor = ref.read(estimateBriefProvider.notifier);
    return FractionallySizedBox(
      heightFactor: .95,
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
                    children: [
                      _GenerationHeader(
                        busy: action.isLoading,
                        onClose: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        enabled: !action.isLoading,
                        onChanged: editor.setName,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Estimate name',
                          hintText: 'Orchid Residence - Feasibility Plan',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        key: ValueKey('estimate-site-${brief.siteId}'),
                        initialValue: brief.siteId.isEmpty
                            ? null
                            : brief.siteId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Project site',
                          prefixIcon: Icon(Icons.apartment_rounded),
                        ),
                        hint: Text(
                          data.sites.isEmpty
                              ? 'No project sites available'
                              : 'Choose a live project',
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
                        onChanged: action.isLoading || data.sites.isEmpty
                            ? null
                            : (value) {
                                if (value != null) editor.setSite(value);
                              },
                      ),
                      const SizedBox(height: 22),
                      _SectionHeading(
                        title: 'Project assumptions',
                        message:
                            'Enter verified geometry and the intended construction specification.',
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 540;
                          final plot = TextField(
                            enabled: !action.isLoading,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: editor.setPlotArea,
                            decoration: const InputDecoration(
                              labelText: 'Plot area',
                              hintText: '2400',
                              suffixText: 'sq ft',
                              prefixIcon: Icon(Icons.square_foot_rounded),
                            ),
                          );
                          final floors = TextField(
                            enabled: !action.isLoading,
                            keyboardType: TextInputType.number,
                            onChanged: editor.setFloors,
                            decoration: const InputDecoration(
                              labelText: 'Floors',
                              hintText: '2',
                              prefixIcon: Icon(Icons.layers_outlined),
                            ),
                          );
                          if (wide) {
                            return Row(
                              children: [
                                Expanded(child: plot),
                                const SizedBox(width: 12),
                                Expanded(child: floors),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              plot,
                              const SizedBox(height: 12),
                              floors,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<EstimateConstructionType>(
                        initialValue: brief.constructionType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Construction type',
                          prefixIcon: Icon(Icons.domain_outlined),
                        ),
                        items: EstimateConstructionType.values
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type.label),
                              ),
                            )
                            .toList(),
                        onChanged: action.isLoading
                            ? null
                            : (value) {
                                if (value != null) {
                                  editor.setConstructionType(value);
                                }
                              },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<EstimateQuality>(
                        initialValue: brief.quality,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Quality specification',
                          prefixIcon: Icon(Icons.workspace_premium_outlined),
                        ),
                        items: EstimateQuality.values
                            .map(
                              (quality) => DropdownMenuItem(
                                value: quality,
                                child: Text(quality.label),
                              ),
                            )
                            .toList(),
                        onChanged: action.isLoading
                            ? null
                            : (value) {
                                if (value != null) editor.setQuality(value);
                              },
                      ),
                      const SizedBox(height: 12),
                      SurfaceCard(
                        color: brief.basement
                            ? AppTheme.orange.withValues(alpha: .06)
                            : null,
                        onTap: action.isLoading
                            ? null
                            : () => editor.setBasement(!brief.basement),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: brief.basement
                                    ? AppTheme.orange.withValues(alpha: .12)
                                    : AppTheme.line.withValues(alpha: .55),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                Icons.foundation_rounded,
                                color: brief.basement
                                    ? AppTheme.orange
                                    : AppTheme.muted,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Include basement',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Adds the backend basement area and quantity factors.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: AppTheme.muted),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: brief.basement,
                              onChanged: action.isLoading
                                  ? null
                                  : editor.setBasement,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _SectionHeading(
                        title: 'Approved construction budget',
                        message:
                            'The service allocates this amount across material, labour and overhead.',
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        enabled: !action.isLoading,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: editor.setBudget,
                        decoration: const InputDecoration(
                          labelText: 'Budget',
                          hintText: '7500000',
                          prefixText: 'INR  ',
                          prefixIcon: Icon(
                            Icons.account_balance_wallet_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _ApiScopeNotice(),
                      if (action.value.hasError) ...[
                        const SizedBox(height: 14),
                        _GenerationError(error: action.value.error!),
                      ],
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: action.isLoading || data.sites.isEmpty
                            ? null
                            : () => _submit(context, ref, brief),
                        icon: action.isLoading
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.auto_graph_rounded),
                        label: Text(
                          action.isLoading
                              ? 'Calculating on server...'
                              : 'Create feasibility estimate',
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
    );
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    EstimateBrief brief,
  ) async {
    final validation = brief.validationMessage;
    if (validation != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validation)));
      return;
    }
    final estimate = await ref
        .read(estimateActionControllerProvider.notifier)
        .create(brief);
    if (estimate != null && context.mounted) {
      Navigator.pop(context, estimate.id);
    }
  }
}

class _GenerationHeader extends StatelessWidget {
  const _GenerationHeader({required this.busy, required this.onClose});
  final bool busy;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.blue, AppTheme.blueBright],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.calculate_rounded, color: Colors.white),
      ),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create project estimate',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              'Generate a server-calculated feasibility baseline.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Close',
        onPressed: busy ? null : onClose,
        icon: const Icon(Icons.close_rounded),
      ),
    ],
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 4),
      Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppTheme.muted, height: 1.4),
      ),
    ],
  );
}

class _ApiScopeNotice extends StatelessWidget {
  const _ApiScopeNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.blue.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.blue.withValues(alpha: .16)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.verified_user_outlined,
          color: AppTheme.blue,
          size: 19,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'This creates a read-only planning estimate from the current backend rules. GST, discount, terms, payment schedule, images, signature and export are not accepted by this API version.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.muted,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );
}

class _GenerationError extends StatelessWidget {
  const _GenerationError({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    final message = error is ApiException
        ? (error as ApiException).message
        : '$error';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.danger.withValues(alpha: .2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
