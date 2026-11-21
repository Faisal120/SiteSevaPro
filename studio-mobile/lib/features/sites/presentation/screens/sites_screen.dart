import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/site_models.dart';
import '../../providers/sites_provider.dart';
import '../widgets/site_form_sheet.dart';
import '../widgets/site_widgets.dart';

class SitesScreen extends ConsumerWidget {
  const SitesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sites = ref.watch(sitesControllerProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final canManage = user?.canManageSites ?? false;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: sites.when(
          loading: () => const SiteListSkeleton(),
          error: (error, stackTrace) => _SitesError(
            error: error,
            onRetry: () => ref.read(sitesControllerProvider.notifier).load(),
          ),
          data: (collection) => RefreshIndicator(
            color: AppTheme.orange,
            onRefresh: () =>
                ref.read(sitesControllerProvider.notifier).refresh(),
            child: LayoutBuilder(
              builder: (context, constraints) => ListView(
                key: const PageStorageKey('sites-portfolio-scroll'),
                primary: false,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  constraints.maxWidth >= 900 ? 30 : 18,
                  18,
                  constraints.maxWidth >= 900 ? 30 : 18,
                  124,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SitesHeader(
                            roleLabel: user?.roleLabel ?? 'Workspace',
                            canManage: canManage,
                            onCreate: () => showSiteFormSheet(context, ref),
                            onRefresh: () => ref
                                .read(sitesControllerProvider.notifier)
                                .refresh(),
                          ),
                          if (collection.isOffline) ...[
                            const SizedBox(height: 14),
                            SiteOfflineBanner(syncedAt: collection.fetchedAt),
                          ],
                          const SizedBox(height: 20),
                          SitePortfolioHero(collection: collection),
                          const SizedBox(height: 24),
                          _SiteSearchAndFilters(collection: collection),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.isClient == true
                                          ? 'My projects'
                                          : user?.isSupervisor == true
                                          ? 'Assigned sites'
                                          : 'Project portfolio',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -.5,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${collection.visibleSites.length} of ${collection.sites.length} sites shown',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppTheme.muted),
                                    ),
                                  ],
                                ),
                              ),
                              if (canManage && constraints.maxWidth >= 640)
                                FilledButton.icon(
                                  onPressed: () =>
                                      showSiteFormSheet(context, ref),
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Create site'),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 52),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _SiteGrid(
                            sites: collection.visibleSites,
                            canManage: canManage,
                            hasFilters:
                                collection.query.isNotEmpty ||
                                collection.filter != null,
                            onCreate: () => showSiteFormSheet(context, ref),
                            onClear: () {
                              final controller = ref.read(
                                sitesControllerProvider.notifier,
                              );
                              controller.setQuery('');
                              controller.setFilter(null);
                            },
                          ),
                        ],
                      ),
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
}

class _SitesHeader extends StatelessWidget {
  const _SitesHeader({
    required this.roleLabel,
    required this.canManage,
    required this.onCreate,
    required this.onRefresh,
  });

  final String roleLabel;
  final bool canManage;
  final VoidCallback onCreate;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sites',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.9,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$roleLabel workspace · live construction portfolio',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
      IconButton.filledTonal(
        tooltip: 'Refresh sites',
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh_rounded),
      ),
      if (canManage) ...[
        const SizedBox(width: 8),
        IconButton.filled(
          tooltip: 'Create site',
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded),
          style: IconButton.styleFrom(backgroundColor: AppTheme.orange),
        ),
      ],
    ],
  ).animate().fadeIn(duration: 240.ms);
}

class _SiteSearchAndFilters extends ConsumerWidget {
  const _SiteSearchAndFilters({required this.collection});

  final SiteCollection collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        onChanged: ref.read(sitesControllerProvider.notifier).setQuery,
        decoration: const InputDecoration(
          hintText: 'Search site, location, client or supervisor',
          prefixIcon: Icon(Icons.search_rounded),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _FilterChip(
              label: 'All ${collection.sites.length}',
              selected: collection.filter == null,
              onTap: () =>
                  ref.read(sitesControllerProvider.notifier).setFilter(null),
            ),
            ...SiteStatus.values.map(
              (status) => _FilterChip(
                label: '${status.label} ${collection.count(status)}',
                selected: collection.filter == status,
                onTap: () => ref
                    .read(sitesControllerProvider.notifier)
                    .setFilter(status),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.orange.withValues(alpha: .12),
      side: BorderSide(color: selected ? AppTheme.orange : AppTheme.line),
      labelStyle: TextStyle(
        color: selected ? AppTheme.orange : AppTheme.muted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _SiteGrid extends StatelessWidget {
  const _SiteGrid({
    required this.sites,
    required this.canManage,
    required this.hasFilters,
    required this.onCreate,
    required this.onClear,
  });

  final List<SiteSummary> sites;
  final bool canManage;
  final bool hasFilters;
  final VoidCallback onCreate;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (sites.isEmpty) {
      return EmptyPanel(
        title: hasFilters ? 'No matching sites' : 'No sites yet',
        message: hasFilters
            ? 'Clear the search or choose another project status.'
            : canManage
            ? 'Create your first governed project workspace to begin field operations.'
            : 'No construction site is assigned to your account yet.',
        icon: Icons.apartment_outlined,
        actionLabel: hasFilters
            ? 'Clear filters'
            : canManage
            ? 'Create site'
            : null,
        onAction: hasFilters
            ? onClear
            : canManage
            ? onCreate
            : null,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1020
            ? 3
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: sites.indexed
              .map(
                (entry) => SizedBox(
                  width: width,
                  height: 330,
                  child: SiteProjectCard(site: entry.$2)
                      .animate(delay: (entry.$1 * 45).ms)
                      .fadeIn(duration: 240.ms)
                      .slideY(begin: .07, end: 0),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SitesError extends StatelessWidget {
  const _SitesError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(20),
    children: [
      const SizedBox(height: 70),
      EmptyPanel(
        title: 'Sites are unavailable',
        message: '$error',
        icon: Icons.cloud_off_rounded,
        actionLabel: 'Try again',
        onAction: onRetry,
      ),
    ],
  );
}
