import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/models/auth_user.dart';
import '../../models/dashboard_data.dart';
import '../../models/dashboard_experience.dart';
import 'dashboard_primitives.dart';

class DashboardHero extends StatelessWidget {
  const DashboardHero({super.key, required this.user, required this.data});

  final AuthUser user;
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final stats = data.stats;
    final total = stats.totalSites;
    final active = stats.activeSites;
    final completion = total == 0 ? 0.0 : stats.completedSites / total;
    return Container(
      constraints: const BoxConstraints(minHeight: 218),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF070D18), Color(0xFF0C274B), Color(0xFF0F5EB8)],
          stops: [0, .62, 1],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A0A0E17),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _HeroGridPainter()),
          ),
          Positioned(
            right: -48,
            top: -58,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.orange.withValues(alpha: .14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.orange.withValues(alpha: .2),
                    blurRadius: 80,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 390;
              return Padding(
                padding: EdgeInsets.all(compact ? 18 : 22),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.orangeBright,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _eyebrow(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: const Color(0xFFC6CFDC),
                                        fontSize: compact ? 8.5 : null,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: compact ? .45 : .9,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _headline(active, total),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  height: 1.12,
                                  letterSpacing: -.9,
                                ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            _supporting(),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: const Color(0xFFB7C1CF),
                                  height: 1.5,
                                ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: compact ? double.infinity : 184,
                            child: FilledButton.icon(
                              onPressed: () => context.go(_actionPath()),
                              icon: Icon(_actionIcon(), size: 18),
                              label: Text(_actionLabel()),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(46),
                                backgroundColor: AppTheme.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: compact ? 12 : 16),
                    _PortfolioRing(
                      compact: compact,
                      value: completion.clamp(0, 1),
                      centerValue: total == 0
                          ? '0'
                          : '${(completion * 100).round()}%',
                      label: total == 0 ? 'NO SITES' : 'COMPLETED',
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 340.ms).slideY(begin: .06, end: 0);
  }

  String _eyebrow() {
    if (user.isSupervisor) return 'FIELD EXECUTION';
    if (user.isClient) return 'PROJECT VIEW';
    return 'OPERATIONS COMMAND CENTER';
  }

  String _headline(int active, int total) {
    if (total == 0) {
      if (user.isClient) return 'No project is assigned yet.';
      if (user.isSupervisor) return 'No site is assigned yet.';
      return 'Create your first live site.';
    }
    if (user.isClient) {
      return '$active of $total project${total == 1 ? '' : 's'} currently active.';
    }
    if (user.isSupervisor) {
      return '$active assigned site${active == 1 ? '' : 's'} moving today.';
    }
    return '$active active site${active == 1 ? '' : 's'} across your portfolio.';
  }

  String _supporting() {
    if (user.isClient) {
      return 'Review verified progress, site photos, reports and payment activity shared by your project team.';
    }
    if (user.isSupervisor) {
      return '${data.stats.pendingTasks} pending tasks and ${data.stats.todayReports} reports recorded today.';
    }
    return '${data.stats.todayLabours} labour present today • ${data.stats.pendingTasks} tasks awaiting action.';
  }

  String _actionPath() => user.isClient
      ? '/sites'
      : user.isSupervisor
      ? '/reports'
      : '/sites';
  String _actionLabel() => user.isClient
      ? 'Open projects'
      : user.isSupervisor
      ? 'Daily reports'
      : 'Manage sites';
  IconData _actionIcon() => user.isSupervisor
      ? Icons.description_outlined
      : Icons.arrow_forward_rounded;
}

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final actions = DashboardExperience.featuresFor(user.role);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 680) {
          return SizedBox(
            height: 102,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: actions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 9),
              itemBuilder: (context, index) => SizedBox(
                width: 88,
                child: _FeatureTile(feature: actions[index])
                    .animate(delay: (index.clamp(0, 7) * 38).ms)
                    .fadeIn(duration: 200.ms)
                    .slideX(begin: .08, end: 0),
              ),
            ),
          );
        }
        final columns = constraints.maxWidth >= 1100
            ? actions.length
            : constraints.maxWidth >= 860
            ? 6
            : 5;
        const spacing = 9.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: actions.indexed
              .map(
                (entry) => SizedBox(
                  width: width,
                  height: 102,
                  child: _FeatureTile(feature: entry.$2)
                      .animate(delay: (entry.$1.clamp(0, 7) * 38).ms)
                      .fadeIn(duration: 200.ms)
                      .slideY(begin: .08, end: 0),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.feature});

  final DashboardFeatureLink feature;

  @override
  Widget build(BuildContext context) {
    final tone = _featureTone(feature.kind);
    return DashboardSurface(
      onTap: () => context.go(feature.path),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 12),
      radius: 20,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_featureIcon(feature.kind), color: tone, size: 19),
          ),
          const SizedBox(height: 9),
          Text(
            feature.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class DashboardCampaignCarousel extends StatefulWidget {
  const DashboardCampaignCarousel({
    super.key,
    required this.user,
    required this.data,
  });

  final AuthUser user;
  final DashboardData data;

  @override
  State<DashboardCampaignCarousel> createState() =>
      _DashboardCampaignCarouselState();
}

class _DashboardCampaignCarouselState extends State<DashboardCampaignCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _page = 0;

  List<DashboardCampaign> get _campaigns =>
      DashboardExperience.campaignsFor(widget.data, widget.user.role);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _restartTimer();
  }

  @override
  void didUpdateWidget(covariant DashboardCampaignCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.campaigns.length != widget.data.campaigns.length ||
        oldWidget.user.role != widget.user.role) {
      _page = 0;
      if (_controller.hasClients) _controller.jumpToPage(0);
      _restartTimer();
    }
  }

  void _restartTimer() {
    _timer?.cancel();
    if (_campaigns.length < 2 || MediaQuery.disableAnimationsOf(context))
      return;
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!_controller.hasClients || !mounted) return;
      final next = (_page + 1) % _campaigns.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 620),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = _campaigns;
    return Column(
      children: [
        SizedBox(
          height: 216,
          child: PageView.builder(
            key: const ValueKey('dashboard-campaign-carousel'),
            controller: _controller,
            itemCount: campaigns.length,
            onPageChanged: (value) => setState(() => _page = value),
            itemBuilder: (context, index) =>
                _CampaignCard(campaign: campaigns[index]),
          ),
        ),
        if (campaigns.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              campaigns.length,
              (index) => Semantics(
                button: true,
                selected: index == _page,
                label: 'Show dashboard banner ${index + 1}',
                child: GestureDetector(
                  onTap: () => _controller.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                  ),
                  child: AnimatedContainer(
                    key: ValueKey('dashboard-campaign-dot-$index'),
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    width: index == _page ? 24 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: index == _page
                          ? AppTheme.blue
                          : AppTheme.blue.withValues(alpha: .2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: .05, end: 0);
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({required this.campaign});

  final DashboardCampaign campaign;

  @override
  Widget build(BuildContext context) {
    final colors = _campaignGradient(campaign.tone);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260A2D5A),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: const _CampaignBlueprintPainter()),
          ),
          if (campaign.imageUrl != null)
            Positioned.fill(
              left: MediaQuery.sizeOf(context).width < 600 ? 150 : 360,
              child: Opacity(
                opacity: .32,
                child: Image.network(
                  campaign.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(),
                ),
              ),
            ),
          Positioned(
            right: -36,
            top: -48,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: .08),
                  width: 30,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 19),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 480;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            campaign.eyebrow.isEmpty
                                ? 'SITESEVA UPDATE'
                                : campaign.eyebrow,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                          ),
                        ),
                        if (campaign.isPromoted) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .12),
                              ),
                            ),
                            child: Text(
                              'PROMOTED',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Colors.white70,
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: .7,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: compact ? constraints.maxWidth : 650,
                      ),
                      child: Text(
                        campaign.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.12,
                          letterSpacing: -.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: compact ? constraints.maxWidth : 680,
                      ),
                      child: Text(
                        campaign.body,
                        maxLines: compact ? 2 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: .72),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (campaign.actionPath != null)
                      _CampaignAction(
                        label: campaign.actionLabel.isEmpty
                            ? 'Open workspace'
                            : campaign.actionLabel,
                        onTap: () => context.go(campaign.actionPath!),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignAction extends StatelessWidget {
  const _CampaignAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_forward_rounded,
              color: AppTheme.ink,
              size: 15,
            ),
          ],
        ),
      ),
    ),
  );
}

class DashboardInsights extends StatelessWidget {
  const DashboardInsights({
    super.key,
    required this.user,
    required this.data,
    required this.now,
  });

  final AuthUser user;
  final DashboardData data;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final insights = DashboardExperience.insightsFor(data, user.role, now);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: insights.indexed
                  .map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(
                        right: entry.$1 == insights.length - 1 ? 0 : 10,
                      ),
                      child: SizedBox(
                        width: 202,
                        height: 136,
                        child: _InsightCard(insight: entry.$2),
                      ),
                    ),
                  )
                  .toList(),
            ),
          );
        }
        const spacing = 10.0;
        final width = (constraints.maxWidth - spacing * 3) / 4;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: insights
              .map(
                (insight) => SizedBox(
                  width: width,
                  height: 136,
                  child: _InsightCard(insight: insight),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final DashboardInsight insight;

  @override
  Widget build(BuildContext context) {
    final tone = _insightTone(insight.kind);
    return DashboardSurface(
      onTap: () => context.go(insight.path),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_insightIcon(insight.kind), color: tone, size: 17),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_outward_rounded,
                color: AppTheme.muted,
                size: 16,
              ),
            ],
          ),
          const Spacer(),
          Text(
            insight.value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            insight.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            insight.detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.muted,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardProjects extends StatelessWidget {
  const DashboardProjects({super.key, required this.sites, required this.user});

  final List<DashboardSite> sites;
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    if (sites.isEmpty) {
      return DashboardEmptyState(
        icon: Icons.apartment_outlined,
        title: user.isClient ? 'No assigned projects' : 'No sites available',
        message: user.isClient
            ? 'Projects will appear here after the contractor assigns your account.'
            : user.isSupervisor
            ? 'Assigned sites will appear here when your contractor adds you to a project.'
            : 'Create a site to start tracking progress, teams and material movement.',
        actionLabel: user.isContractor ? 'Create site' : null,
        onAction: user.isContractor ? () => context.go('/sites') : null,
      );
    }
    return SizedBox(
      height: 272,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: math.min(sites.length, 8),
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) => SizedBox(
          width: MediaQuery.sizeOf(context).width >= 700 ? 344 : 302,
          child: _ProjectCard(site: sites[index], user: user)
              .animate(delay: (index * 55).ms)
              .fadeIn(duration: 260.ms)
              .slideX(begin: .05, end: 0),
        ),
      ),
    );
  }
}

class DashboardAlerts extends StatelessWidget {
  const DashboardAlerts({super.key, required this.alerts});

  final List<DashboardAlert> alerts;

  @override
  Widget build(BuildContext context) => DashboardSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionTitle(
          title: 'Needs attention',
          subtitle: 'Exceptions reported by the live dashboard',
        ),
        const SizedBox(height: 14),
        if (alerts.isEmpty)
          const _ClearOperationsState()
        else
          ...alerts
              .take(5)
              .indexed
              .map(
                (entry) => Padding(
                  padding: EdgeInsets.only(
                    bottom: entry.$1 == math.min(alerts.length, 5) - 1 ? 0 : 12,
                  ),
                  child: _AlertRow(alert: entry.$2),
                ),
              ),
      ],
    ),
  );
}

class DashboardActivityFeed extends StatelessWidget {
  const DashboardActivityFeed({super.key, required this.activities});

  final List<DashboardActivity> activities;

  @override
  Widget build(BuildContext context) => DashboardSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionTitle(
          title: 'Recent activity',
          subtitle: 'Payments and reports ordered by the API',
        ),
        const SizedBox(height: 14),
        if (activities.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No recent workspace activity.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
              ),
            ),
          )
        else
          ...activities
              .take(6)
              .indexed
              .map(
                (entry) => _ActivityRow(
                  activity: entry.$2,
                  showLine: entry.$1 != math.min(activities.length, 6) - 1,
                ),
              ),
      ],
    ),
  );
}

class DashboardPhotos extends StatelessWidget {
  const DashboardPhotos({super.key, required this.photos});

  final List<DashboardPhoto> photos;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionTitle(
          title: 'Latest site photos',
          subtitle: 'Images attached to submitted daily reports',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 164,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) => _PhotoCard(photo: photos[index]),
          ),
        ),
      ],
    );
  }
}

class DashboardPayments extends StatelessWidget {
  const DashboardPayments({super.key, required this.payments});

  final List<DashboardPayment> payments;

  @override
  Widget build(BuildContext context) => DashboardSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionTitle(
          title: 'Payment activity',
          subtitle: 'Latest entries shared with your project account',
          actionLabel: 'View all',
          onAction: () => context.go('/payments'),
        ),
        const SizedBox(height: 12),
        if (payments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: Text(
                'No payment entries are available.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
              ),
            ),
          )
        else
          ...payments
              .take(5)
              .indexed
              .map(
                (entry) => Padding(
                  padding: EdgeInsets.only(
                    bottom: entry.$1 == math.min(payments.length, 5) - 1
                        ? 0
                        : 10,
                  ),
                  child: _PaymentRow(payment: entry.$2),
                ),
              ),
      ],
    ),
  );
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.site, required this.user});

  final DashboardSite site;
  final AuthUser user;

  @override
  Widget build(BuildContext context) => DashboardSurface(
    padding: EdgeInsets.zero,
    onTap: () => context.go('/sites/${site.id}'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 112,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: _ProjectVisual(site: site),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppTheme.ink.withValues(alpha: .55),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: _StatusPill(status: site.status),
              ),
              Positioned(
                right: 12,
                bottom: 10,
                child: _MiniProgressRing(progress: site.progress),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  site.name.isEmpty ? 'Unnamed site' : site.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.25,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppTheme.muted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        site.location.isEmpty
                            ? 'Location not recorded'
                            : site.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: _ProjectFact(
                        label: user.isSupervisor ? 'SUPERVISOR' : 'BUDGET',
                        value: user.isSupervisor
                            ? (site.supervisorNames.firstOrNull ?? 'Assigned')
                            : site.budget > 0
                            ? formatInr(site.budget)
                            : 'Not recorded',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ProjectFact(
                        label: 'DEADLINE',
                        value: site.endDate == null
                            ? 'Not recorded'
                            : formatShortDate(site.endDate),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _ProjectVisual extends StatelessWidget {
  const _ProjectVisual({required this.site});

  final DashboardSite site;

  @override
  Widget build(BuildContext context) {
    final image = site.coverImage;
    if (image == null) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF152033), Color(0xFF26354A), Color(0xFF71371D)],
          ),
        ),
        child: CustomPaint(painter: _BuildingLinePainter()),
      );
    }
    return Image.network(
      image,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const ColoredBox(
              color: Color(0xFF172132),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.orangeBright,
                ),
              ),
            ),
      errorBuilder: (context, error, stackTrace) => const ColoredBox(
        color: Color(0xFF172132),
        child: Icon(Icons.apartment_rounded, color: AppTheme.orangeBright),
      ),
    );
  }
}

class _MiniProgressRing extends StatelessWidget {
  const _MiniProgressRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppTheme.ink.withValues(alpha: .78),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white.withValues(alpha: .14)),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.square(
          dimension: 38,
          child: CircularProgressIndicator(
            value: progress / 100,
            strokeWidth: 3,
            color: AppTheme.orangeBright,
            backgroundColor: Colors.white.withValues(alpha: .14),
          ),
        ),
        Text(
          '${progress.round()}%',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _PortfolioRing extends StatelessWidget {
  const _PortfolioRing({
    required this.compact,
    required this.value,
    required this.centerValue,
    required this.label,
  });

  final bool compact;
  final double value;
  final String centerValue;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    width: compact ? 96 : 104,
    height: compact ? 112 : 118,
    padding: EdgeInsets.all(compact ? 10 : 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white.withValues(alpha: .1)),
    ),
    child: Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
                color: AppTheme.orangeBright,
                backgroundColor: Colors.white.withValues(alpha: .12),
              ),
              Text(
                centerValue,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFFABB6C5),
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: .65,
          ),
        ),
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final color = normalized == 'COMPLETED'
        ? AppTheme.success
        : normalized == 'ON_HOLD' || normalized == 'DELAYED'
        ? AppTheme.warning
        : AppTheme.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.ink.withValues(alpha: .78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: .65)),
      ),
      child: Text(
        normalized.isEmpty ? 'UNSPECIFIED' : normalized.replaceAll('_', ' '),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: .45,
        ),
      ),
    );
  }
}

class _ProjectFact extends StatelessWidget {
  const _ProjectFact({required this.label, required this.value});

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
          fontWeight: FontWeight.w800,
          letterSpacing: .7,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert});

  final DashboardAlert alert;

  @override
  Widget build(BuildContext context) {
    final severity = alert.severity.toUpperCase();
    final tone = severity == 'HIGH'
        ? AppTheme.danger
        : severity == 'MEDIUM'
        ? AppTheme.warning
        : AppTheme.blue;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: tone.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(_alertIcon(alert.type), color: tone, size: 18),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alert.title,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                '${severity.isEmpty ? 'INFO' : severity} • ${alert.type.replaceAll('_', ' ')}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClearOperationsState extends StatelessWidget {
  const _ClearOperationsState();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.success.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.success.withValues(alpha: .14)),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          color: AppTheme.success,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'No active exceptions were returned by the dashboard.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity, required this.showLine});

  final DashboardActivity activity;
  final bool showLine;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 34,
          child: Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _activityTone(activity.type).withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _activityIcon(activity.type),
                  color: _activityTone(activity.type),
                  size: 15,
                ),
              ),
              if (showLine)
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppTheme.line,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title.isEmpty
                      ? activity.type.replaceAll('_', ' ')
                      : activity.title.replaceAll('_', ' '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  activity.description.isEmpty
                      ? formatRelativeTime(activity.createdAt)
                      : '${activity.description} • ${formatRelativeTime(activity.createdAt)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.muted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.photo});

  final DashboardPhoto photo;

  @override
  Widget build(BuildContext context) => Container(
    width: 210,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      color: AppTheme.ink,
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          photo.thumbnail.isEmpty ? photo.url : photo.thumbnail,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image_outlined, color: Colors.white54),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xE20A0E17)],
            ),
          ),
        ),
        Positioned(
          left: 13,
          right: 13,
          bottom: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                photo.siteName.isEmpty ? 'Site update' : photo.siteName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                photo.caption.isEmpty
                    ? formatRelativeTime(photo.createdAt)
                    : photo.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFC3CDD9),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});

  final DashboardPayment payment;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.currency_rupee_rounded,
          color: AppTheme.success,
          size: 18,
        ),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              payment.description.isEmpty
                  ? payment.type.replaceAll('_', ' ')
                  : payment.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              [
                payment.party,
                formatRelativeTime(payment.createdAt),
              ].where((value) => value.isNotEmpty).join(' • '),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
      Text(
        formatInr(payment.amount),
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
    ],
  );
}

IconData _featureIcon(DashboardFeatureKind kind) => switch (kind) {
  DashboardFeatureKind.sites => Icons.apartment_outlined,
  DashboardFeatureKind.attendance => Icons.how_to_reg_outlined,
  DashboardFeatureKind.labour => Icons.groups_outlined,
  DashboardFeatureKind.stock => Icons.inventory_2_outlined,
  DashboardFeatureKind.payments => Icons.payments_outlined,
  DashboardFeatureKind.expenses => Icons.receipt_long_outlined,
  DashboardFeatureKind.estimates => Icons.calculate_outlined,
  DashboardFeatureKind.boq => Icons.format_list_numbered_rounded,
  DashboardFeatureKind.design => Icons.auto_awesome_outlined,
  DashboardFeatureKind.reports => Icons.description_outlined,
  DashboardFeatureKind.crm => Icons.handshake_outlined,
  DashboardFeatureKind.documents => Icons.folder_copy_outlined,
  DashboardFeatureKind.notifications => Icons.notifications_none_rounded,
  DashboardFeatureKind.support => Icons.support_agent_rounded,
};

Color _featureTone(DashboardFeatureKind kind) => switch (kind) {
  DashboardFeatureKind.sites ||
  DashboardFeatureKind.attendance => AppTheme.orange,
  DashboardFeatureKind.labour || DashboardFeatureKind.stock => AppTheme.success,
  DashboardFeatureKind.payments ||
  DashboardFeatureKind.expenses => const Color(0xFF0EA5A8),
  DashboardFeatureKind.estimates || DashboardFeatureKind.boq => AppTheme.blue,
  DashboardFeatureKind.design => const Color(0xFF7C5CE7),
  DashboardFeatureKind.reports => const Color(0xFF0F7AC0),
  DashboardFeatureKind.crm => const Color(0xFF7C5CE7),
  DashboardFeatureKind.documents => AppTheme.blue,
  DashboardFeatureKind.notifications => AppTheme.warning,
  DashboardFeatureKind.support => AppTheme.muted,
};

IconData _insightIcon(DashboardInsightKind kind) => switch (kind) {
  DashboardInsightKind.progress => Icons.donut_large_rounded,
  DashboardInsightKind.deadline => Icons.event_busy_outlined,
  DashboardInsightKind.activity => Icons.bolt_rounded,
  DashboardInsightKind.field => Icons.engineering_outlined,
  DashboardInsightKind.payments => Icons.account_balance_wallet_outlined,
};

Color _insightTone(DashboardInsightKind kind) => switch (kind) {
  DashboardInsightKind.progress => AppTheme.blue,
  DashboardInsightKind.deadline => AppTheme.orange,
  DashboardInsightKind.activity => const Color(0xFF7C5CE7),
  DashboardInsightKind.field => AppTheme.success,
  DashboardInsightKind.payments => const Color(0xFF0EA5A8),
};

List<Color> _campaignGradient(String tone) => switch (tone.toUpperCase()) {
  'ORANGE' => const [Color(0xFF07101D), Color(0xFF16304D), Color(0xFFB94E16)],
  'SLATE' => const [Color(0xFF070C15), Color(0xFF172235), Color(0xFF3B4C66)],
  'GREEN' => const [Color(0xFF06151A), Color(0xFF0D3B46), Color(0xFF0E7665)],
  _ => const [Color(0xFF060D18), Color(0xFF0B2D58), Color(0xFF0F64C8)],
};

IconData _alertIcon(String type) => switch (type.toUpperCase()) {
  'TASK' => Icons.task_alt_rounded,
  'PAYMENT' => Icons.payments_outlined,
  'MATERIAL' => Icons.inventory_2_outlined,
  'TEAM' => Icons.groups_outlined,
  _ => Icons.priority_high_rounded,
};

IconData _activityIcon(String type) => switch (type.toUpperCase()) {
  'PAYMENT' => Icons.currency_rupee_rounded,
  'REPORT' => Icons.description_outlined,
  'ATTENDANCE' => Icons.how_to_reg_outlined,
  'MATERIAL' => Icons.inventory_2_outlined,
  _ => Icons.bolt_rounded,
};

Color _activityTone(String type) => switch (type.toUpperCase()) {
  'PAYMENT' => AppTheme.success,
  'REPORT' => AppTheme.blue,
  'ATTENDANCE' => AppTheme.orange,
  'MATERIAL' => Color(0xFF7C5CE7),
  _ => AppTheme.muted,
};

class _HeroGridPainter extends CustomPainter {
  const _HeroGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .035)
      ..strokeWidth = 1;
    const step = 30.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CampaignBlueprintPainter extends CustomPainter {
  const _CampaignBlueprintPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .035)
      ..strokeWidth = 1;
    const step = 32.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final line = Paint()
      ..color = Colors.white.withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final right = size.width;
    final path = Path()
      ..moveTo(right * .72, size.height * .78)
      ..lineTo(right * .72, size.height * .31)
      ..lineTo(right * .82, size.height * .16)
      ..lineTo(right * .92, size.height * .31)
      ..lineTo(right * .92, size.height * .78)
      ..moveTo(right * .77, size.height * .78)
      ..lineTo(right * .77, size.height * .49)
      ..lineTo(right * .87, size.height * .49)
      ..lineTo(right * .87, size.height * .78);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BuildingLinePainter extends CustomPainter {
  const _BuildingLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..moveTo(size.width * .1, size.height * .86)
      ..lineTo(size.width * .1, size.height * .36)
      ..lineTo(size.width * .38, size.height * .16)
      ..lineTo(size.width * .66, size.height * .34)
      ..lineTo(size.width * .66, size.height * .86)
      ..moveTo(size.width * .66, size.height * .5)
      ..lineTo(size.width * .9, size.height * .39)
      ..lineTo(size.width * .9, size.height * .86)
      ..moveTo(size.width * .25, size.height * .86)
      ..lineTo(size.width * .25, size.height * .52)
      ..lineTo(size.width * .48, size.height * .52)
      ..lineTo(size.width * .48, size.height * .86);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
