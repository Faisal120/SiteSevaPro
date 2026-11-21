import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/crm_models.dart';

class CrmHeroCard extends StatelessWidget {
  const CrmHeroCard({
    super.key,
    required this.role,
    required this.data,
    required this.canWrite,
    required this.onCreate,
  });

  final String role;
  final CrmWorkspaceData data;
  final bool canWrite;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final label = role.toUpperCase() == 'CLIENT'
        ? 'CLIENT RELATIONSHIP VIEW'
        : role.toUpperCase() == 'SUPERVISOR'
        ? 'FIELD RELATIONSHIP VIEW'
        : 'RELATIONSHIP COMMAND CENTER';
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 19),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF070E1A), Color(0xFF0C2E59), Color(0xFF1467C9)],
        ),
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
          Positioned(
            right: -42,
            top: -58,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Relationships that move projects forward.',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.7,
                  height: 1.13,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                data.apiAvailable
                    ? 'Keep leads, stakeholders, follow-ups and quotations connected to the project record.'
                    : 'The CRM workspace is ready, but the connected FastAPI service has not enabled CRM endpoints yet.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: .72),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              if (canWrite && data.apiAvailable)
                _CrmHeroAction(onTap: onCreate, label: 'Create record')
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .12),
                    ),
                  ),
                  child: Text(
                    data.apiAvailable ? 'Read-only workspace' : 'Awaiting CRM API',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CrmHeroAction extends StatelessWidget {
  const _CrmHeroAction({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

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
            const Icon(Icons.add_rounded, color: AppTheme.ink, size: 16),
          ],
        ),
      ),
    ),
  );
}

class CrmWorkspaceTabs extends StatelessWidget {
  const CrmWorkspaceTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final CrmWorkspace selected;
  final ValueChanged<CrmWorkspace> onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    clipBehavior: Clip.none,
    child: Row(
      children: CrmWorkspace.values
          .map(
            (workspace) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: selected == workspace,
                onSelected: (_) => onChanged(workspace),
                avatar: Icon(_workspaceIcon(workspace), size: 16),
                label: Text(workspace.label),
              ),
            ),
          )
          .toList(growable: false),
    ),
  );
}

class CrmMetricStrip extends StatelessWidget {
  const CrmMetricStrip({super.key, required this.metrics});

  final CrmMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final items = [
      _CrmMetric('Leads', '${metrics.leads}', Icons.filter_alt_outlined, AppTheme.blue),
      _CrmMetric(
        'Clients',
        '${metrics.activeClients}',
        Icons.business_outlined,
        AppTheme.success,
      ),
      _CrmMetric(
        'Follow-ups',
        '${metrics.openFollowUps}',
        Icons.schedule_outlined,
        AppTheme.orange,
      ),
      _CrmMetric(
        'Pipeline',
        formatCrmCurrency(metrics.pipelineValue),
        Icons.account_tree_outlined,
        const Color(0xFF7C5CE7),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) => SizedBox(
                width: 154,
                child: _CrmMetricCard(metric: items[index]),
              ),
            ),
          );
        }
        const spacing = 10.0;
        return Row(
          children: items
              .map(
                (metric) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: metric == items.last ? 0 : spacing,
                    ),
                    child: _CrmMetricCard(metric: metric),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _CrmMetric {
  const _CrmMetric(this.label, this.value, this.icon, this.tone);

  final String label;
  final String value;
  final IconData icon;
  final Color tone;
}

class _CrmMetricCard extends StatelessWidget {
  const _CrmMetricCard({required this.metric});

  final _CrmMetric metric;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.all(13),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: metric.tone.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(metric.icon, color: metric.tone, size: 17),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                metric.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                metric.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class CrmApiNotice extends StatelessWidget {
  const CrmApiNotice({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: AppTheme.warning.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppTheme.warning.withValues(alpha: .2)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.api_outlined, color: AppTheme.warning, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CRM service not connected',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 7),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppTheme.warning,
                ),
                child: const Text('Retry connection'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class CrmOfflineBanner extends StatelessWidget {
  const CrmOfflineBanner({super.key, required this.cachedAt});

  final DateTime cachedAt;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: AppTheme.orange.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.orange.withValues(alpha: .18)),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: AppTheme.orange, size: 18),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            'Offline snapshot • Last synced ${formatCrmDate(cachedAt)}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.orange,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class CrmRecordCard extends StatelessWidget {
  const CrmRecordCard({super.key, required this.record, this.onComplete});

  final Object record;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) => switch (record) {
    CrmLead lead => _LeadCard(lead: lead),
    CrmContact contact => _ContactCard(contact: contact),
    CrmActivity activity => _ActivityCard(
      activity: activity,
      onComplete: onComplete,
    ),
    CrmQuotation quotation => _QuotationCard(quotation: quotation),
    _ => const SizedBox.shrink(),
  };
}

class _LeadCard extends StatelessWidget {
  const _LeadCard({required this.lead});
  final CrmLead lead;

  @override
  Widget build(BuildContext context) => _CrmRecordSurface(
    icon: Icons.filter_alt_outlined,
    tone: AppTheme.blue,
    title: lead.name.isEmpty ? 'Unnamed lead' : lead.name,
    subtitle: [lead.company, lead.email].where((value) => value.isNotEmpty).join(' • '),
    trailing: CrmStatusPill(label: lead.stage.label, tone: _stageTone(lead.stage)),
    footer: [
      if (lead.value > 0) formatCrmCurrency(lead.value),
      if (lead.source.isNotEmpty) lead.source,
      if (lead.nextFollowUp != null) 'Next ${formatCrmDate(lead.nextFollowUp!)}',
    ],
  );
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact});
  final CrmContact contact;

  @override
  Widget build(BuildContext context) => _CrmRecordSurface(
    icon: contact.kind == CrmContactKind.vendor
        ? Icons.storefront_outlined
        : Icons.business_outlined,
    tone: contact.kind == CrmContactKind.vendor
        ? AppTheme.orange
        : AppTheme.success,
    title: contact.name.isEmpty ? 'Unnamed contact' : contact.name,
    subtitle: [contact.company, contact.city]
        .where((value) => value.isNotEmpty)
        .join(' • '),
    trailing: CrmStatusPill(
      label: contact.kind.label,
      tone: contact.kind == CrmContactKind.vendor
          ? AppTheme.orange
          : AppTheme.success,
    ),
    footer: [
      if (contact.phone.isNotEmpty) contact.phone,
      if (contact.email.isNotEmpty) contact.email,
      if (contact.gstin.isNotEmpty) 'GST ${contact.gstin}',
    ],
  );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity, required this.onComplete});
  final CrmActivity activity;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) => _CrmRecordSurface(
    icon: _activityIcon(activity.kind),
    tone: AppTheme.orange,
    title: activity.title.isEmpty ? activity.kind.label : activity.title,
    subtitle: [activity.contactName, activity.description]
        .where((value) => value.isNotEmpty)
        .join(' • '),
    trailing: CrmStatusPill(
      label: activity.status.isEmpty ? 'Open' : activity.status,
      tone: activity.status.toUpperCase() == 'COMPLETED'
          ? AppTheme.success
          : AppTheme.orange,
    ),
    footer: [
      activity.kind.label,
      if (activity.scheduledAt != null) formatCrmDate(activity.scheduledAt!),
    ],
    action: onComplete == null || activity.status.toUpperCase() == 'COMPLETED'
        ? null
        : TextButton(
            onPressed: onComplete,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Complete'),
          ),
  );
}

class _QuotationCard extends StatelessWidget {
  const _QuotationCard({required this.quotation});
  final CrmQuotation quotation;

  @override
  Widget build(BuildContext context) => _CrmRecordSurface(
    icon: Icons.request_quote_outlined,
    tone: const Color(0xFF7C5CE7),
    title: quotation.title.isEmpty ? quotation.number : quotation.title,
    subtitle: [quotation.number, quotation.contactName]
        .where((value) => value.isNotEmpty)
        .join(' • '),
    trailing: CrmStatusPill(
      label: quotation.status.isEmpty ? 'Draft' : quotation.status,
      tone: _quotationTone(quotation.status),
    ),
    footer: [
      if (quotation.amount > 0) formatCrmCurrency(quotation.amount),
      if (quotation.validUntil != null)
        'Valid till ${formatCrmDate(quotation.validUntil!)}',
    ],
  );
}

class _CrmRecordSurface extends StatelessWidget {
  const _CrmRecordSurface({
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.footer,
    this.action,
  });

  final IconData icon;
  final Color tone;
  final String title;
  final String subtitle;
  final Widget trailing;
  final List<String> footer;
  final Widget? action;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.all(15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: tone, size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.muted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
        if (footer.isNotEmpty || action != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: footer
                      .map(
                        (value) => Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppTheme.muted,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      )
                      .toList(),
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: 10),
                action!,
              ],
            ],
          ),
        ],
      ],
    ),
  );
}

class CrmStatusPill extends StatelessWidget {
  const CrmStatusPill({super.key, required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 105),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: tone.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label.toUpperCase().replaceAll('_', ' '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: tone,
        fontSize: 8,
        fontWeight: FontWeight.w800,
        letterSpacing: .35,
      ),
    ),
  );
}

class CrmEmptyState extends StatelessWidget {
  const CrmEmptyState({
    super.key,
    required this.workspace,
    required this.apiAvailable,
    required this.canWrite,
    required this.onCreate,
  });

  final CrmWorkspace workspace;
  final bool apiAvailable;
  final bool canWrite;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => DashboardLikeEmpty(
    icon: apiAvailable ? _workspaceIcon(workspace) : Icons.api_outlined,
    title: apiAvailable
        ? 'No ${workspace.label.toLowerCase()} records yet'
        : 'CRM records will appear here',
    message: apiAvailable
        ? canWrite
              ? 'Create the first ${workspace.label.toLowerCase()} record to begin your relationship pipeline.'
              : 'Records shared with your role will appear here once the CRM service is connected.'
        : 'Connect the CRM FastAPI module to load real leads, contacts, follow-ups and quotations.',
    actionLabel: apiAvailable && canWrite ? 'Create record' : null,
    onAction: apiAvailable && canWrite ? onCreate : null,
  );
}

class DashboardLikeEmpty extends StatelessWidget {
  const DashboardLikeEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
    child: Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.blue.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: AppTheme.blue),
        ),
        const SizedBox(height: 13),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.muted,
            height: 1.45,
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 14),
          FilledButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    ),
  );
}

IconData _workspaceIcon(CrmWorkspace workspace) => switch (workspace) {
  CrmWorkspace.leads => Icons.filter_alt_outlined,
  CrmWorkspace.clients => Icons.business_outlined,
  CrmWorkspace.vendors => Icons.storefront_outlined,
  CrmWorkspace.activities => Icons.schedule_outlined,
  CrmWorkspace.quotations => Icons.request_quote_outlined,
};

IconData _activityIcon(CrmActivityKind kind) => switch (kind) {
  CrmActivityKind.meeting => Icons.event_outlined,
  CrmActivityKind.call => Icons.call_outlined,
  CrmActivityKind.followUp => Icons.notifications_active_outlined,
  CrmActivityKind.note => Icons.sticky_note_2_outlined,
  CrmActivityKind.unknown => Icons.bolt_outlined,
};

Color _stageTone(CrmLeadStage stage) => switch (stage) {
  CrmLeadStage.won => AppTheme.success,
  CrmLeadStage.lost => AppTheme.danger,
  CrmLeadStage.proposal || CrmLeadStage.negotiation => AppTheme.orange,
  CrmLeadStage.qualified => AppTheme.blue,
  CrmLeadStage.newLead || CrmLeadStage.unknown => AppTheme.muted,
};

Color _quotationTone(String status) {
  final value = status.toUpperCase();
  if (value == 'ACCEPTED' || value == 'WON') return AppTheme.success;
  if (value == 'REJECTED' || value == 'EXPIRED') return AppTheme.danger;
  if (value == 'SENT' || value == 'SUBMITTED') return AppTheme.blue;
  return const Color(0xFF7C5CE7);
}

String formatCrmCurrency(num value) {
  if (value.abs() >= 10000000) return '₹${(value / 10000000).toStringAsFixed(1)}Cr';
  if (value.abs() >= 100000) return '₹${(value / 100000).toStringAsFixed(1)}L';
  if (value.abs() >= 1000) return '₹${(value / 1000).toStringAsFixed(1)}K';
  return '₹${value.round()}';
}

String formatCrmDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')} ${_months[value.month - 1]} ${value.year}';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
