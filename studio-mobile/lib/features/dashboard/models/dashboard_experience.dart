import 'dashboard_data.dart';

enum DashboardFeatureKind {
  sites,
  attendance,
  labour,
  stock,
  payments,
  expenses,
  estimates,
  boq,
  design,
  reports,
  crm,
  documents,
  notifications,
  support,
}

class DashboardFeatureLink {
  const DashboardFeatureLink({
    required this.kind,
    required this.label,
    required this.path,
  });

  final DashboardFeatureKind kind;
  final String label;
  final String path;
}

enum DashboardInsightKind { progress, deadline, activity, field, payments }

class DashboardInsight {
  const DashboardInsight({
    required this.kind,
    required this.label,
    required this.value,
    required this.detail,
    required this.path,
  });

  final DashboardInsightKind kind;
  final String label;
  final String value;
  final String detail;
  final String path;
}

class DashboardExperience {
  const DashboardExperience._();

  static List<DashboardFeatureLink> featuresFor(String role) {
    return switch (role.toUpperCase()) {
      'CLIENT' => const [
        DashboardFeatureLink(
          kind: DashboardFeatureKind.sites,
          label: 'Projects',
          path: '/sites',
        ),
        DashboardFeatureLink(
          kind: DashboardFeatureKind.payments,
          label: 'Payments',
          path: '/payments',
        ),
        DashboardFeatureLink(
          kind: DashboardFeatureKind.reports,
          label: 'Reports',
          path: '/reports',
        ),
        DashboardFeatureLink(
          kind: DashboardFeatureKind.design,
          label: 'Designs',
          path: '/design-studio',
        ),
        DashboardFeatureLink(
          kind: DashboardFeatureKind.crm,
          label: 'Contacts',
          path: '/crm',
        ),
        DashboardFeatureLink(
          kind: DashboardFeatureKind.documents,
          label: 'Files',
          path: '/documents',
        ),
        DashboardFeatureLink(
          kind: DashboardFeatureKind.notifications,
          label: 'Alerts',
          path: '/notifications',
        ),
        DashboardFeatureLink(
          kind: DashboardFeatureKind.support,
          label: 'Support',
          path: '/help',
        ),
      ],
      'SUPERVISOR' => const [
        DashboardFeatureLink(
          kind: DashboardFeatureKind.sites,
          label: 'My sites',
          path: '/sites',
        ),
        DashboardFeatureLink(
          kind: DashboardFeatureKind.attendance,
          label: 'Attendance',
          path: '/attendance',
        ),
        DashboardFeatureLink(
          kind: DashboardFeatureKind.labour,
          label: 'Workforce',
          path: '/labour',
        ),
        DashboardFeatureLink(
          kind: DashboardFeatureKind.stock,
          label: 'Materials',
          path: '/materials',
        ),
        DashboardFeatureLink(
          kind: DashboardFeatureKind.reports,
          label: 'Daily report',
          path: '/reports',
        ),
        DashboardFeatureLink(
          kind: DashboardFeatureKind.crm,
          label: 'CRM',
          path: '/crm',
        ),
        DashboardFeatureLink(
          kind: DashboardFeatureKind.documents,
          label: 'Files',
          path: '/documents',
        ),
        DashboardFeatureLink(
          kind: DashboardFeatureKind.notifications,
          label: 'Alerts',
          path: '/notifications',
        ),
      ],
      _ => const [
        DashboardFeatureLink(
          kind: DashboardFeatureKind.sites,
          label: 'Sites',
          path: '/sites',
        ),
        DashboardFeatureLink(
          kind: DashboardFeatureKind.attendance,
          label: 'Attendance',
          path: '/attendance',
        ),
        DashboardFeatureLink(
          kind: DashboardFeatureKind.labour,
          label: 'Labour',
          path: '/labour',
        ),
        DashboardFeatureLink(
          kind: DashboardFeatureKind.stock,
          label: 'Stock',
          path: '/materials',
        ),
        DashboardFeatureLink(
          kind: DashboardFeatureKind.payments,
          label: 'Payments',
          path: '/payments',
        ),
        DashboardFeatureLink(
          kind: DashboardFeatureKind.expenses,
          label: 'Expenses',
          path: '/expenses',
        ),
        DashboardFeatureLink(
          kind: DashboardFeatureKind.estimates,
          label: 'Estimates',
          path: '/estimates',
        ),
        DashboardFeatureLink(
          kind: DashboardFeatureKind.boq,
          label: 'BOQ',
          path: '/boq',
        ),
        DashboardFeatureLink(
          kind: DashboardFeatureKind.design,
          label: 'AI Studio',
          path: '/design-studio',
        ),
        DashboardFeatureLink(
          kind: DashboardFeatureKind.crm,
          label: 'CRM',
          path: '/crm',
        ),
        DashboardFeatureLink(
          kind: DashboardFeatureKind.documents,
          label: 'Documents',
          path: '/documents',
        ),
        DashboardFeatureLink(
          kind: DashboardFeatureKind.reports,
          label: 'Reports',
          path: '/reports',
        ),
      ],
    };
  }

  static List<DashboardCampaign> campaignsFor(DashboardData data, String role) {
    final apiCampaigns = data.campaigns
        .where((campaign) => campaign.supportsRole(role))
        .where((campaign) => campaign.title.isNotEmpty)
        .toList(growable: false);
    if (apiCampaigns.isNotEmpty) return apiCampaigns;

    final active = data.stats.activeSites;
    final total = data.stats.totalSites;
    final portfolioTitle = total == 0
        ? role.toUpperCase() == 'CLIENT'
              ? 'Your project workspace is ready for assignment.'
              : 'Launch your first connected project workspace.'
        : '$active of $total project${total == 1 ? '' : 's'} are active.';
    final portfolioBody = role.toUpperCase() == 'CLIENT'
        ? 'Review verified progress, reports, photos and payments shared by your project team.'
        : '${data.stats.pendingTasks} open tasks and ${data.stats.todayReports} reports are in the current operations snapshot.';

    final portfolio = DashboardCampaign(
      id: 'live-portfolio',
      eyebrow: 'LIVE PORTFOLIO',
      title: portfolioTitle,
      body: portfolioBody,
      actionLabel: role.toUpperCase() == 'CLIENT'
          ? 'View projects'
          : 'Open sites',
      actionPath: '/sites',
      tone: 'BLUE',
      roles: const [],
    );

    return switch (role.toUpperCase()) {
      'SUPERVISOR' => [
        portfolio,
        const DashboardCampaign(
          id: 'field-report-spotlight',
          eyebrow: 'SITESEVA FEATURE',
          title: 'Close the day with a verified field report.',
          body:
              'Capture progress, blockers, labour and site evidence in one field workflow.',
          actionLabel: 'Create report',
          actionPath: '/reports',
          tone: 'ORANGE',
          roles: ['SUPERVISOR'],
          isPromoted: true,
        ),
        const DashboardCampaign(
          id: 'field-control-spotlight',
          eyebrow: 'FIELD CONTROL',
          title: 'Attendance and materials, ready for site hours.',
          body:
              'Move between workforce presence and material movement without losing project context.',
          actionLabel: 'Open attendance',
          actionPath: '/attendance',
          tone: 'SLATE',
          roles: ['SUPERVISOR'],
          isPromoted: true,
        ),
      ],
      'CLIENT' => [
        portfolio,
        const DashboardCampaign(
          id: 'client-visibility-spotlight',
          eyebrow: 'SITESEVA FEATURE',
          title: 'One verified view of every project milestone.',
          body:
              'Follow progress reports and site evidence without operational noise.',
          actionLabel: 'Review reports',
          actionPath: '/reports',
          tone: 'SLATE',
          roles: ['CLIENT'],
          isPromoted: true,
        ),
        const DashboardCampaign(
          id: 'client-design-spotlight',
          eyebrow: 'DESIGN REVIEW',
          title: 'Explore project designs in the AI Studio.',
          body:
              'Open shared plans and design outputs from the same secure project workspace.',
          actionLabel: 'Open designs',
          actionPath: '/design-studio',
          tone: 'BLUE',
          roles: ['CLIENT'],
          isPromoted: true,
        ),
      ],
      _ => [
        portfolio,
        const DashboardCampaign(
          id: 'ai-studio-spotlight',
          eyebrow: 'SITESEVA AI',
          title: 'Move from plot brief to a buildable design workflow.',
          body:
              'Generate floor plans, technical layers and production exports inside AI Studio.',
          actionLabel: 'Launch AI Studio',
          actionPath: '/design-studio',
          tone: 'ORANGE',
          roles: ['CONTRACTOR'],
          isPromoted: true,
        ),
        const DashboardCampaign(
          id: 'costing-spotlight',
          eyebrow: 'COST CONTROL',
          title: 'Turn estimates into controlled BOQ decisions.',
          body:
              'Keep quantities, rates, GST and revisions connected to the project record.',
          actionLabel: 'Open estimates',
          actionPath: '/estimates',
          tone: 'SLATE',
          roles: ['CONTRACTOR'],
          isPromoted: true,
        ),
      ],
    };
  }

  static List<DashboardInsight> insightsFor(
    DashboardData data,
    String role,
    DateTime now,
  ) {
    final average = data.averageSiteProgress.round();
    final deadlines = data.deadlineWatch(now);
    final normalized = role.toUpperCase();
    final fieldValue = normalized == 'SUPERVISOR'
        ? data.todayPresent
        : data.stats.todayLabours;
    final fieldLabel = normalized == 'SUPERVISOR'
        ? 'Present today'
        : 'Labour today';
    final fieldDetail = normalized == 'CLIENT'
        ? '${data.photos.length} site photos loaded'
        : '${data.stats.pendingTasks} tasks pending';

    return [
      DashboardInsight(
        kind: DashboardInsightKind.progress,
        label: 'Portfolio progress',
        value: '$average%',
        detail: '${data.sites.length} project records',
        path: '/sites',
      ),
      DashboardInsight(
        kind: DashboardInsightKind.deadline,
        label: 'Deadline watch',
        value: '$deadlines',
        detail: 'Due in 30 days, delayed or on hold',
        path: '/sites',
      ),
      if (normalized == 'CLIENT')
        DashboardInsight(
          kind: DashboardInsightKind.payments,
          label: 'Payment records',
          value: '${data.payments.length}',
          detail: '${data.activities.length} recent updates loaded',
          path: '/payments',
        )
      else
        DashboardInsight(
          kind: DashboardInsightKind.field,
          label: fieldLabel,
          value: '$fieldValue',
          detail: fieldDetail,
          path: '/attendance',
        ),
      DashboardInsight(
        kind: DashboardInsightKind.activity,
        label: 'Recent records',
        value: '${data.activities.length}',
        detail: '${data.alerts.length} exceptions in view',
        path: '/notifications',
      ),
    ];
  }
}
