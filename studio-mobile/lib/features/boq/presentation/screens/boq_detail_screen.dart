import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/boq_models.dart';
import '../../providers/boq_provider.dart';
import '../widgets/boq_detail_widgets.dart';

class BoqDetailScreen extends ConsumerWidget {
  const BoqDetailScreen({super.key, required this.boqId});
  final String boqId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(boqDetailControllerProvider(boqId));
    final studio = ref.watch(boqStudioControllerProvider).valueOrNull;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: detail.when(
          loading: () => const _BoqDetailSkeleton(),
          error: (error, stackTrace) => _BoqDetailError(
            error: error,
            onBack: () => context.go('/'),
            onRetry: () =>
                ref.read(boqDetailControllerProvider(boqId).notifier).load(),
          ),
          data: (document) {
            final siteName =
                studio?.siteFor(document.siteId)?.name ?? 'Project site';
            final estimate = studio?.estimateFor(document.estimateId);
            final vendors = studio?.vendors ?? const <BoqVendorSummary>[];
            return LayoutBuilder(
              builder: (context, constraints) => ListView(
                key: PageStorageKey('boq-detail-$boqId'),
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
                          _BoqDetailHeader(
                            document: document,
                            onBack: () => context.go('/'),
                            onRefresh: () => ref
                                .read(
                                  boqDetailControllerProvider(boqId).notifier,
                                )
                                .load(),
                          ),
                          const SizedBox(height: 16),
                          BoqDetailHero(document: document, siteName: siteName)
                              .animate()
                              .fadeIn(duration: 300.ms)
                              .slideY(begin: .04, end: 0),
                          const SizedBox(height: 14),
                          const BoqIssuedNotice(),
                          const SizedBox(height: 18),
                          _BoqDetailWorkspace(
                            document: document,
                            estimate: estimate,
                            vendors: vendors,
                          ),
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
}

class _BoqDetailHeader extends StatelessWidget {
  const _BoqDetailHeader({
    required this.document,
    required this.onBack,
    required this.onRefresh,
  });
  final BoqDocument document;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

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
              document.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.5,
              ),
            ),
            Text(
              'Issued quantity and rate worksheet',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Refresh BOQ',
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
  );
}

class _BoqDetailWorkspace extends StatelessWidget {
  const _BoqDetailWorkspace({
    required this.document,
    required this.estimate,
    required this.vendors,
  });
  final BoqDocument document;
  final BoqEstimateSummary? estimate;
  final List<BoqVendorSummary> vendors;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final side = Column(
        children: [
          BoqCostComposition(document: document),
          const SizedBox(height: 12),
          BoqSourceContext(document: document, estimate: estimate),
          const SizedBox(height: 12),
          BoqVendorDirectory(vendors: vendors),
        ],
      );
      final worksheet = BoqWorksheet(document: document);
      if (constraints.maxWidth >= 980) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 310, child: side),
            const SizedBox(width: 16),
            Expanded(child: worksheet),
          ],
        );
      }
      return Column(children: [side, const SizedBox(height: 22), worksheet]);
    },
  );
}

class _BoqDetailSkeleton extends StatelessWidget {
  const _BoqDetailSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
    children: const [
      AppSkeleton(height: 50),
      SizedBox(height: 16),
      AppSkeleton(height: 198, radius: 30),
      SizedBox(height: 14),
      AppSkeleton(height: 54),
      SizedBox(height: 18),
      AppSkeleton(height: 460),
    ],
  );
}

class _BoqDetailError extends StatelessWidget {
  const _BoqDetailError({
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
      Align(
        alignment: Alignment.centerLeft,
        child: IconButton.filledTonal(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      const SizedBox(height: 16),
      EmptyPanel(
        title: 'BOQ unavailable',
        message: '$error',
        icon: Icons.cloud_off_rounded,
        actionLabel: 'Try again',
        onAction: onRetry,
      ),
    ],
  );
}
