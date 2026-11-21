import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/boq_models.dart';
import '../../providers/boq_provider.dart';

Future<String?> showBoqGenerationSheet(
  BuildContext context,
  WidgetRef ref, {
  required BoqStudioData data,
}) {
  ref.read(boqGenerationBriefProvider.notifier).reset();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _BoqGenerationSheet(data: data),
  );
}

class _BoqGenerationSheet extends ConsumerWidget {
  const _BoqGenerationSheet({required this.data});
  final BoqStudioData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brief = ref.watch(boqGenerationBriefProvider);
    final action = ref.watch(boqActionControllerProvider);
    final estimates = brief.siteId.isEmpty
        ? const <BoqEstimateSummary>[]
        : data.estimatesForSite(brief.siteId);
    final selectedEstimate = estimates
        .where((estimate) => estimate.id == brief.estimateId)
        .firstOrNull;
    return FractionallySizedBox(
      heightFactor: .94,
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
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.orange.withValues(alpha: .11),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.add_chart_rounded,
                              color: AppTheme.orange,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Generate project BOQ',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Create one server-calculated issued worksheet.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppTheme.muted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: action.isLoading
                                ? null
                                : () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        enabled: !action.isLoading,
                        onChanged: ref
                            .read(boqGenerationBriefProvider.notifier)
                            .setName,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'BOQ name',
                          hintText: 'Orchid Residence - Tender BOQ',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        key: ValueKey('boq-site-${brief.siteId}'),
                        initialValue: brief.siteId.isEmpty
                            ? null
                            : brief.siteId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Project site',
                          prefixIcon: Icon(Icons.apartment_rounded),
                        ),
                        hint: const Text('Choose a live project'),
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
                                if (value != null) {
                                  ref
                                      .read(boqGenerationBriefProvider.notifier)
                                      .setSite(value);
                                }
                              },
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Quantity source',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Use an approved estimate when available, or enter a verified measured area.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 520;
                          final cards = [
                            _SourceCard(
                              selected:
                                  brief.source == BoqGenerationSource.estimate,
                              icon: Icons.calculate_outlined,
                              title: 'Approved estimate',
                              message:
                                  'Use its server-calculated built-up area.',
                              onTap: action.isLoading
                                  ? null
                                  : () => ref
                                        .read(
                                          boqGenerationBriefProvider.notifier,
                                        )
                                        .setSource(
                                          BoqGenerationSource.estimate,
                                        ),
                            ),
                            _SourceCard(
                              selected:
                                  brief.source ==
                                  BoqGenerationSource.measuredArea,
                              icon: Icons.square_foot_rounded,
                              title: 'Measured area',
                              message:
                                  'Enter a verified built-up square footage.',
                              onTap: action.isLoading
                                  ? null
                                  : () => ref
                                        .read(
                                          boqGenerationBriefProvider.notifier,
                                        )
                                        .setSource(
                                          BoqGenerationSource.measuredArea,
                                        ),
                            ),
                          ];
                          if (wide) {
                            return Row(
                              children: [
                                Expanded(child: cards.first),
                                const SizedBox(width: 10),
                                Expanded(child: cards.last),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              cards.first,
                              const SizedBox(height: 10),
                              cards.last,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      if (brief.source == BoqGenerationSource.estimate) ...[
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                            'boq-estimate-${brief.siteId}-${brief.estimateId}',
                          ),
                          initialValue: brief.estimateId.isEmpty
                              ? null
                              : brief.estimateId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Source estimate',
                            prefixIcon: Icon(Icons.request_quote_outlined),
                          ),
                          hint: Text(
                            brief.siteId.isEmpty
                                ? 'Choose a project site first'
                                : estimates.isEmpty
                                ? 'No estimates for this project'
                                : 'Choose an approved estimate',
                          ),
                          items: estimates
                              .map(
                                (estimate) => DropdownMenuItem(
                                  value: estimate.id,
                                  child: Text(
                                    '${estimate.name} - ${estimate.builtupSqft.round()} sq ft',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: action.isLoading || estimates.isEmpty
                              ? null
                              : (value) {
                                  if (value != null) {
                                    ref
                                        .read(
                                          boqGenerationBriefProvider.notifier,
                                        )
                                        .setEstimate(value);
                                  }
                                },
                        ),
                        if (selectedEstimate != null) ...[
                          const SizedBox(height: 12),
                          _EstimateSummary(estimate: selectedEstimate),
                        ],
                      ] else
                        TextField(
                          enabled: !action.isLoading,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: ref
                              .read(boqGenerationBriefProvider.notifier)
                              .setBuiltup,
                          decoration: const InputDecoration(
                            labelText: 'Verified built-up area',
                            hintText: '4500',
                            suffixText: 'sq ft',
                            prefixIcon: Icon(Icons.straighten_rounded),
                          ),
                        ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.blue.withValues(alpha: .07),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppTheme.blue.withValues(alpha: .16),
                          ),
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
                                'The backend applies the current SiteSeva quantity factors and unit-rate template. GST, vendor quotes and manual line edits are not included in this API version.',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppTheme.muted,
                                      height: 1.45,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (action.value.hasError) ...[
                        const SizedBox(height: 14),
                        _GenerationError(error: action.value.error!),
                      ],
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: action.isLoading
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
                            : const Icon(Icons.functions_rounded),
                        label: Text(
                          action.isLoading
                              ? 'Calculating server quantities...'
                              : 'Generate issued BOQ',
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
    BoqGenerationBrief brief,
  ) async {
    final validation = brief.validationMessage;
    if (validation != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validation)));
      return;
    }
    final document = await ref
        .read(boqActionControllerProvider.notifier)
        .generate(brief);
    if (document != null && context.mounted) {
      Navigator.pop(context, document.id);
    }
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.message,
    required this.onTap,
  });
  final bool selected;
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    onTap: onTap,
    color: selected ? AppTheme.orange.withValues(alpha: .06) : null,
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.orange.withValues(alpha: .12)
                : AppTheme.line.withValues(alpha: .55),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: selected ? AppTheme.orange : AppTheme.muted,
            size: 20,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
              ),
            ],
          ),
        ),
        Icon(
          selected
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: selected ? AppTheme.orange : AppTheme.muted,
          size: 19,
        ),
      ],
    ),
  );
}

class _EstimateSummary extends StatelessWidget {
  const _EstimateSummary({required this.estimate});
  final BoqEstimateSummary estimate;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Row(
      children: [
        Expanded(
          child: _SummaryValue(
            label: 'BUILT-UP',
            value: '${estimate.builtupSqft.round()} sq ft',
          ),
        ),
        Expanded(
          child: _SummaryValue(
            label: 'BUDGET',
            value: compactInr(estimate.total),
          ),
        ),
        Expanded(
          child: _SummaryValue(
            label: 'QUALITY',
            value: estimate.qualityBand.isEmpty
                ? 'Not set'
                : estimate.qualityBand,
          ),
        ),
      ],
    ),
  );
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.muted,
          fontSize: 8,
          letterSpacing: .4,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    ],
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
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.danger.withValues(alpha: .18)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.danger,
            size: 19,
          ),
          const SizedBox(width: 9),
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
