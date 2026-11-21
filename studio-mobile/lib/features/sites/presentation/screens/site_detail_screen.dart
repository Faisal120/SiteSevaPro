import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/site_models.dart';
import '../../providers/sites_provider.dart';
import '../widgets/site_detail_sections.dart';
import '../widgets/site_form_sheet.dart';

class SiteDetailScreen extends ConsumerStatefulWidget {
  const SiteDetailScreen({super.key, required this.siteId});

  final String siteId;

  @override
  ConsumerState<SiteDetailScreen> createState() => _SiteDetailScreenState();
}

class _SiteDetailScreenState extends ConsumerState<SiteDetailScreen> {
  SiteWorkspaceTab _selected = SiteWorkspaceTab.overview;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final site = ref.watch(siteDetailControllerProvider(widget.siteId));
    if (user == null) return const SizedBox.shrink();
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: site.when(
          loading: () => const _DetailLoading(),
          error: (error, stackTrace) => _DetailError(
            error: error,
            onBack: _goBack,
            onRetry: () => ref
                .read(siteDetailControllerProvider(widget.siteId).notifier)
                .load(),
          ),
          data: (detail) => RefreshIndicator(
            color: AppTheme.orange,
            onRefresh: () => _refresh(user),
            child: LayoutBuilder(
              builder: (context, constraints) => ListView(
                key: PageStorageKey('site-detail-scroll-${widget.siteId}'),
                primary: false,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  constraints.maxWidth >= 900 ? 30 : 18,
                  16,
                  constraints.maxWidth >= 900 ? 30 : 18,
                  124,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DetailHeader(
                            site: detail,
                            canManage: user.canManageSites,
                            onBack: _goBack,
                            onEdit: () => _edit(detail),
                            onDelete: () => _delete(detail),
                            onRefresh: () => _refresh(user),
                          ),
                          const SizedBox(height: 18),
                          SiteDetailHero(site: detail),
                          const SizedBox(height: 20),
                          _WorkspaceTabs(
                            tabs: siteTabsFor(user),
                            selected: _selected,
                            onSelected: (value) =>
                                setState(() => _selected = value),
                          ),
                          const SizedBox(height: 22),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            switchInCurve: Curves.easeOutCubic,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, .025),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                            child: KeyedSubtree(
                              key: ValueKey(_selected),
                              child: _tabContent(detail, user),
                            ),
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

  Widget _tabContent(SiteDetail site, AuthUser user) => switch (_selected) {
    SiteWorkspaceTab.overview => SiteOverviewSection(site: site, user: user),
    SiteWorkspaceTab.reports => SiteReportsSection(siteId: site.id, user: user),
    SiteWorkspaceTab.workforce => SiteWorkforceSection(siteId: site.id),
    SiteWorkspaceTab.materials => SiteMaterialsSection(siteId: site.id),
    SiteWorkspaceTab.payments => SitePaymentsSection(
      siteId: site.id,
      user: user,
    ),
    SiteWorkspaceTab.attendance => SiteAttendanceSection(siteId: site.id),
  };

  Future<void> _refresh(AuthUser user) async {
    await ref
        .read(siteDetailControllerProvider(widget.siteId).notifier)
        .refresh();
    ref.invalidate(siteReportsProvider(widget.siteId));
    if (!user.isClient) {
      ref.invalidate(siteLabourProvider(widget.siteId));
      ref.invalidate(siteMaterialsProvider(widget.siteId));
      ref.invalidate(siteAttendanceProvider(widget.siteId));
    }
    if (!user.isSupervisor) {
      ref.invalidate(sitePaymentsProvider(widget.siteId));
    }
  }

  void _goBack() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      context.go('/sites');
    }
  }

  Future<void> _edit(SiteDetail site) async {
    final saved = await showSiteFormSheet(context, ref, initial: site);
    if (saved != null && mounted) {
      await ref
          .read(siteDetailControllerProvider(widget.siteId).notifier)
          .refresh();
    }
  }

  Future<void> _delete(SiteDetail site) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete site workspace?'),
        content: Text(
          '${site.name} will be removed from the live backend. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Delete site'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final deleted = await ref
        .read(siteMutationControllerProvider.notifier)
        .delete(site.id);
    if (!mounted) return;
    if (deleted) {
      context.go('/sites');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${ref.read(siteMutationControllerProvider).error ?? 'Could not delete site'}',
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.site,
    required this.canManage,
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
  });

  final SiteDetail site;
  final bool canManage;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton.filledTonal(
        tooltip: 'Back',
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              site.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Site command center · ${site.status.label}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Refresh site',
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh_rounded),
      ),
      if (canManage)
        PopupMenuButton<_SiteMenuAction>(
          tooltip: 'Manage site',
          icon: const Icon(Icons.more_horiz_rounded),
          onSelected: (action) {
            if (action == _SiteMenuAction.edit) onEdit();
            if (action == _SiteMenuAction.assignTeam) onEdit();
            if (action == _SiteMenuAction.delete) onDelete();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: _SiteMenuAction.edit,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.edit_outlined),
                title: Text('Edit site'),
              ),
            ),
            PopupMenuItem(
              value: _SiteMenuAction.assignTeam,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.group_add_outlined),
                title: Text('Assign supervisor & client'),
              ),
            ),
            PopupMenuItem(
              value: _SiteMenuAction.delete,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.danger,
                ),
                title: Text(
                  'Delete site',
                  style: TextStyle(color: AppTheme.danger),
                ),
              ),
            ),
          ],
        ),
    ],
  ).animate().fadeIn(duration: 220.ms);
}

class _WorkspaceTabs extends StatelessWidget {
  const _WorkspaceTabs({
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  final List<SiteWorkspaceTab> tabs;
  final SiteWorkspaceTab selected;
  final ValueChanged<SiteWorkspaceTab> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: tabs
          .map(
            (tab) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(tab.label),
                selected: selected == tab,
                onSelected: (_) => onSelected(tab),
                selectedColor: AppTheme.orange.withValues(alpha: .12),
                side: BorderSide(
                  color: selected == tab ? AppTheme.orange : AppTheme.line,
                ),
                labelStyle: TextStyle(
                  color: selected == tab ? AppTheme.orange : AppTheme.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _DetailLoading extends StatelessWidget {
  const _DetailLoading();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
    children: const [
      AppSkeleton(height: 52, radius: 18),
      SizedBox(height: 18),
      AppSkeleton(height: 268, radius: 32),
      SizedBox(height: 20),
      AppSkeleton(height: 42, radius: 18),
      SizedBox(height: 20),
      AppSkeleton(height: 240, radius: 24),
    ],
  );
}

class _DetailError extends StatelessWidget {
  const _DetailError({
    required this.error,
    required this.onBack,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(20),
    children: [
      Row(
        children: [
          IconButton.filledTonal(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 10),
          Text(
            'Site command center',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
      const SizedBox(height: 70),
      EmptyPanel(
        title: 'Site unavailable',
        message: '$error',
        icon: Icons.cloud_off_rounded,
        actionLabel: 'Try again',
        onAction: onRetry,
      ),
    ],
  );
}

enum _SiteMenuAction { edit, assignTeam, delete }
