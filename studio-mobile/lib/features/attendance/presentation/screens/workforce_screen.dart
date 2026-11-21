import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../models/workforce_models.dart';
import '../../providers/workforce_provider.dart';
import '../widgets/workforce_creation_sheet.dart';
import '../widgets/workforce_widgets.dart';

class WorkforceScreen extends ConsumerWidget {
  const WorkforceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workforceStudioControllerProvider);
    final canManage =
        ref.watch(authControllerProvider).valueOrNull?.isContractor == true;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: state.when(
          loading: () => const WorkforceSkeleton(),
          error: (error, stackTrace) => _WorkforceError(
            error: error,
            onRetry: () =>
                ref.read(workforceStudioControllerProvider.notifier).load(),
          ),
          data: (data) => RefreshIndicator(
            color: AppTheme.orange,
            onRefresh: () =>
                ref.read(workforceStudioControllerProvider.notifier).refresh(),
            child: LayoutBuilder(
              builder: (context, constraints) => ListView(
                key: const PageStorageKey('workforce-directory-scroll'),
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
                          _WorkforceHeader(
                            canManage: canManage,
                            onCreate: () => _openCreation(context, ref, data),
                            onRefresh: () => ref
                                .read(
                                  workforceStudioControllerProvider.notifier,
                                )
                                .refresh(),
                          ),
                          if (data.isOffline) ...[
                            const SizedBox(height: 14),
                            WorkforceOfflineBanner(syncedAt: data.fetchedAt),
                          ],
                          const SizedBox(height: 18),
                          WorkforcePortfolioHero(
                            data: data,
                            canManage: canManage,
                            onCreate: () => _openCreation(context, ref, data),
                          ),
                          const SizedBox(height: 26),
                          Text(
                            'Connected workforce workflow',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.5,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Capabilities supplied by the current labour, wallet and payroll services.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.muted),
                          ),
                          const SizedBox(height: 13),
                          const WorkforceCapabilityGrid(),
                          const SizedBox(height: 26),
                          _WorkforceFilters(data: data),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Workforce directory',
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
                                      '${data.visibleMembers.length} of ${data.members.length} profiles shown',
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
                                      _openCreation(context, ref, data),
                                  icon: const Icon(
                                    Icons.person_add_alt_1_rounded,
                                  ),
                                  label: const Text('Add member'),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 50),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 13),
                          if (data.members.isEmpty)
                            EmptyPanel(
                              title: 'No workforce profiles',
                              message: canManage
                                  ? 'Add the first project worker to enable attendance and payroll.'
                                  : 'No workforce profiles are assigned to your project sites.',
                              icon: Icons.groups_outlined,
                              actionLabel: canManage ? 'Add member' : null,
                              onAction: canManage
                                  ? () => _openCreation(context, ref, data)
                                  : null,
                            )
                          else
                            WorkforceGrid(
                              data: data,
                              canManage: canManage,
                              onDelete: (member) =>
                                  _confirmDelete(context, ref, member),
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

  Future<void> _openCreation(
    BuildContext context,
    WidgetRef ref,
    WorkforceStudioData data,
  ) async {
    final memberId = await showWorkforceCreationSheet(context, ref, data: data);
    if (memberId != null && context.mounted) context.go('/labour/$memberId');
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    WorkforceMember member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove workforce profile?'),
        content: Text(
          'Remove ${member.displayName} from the active workforce directory? Historical attendance and wallet records are controlled by the backend.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await ref
        .read(workforceActionControllerProvider.notifier)
        .delete(member.id);
    if (deleted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.displayName} was removed.')),
      );
    }
  }
}

class _WorkforceHeader extends StatelessWidget {
  const _WorkforceHeader({
    required this.canManage,
    required this.onCreate,
    required this.onRefresh,
  });
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
              'Workforce',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.9,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Crew profiles, wage context and wallet visibility.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
      IconButton.filledTonal(
        tooltip: 'Refresh workforce',
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh_rounded),
      ),
      if (canManage) ...[
        const SizedBox(width: 8),
        IconButton.filled(
          tooltip: 'Add workforce member',
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded),
          style: IconButton.styleFrom(backgroundColor: AppTheme.orange),
        ),
      ],
    ],
  ).animate().fadeIn(duration: 240.ms);
}

class _WorkforceFilters extends ConsumerWidget {
  const _WorkforceFilters({required this.data});
  final WorkforceStudioData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(workforceStudioControllerProvider.notifier);
    return Column(
      children: [
        TextField(
          onChanged: controller.setQuery,
          decoration: const InputDecoration(
            hintText: 'Search name, trade, mobile, project or location',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 11),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _SiteChip(
                label: 'All projects',
                selected: data.siteFilter == null,
                onTap: () => controller.setSite(null),
              ),
              ...data.sites.map(
                (site) => _SiteChip(
                  label: site.name,
                  selected: data.siteFilter == site.id,
                  onTap: () => controller.setSite(site.id),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SiteChip extends StatelessWidget {
  const _SiteChip({
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
    child: Material(
      color: selected
          ? AppTheme.blue.withValues(alpha: .09)
          : Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppTheme.blue : AppTheme.line),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: selected ? AppTheme.blue : AppTheme.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    ),
  );
}

class _WorkforceError extends StatelessWidget {
  const _WorkforceError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      EmptyPanel(
        title: 'Workforce directory unavailable',
        message: '$error',
        icon: Icons.cloud_off_rounded,
        actionLabel: 'Try again',
        onAction: onRetry,
      ),
    ],
  );
}
