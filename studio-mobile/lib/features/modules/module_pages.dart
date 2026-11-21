import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_service.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_ui.dart';

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({required this.error, required this.retry});
  final Object error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      EmptyPanel(
        title: 'Workspace unavailable',
        message: '$error',
        icon: Icons.cloud_off_rounded,
        actionLabel: 'Reconnect',
        onAction: retry,
      ),
    ],
  );
}

class DataListPage extends StatefulWidget {
  const DataListPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.loader,
    required this.icon,
    required this.emptyTitle,
    required this.emptyMessage,
    this.addLabel,
    this.formType,
  });
  final String title;
  final String subtitle;
  final Future<List<Map<String, dynamic>>> Function() loader;
  final IconData icon;
  final String emptyTitle;
  final String emptyMessage;
  final String? addLabel;
  final RecordType? formType;
  @override
  State<DataListPage> createState() => _DataListPageState();
}

class _DataListPageState extends State<DataListPage> {
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() {
    super.initState();
    future = widget.loader();
  }

  void refresh() => setState(() => future = widget.loader());
  @override
  Widget build(BuildContext context) => AppPage(
    title: widget.title,
    subtitle: widget.subtitle,
    actions: [
      IconButton(onPressed: refresh, icon: const Icon(Icons.refresh_rounded)),
    ],
    child: FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return ListView(
            padding: const EdgeInsets.all(20),
            children: const [
              AppSkeleton(height: 92),
              SizedBox(height: 12),
              AppSkeleton(height: 92),
              SizedBox(height: 12),
              AppSkeleton(height: 92),
            ],
          );
        if (snapshot.hasError)
          return _ErrorContent(error: snapshot.error!, retry: refresh);
        final items = snapshot.data ?? const [];
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
          children: [
            if (widget.addLabel != null) ...[
              FilledButton.icon(
                onPressed: () => _openForm(context),
                icon: const Icon(Icons.add_rounded),
                label: Text(widget.addLabel!),
              ),
              const SizedBox(height: 18),
            ],
            if (items.isEmpty)
              EmptyPanel(
                title: widget.emptyTitle,
                message: widget.emptyMessage,
                icon: widget.icon,
                actionLabel: widget.addLabel,
                onAction: () => _openForm(context),
              )
            else
              ...items.indexed.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RecordCard(item: entry.$2, icon: widget.icon)
                      .animate(delay: (entry.$1 * 45).ms)
                      .fadeIn(duration: 200.ms)
                      .slideY(begin: .06, end: 0),
                ),
              ),
          ],
        );
      },
    ),
  );

  Future<void> _openForm(BuildContext context) async {
    if (widget.formType == null) return;
    final added = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RecordForm(type: widget.formType!),
    );
    if (added == true) refresh();
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.item, required this.icon});
  final Map<String, dynamic> item;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final title =
        '${item['name'] ?? item['full_name'] ?? item['project_name'] ?? item['description'] ?? item['title'] ?? item['id'] ?? 'Record'}';
    final subtitle =
        '${item['location'] ?? item['trade'] ?? item['party'] ?? item['status'] ?? item['message'] ?? item['date'] ?? 'Updated in your workspace'}';
    final badge = item['status'] ?? item['type'];
    return SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.blue.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle.replaceAll('_', ' '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                ),
              ],
            ),
          ),
          if (badge != null) StatusBadge(label: '$badge'),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
        ],
      ),
    );
  }
}

enum RecordType { labour, payment, design }

class RecordForm extends StatefulWidget {
  const RecordForm({super.key, required this.type});
  final RecordType type;
  @override
  State<RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends State<RecordForm> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final secondary = TextEditingController();
  final amount = TextEditingController();
  final note = TextEditingController();
  String? siteId;
  String selection = '';
  bool busy = false;
  late Future<List<Map<String, dynamic>>> sites;
  @override
  void initState() {
    super.initState();
    sites = ApiService.getSites();
  }

  @override
  void dispose() {
    name.dispose();
    secondary.dispose();
    amount.dispose();
    note.dispose();
    super.dispose();
  }

  String get title => switch (widget.type) {
    RecordType.labour => 'Add workforce member',
    RecordType.payment => 'Record payment',
    RecordType.design => 'Start AI design',
  };
  String get primaryLabel => switch (widget.type) {
    RecordType.labour => 'Full name',
    RecordType.payment => 'Description',
    RecordType.design => 'Project name',
  };
  String get secondaryLabel => switch (widget.type) {
    RecordType.labour => 'Trade (Mason, Painter...)',
    RecordType.payment => 'Party / client / vendor',
    RecordType.design => 'Facing (North, East...)',
  };

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SurfaceCard(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Saved directly to your SiteSeva workspace.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.muted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: sites,
                  builder: (context, snapshot) {
                    final values = snapshot.data ?? const [];
                    return DropdownButtonFormField<String>(
                      initialValue: siteId,
                      decoration: const InputDecoration(labelText: 'Site'),
                      items: values
                          .map(
                            (site) => DropdownMenuItem(
                              value: '${site['id']}',
                              child: Text('${site['name'] ?? 'Unnamed site'}'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => siteId = value),
                      validator: (value) =>
                          value == null ? 'Choose a site' : null,
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: name,
                  decoration: InputDecoration(labelText: primaryLabel),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'This field is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: secondary,
                  decoration: InputDecoration(labelText: secondaryLabel),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'This field is required'
                      : null,
                ),
                const SizedBox(height: 12),
                if (widget.type == RecordType.payment) ...[
                  DropdownButtonFormField<String>(
                    initialValue: selection.isEmpty ? null : selection,
                    decoration: const InputDecoration(
                      labelText: 'Payment type',
                    ),
                    items:
                        const [
                              'CLIENT_RECEIVED',
                              'EXPENSE',
                              'LABOUR',
                              'MATERIAL',
                            ]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value.replaceAll('_', ' ')),
                              ),
                            )
                            .toList(),
                    onChanged: (value) =>
                        setState(() => selection = value ?? ''),
                    validator: (value) =>
                        value == null ? 'Choose a type' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (INR)',
                    ),
                    validator: (value) => double.tryParse(value ?? '') == null
                        ? 'Enter a number'
                        : null,
                  ),
                ] else if (widget.type == RecordType.design)
                  DropdownButtonFormField<String>(
                    initialValue: selection.isEmpty ? null : selection,
                    decoration: const InputDecoration(labelText: 'Design type'),
                    items: const ['FLOOR_PLAN', 'ELEVATION', '3D_CONCEPT']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.replaceAll('_', ' ')),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selection = value ?? ''),
                    validator: (value) =>
                        value == null ? 'Choose a type' : null,
                  )
                else
                  TextFormField(
                    controller: amount,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Daily wage (INR)'),
                    validator: (value) => double.tryParse(value ?? '') == null
                        ? 'Enter a number'
                        : null,
                  ),
                const SizedBox(height: 12),
                if (widget.type == RecordType.payment)
                  TextFormField(
                    controller: note,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                    ),
                  ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: busy ? null : _submit,
                  icon: busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_rounded),
                  label: Text(
                    busy
                        ? 'Saving...'
                        : widget.type == RecordType.design
                        ? 'Generate design'
                        : 'Save record',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => busy = true);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    try {
      switch (widget.type) {
        case RecordType.labour:
          await ApiService.createLabour({
            'site_id': siteId,
            'full_name': name.text.trim(),
            'trade': secondary.text.trim(),
            'daily_wage': double.tryParse(amount.text) ?? 0,
          });
        case RecordType.payment:
          await ApiService.createPayment({
            'site_id': siteId,
            'type': selection,
            'amount': double.tryParse(amount.text) ?? 0,
            'description': name.text.trim(),
            'party': secondary.text.trim(),
            'date': today,
          });
        case RecordType.design:
          final dimensions = (secondary.text.trim().isEmpty
              ? 'North'
              : secondary.text.trim());
          await ApiService.createDesign({
            'project_name': name.text.trim(),
            'site_id': siteId,
            'design_type': selection,
            'plot_width': 30,
            'plot_length': 50,
            'facing': dimensions,
            'floors': 1,
            'bedrooms': 2,
            'bathrooms': 2,
            'kitchen': 1,
            'parking': true,
            'garden': false,
            'purpose': 'RESIDENTIAL',
          });
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class VendorsPage extends StatelessWidget {
  const VendorsPage({super.key});
  @override
  Widget build(BuildContext context) => const DataListPage(
    title: 'Vendors',
    subtitle: 'Suppliers connected to your construction operations.',
    loader: ApiService.getVendors,
    icon: Icons.storefront_outlined,
    emptyTitle: 'No vendors yet',
    emptyMessage:
        'Vendor records created by your procurement workflow will appear here.',
  );
}

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});
  @override
  Widget build(BuildContext context) => const _StaticWorkspacePage(
    title: 'Subscription',
    subtitle: 'Plan, billing and included design credits.',
    icon: Icons.workspace_premium_outlined,
    message:
        'Subscription status is managed through the SiteSeva platform workspace. Your plan and credit usage will appear here when the subscription endpoint is enabled.',
  );
}

class BrandingPage extends ConsumerStatefulWidget {
  const BrandingPage({super.key});
  @override
  ConsumerState<BrandingPage> createState() => _BrandingPageState();
}

class _BrandingPageState extends ConsumerState<BrandingPage> {
  final formKey = GlobalKey<FormState>();
  final company = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  late Future<Map<String, dynamic>> future;
  bool hydrated = false;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    future = ApiService.getBranding();
  }

  @override
  void dispose() {
    company.dispose();
    email.dispose();
    phone.dispose();
    address.dispose();
    super.dispose();
  }

  void hydrate(Map<String, dynamic> data) {
    if (hydrated) return;
    hydrated = true;
    company.text = '${data['company_name'] ?? ''}';
    email.text = '${data['email'] ?? ''}';
    phone.text = '${data['phone'] ?? ''}';
    address.text = '${data['address'] ?? ''}';
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => saving = true);
    try {
      await ApiService.updateBranding({
        'company_name': company.text.trim(),
        'primary_color': '#2563EB',
        'secondary_color': '#0A0E17',
        'accent_color': '#4F8CFF',
        'font': 'Sora',
        'email': email.text.trim().isEmpty ? null : email.text.trim(),
        'phone': phone.text.trim().isEmpty ? null : phone.text.trim(),
        'address': address.text.trim().isEmpty ? null : address.text.trim(),
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company branding saved.')),
        );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canWrite =
        ref.watch(authControllerProvider).valueOrNull?.isContractor ?? false;
    return AppPage(
      title: 'Company branding',
      subtitle: canWrite
          ? 'Identity shown across your SiteSeva workspace.'
          : 'Company identity for this workspace.',
      child: FutureBuilder<Map<String, dynamic>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                AppSkeleton(height: 170),
                SizedBox(height: 12),
                AppSkeleton(height: 240),
              ],
            );
          if (snapshot.hasError)
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                EmptyPanel(
                  title: 'Branding unavailable',
                  message: '${snapshot.error}',
                  icon: Icons.cloud_off_rounded,
                  actionLabel: 'Retry',
                  onAction: () => setState(() {
                    hydrated = false;
                    future = ApiService.getBranding();
                  }),
                ),
              ],
            );
          hydrate(snapshot.data ?? {});
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [AppTheme.navy, Color(0xFF1D438E)],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: const Icon(
                        Icons.architecture_rounded,
                        color: AppTheme.blue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.text.isEmpty
                                ? 'Your company'
                                : company.text,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Blue-black construction workspace identity',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: const Color(0xFFC8D9F5)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SurfaceCard(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(title: 'Company information'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: company,
                        enabled: canWrite,
                        decoration: const InputDecoration(
                          labelText: 'Company name',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Company name is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: email,
                        enabled: canWrite,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Business email',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phone,
                        enabled: canWrite,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Business phone',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: address,
                        enabled: canWrite,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Registered address',
                        ),
                      ),
                      if (canWrite) ...[
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: saving ? null : save,
                          icon: saving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded),
                          label: Text(
                            saving
                                ? 'Saving brand...'
                                : 'Save company branding',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final links = user?.isContractor ?? false
        ? [
            (Icons.groups_outlined, 'Workforce', '/labour'),
            (Icons.inventory_2_outlined, 'Procurement', '/materials'),
            (Icons.payments_outlined, 'Finance', '/payments'),
            (Icons.auto_awesome_rounded, 'Design studio', '/design-studio'),
            (Icons.palette_outlined, 'Company branding', '/branding'),
          ]
        : [
            (Icons.apartment_outlined, 'My sites', '/sites'),
            (
              Icons.notifications_none_rounded,
              'Notifications',
              '/notifications',
            ),
            (Icons.shield_outlined, 'Security', '/security'),
            (Icons.support_agent_rounded, 'Help center', '/help'),
          ];
    return AppPage(
      title: 'Settings',
      subtitle: user?.email.isEmpty ?? true
          ? 'Account preferences and workspace tools.'
          : user!.email,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        children: [
          SurfaceCard(
            color: AppTheme.navy,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundColor: AppTheme.blue,
                  child: Text(
                    (user?.name.isNotEmpty == true ? user!.name[0] : 'S')
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'SiteSeva user',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.roleLabel ?? 'Workspace member',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFC5D6F4),
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: user?.roleLabel ?? 'Role',
                  tone: const Color(0xFF99BDFF),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionTitle(title: 'Workspace tools'),
          const SizedBox(height: 10),
          ...links.map(
            (link) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SurfaceCard(
                onTap: () => context.go(link.$3),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.blue.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(link.$1, color: AppTheme.blue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        link.$2,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
              context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});
  @override
  Widget build(BuildContext context) => const _StaticWorkspacePage(
    title: 'Help center',
    subtitle: 'Guidance for your SiteSeva workspace.',
    icon: Icons.support_agent_rounded,
    message:
        'For backend connectivity, pass API_BASE_URL when running the app on a physical device. Your company administrator can also manage access and roles from the web workspace.',
  );
}

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});
  @override
  Widget build(BuildContext context) => const _StaticWorkspacePage(
    title: 'Security',
    subtitle: 'Session and account access controls.',
    icon: Icons.shield_outlined,
    message:
        'Authenticated requests use your SiteSeva session token. Password reset and multi-factor authentication can be activated when their backend routes are enabled.',
  );
}

class _StaticWorkspacePage extends StatelessWidget {
  const _StaticWorkspacePage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.message,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final String message;
  @override
  Widget build(BuildContext context) => AppPage(
    title: title,
    subtitle: subtitle,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [EmptyPanel(title: title, message: message, icon: icon)],
    ),
  );
}

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});
  @override
  Widget build(BuildContext context) => DataListPage(
    title: 'Platform overview',
    subtitle: 'SiteSeva system operations.',
    loader: () async => [await ApiService.getAdminDashboard()],
    icon: Icons.admin_panel_settings_outlined,
    emptyTitle: 'No platform data',
    emptyMessage: 'Admin workspace data will appear here.',
  );
}

class AdminApplicationsPage extends StatelessWidget {
  const AdminApplicationsPage({super.key});
  @override
  Widget build(BuildContext context) => const DataListPage(
    title: 'Applications',
    subtitle: 'New company access requests.',
    loader: ApiService.getCompanyApplications,
    icon: Icons.assignment_ind_outlined,
    emptyTitle: 'No applications',
    emptyMessage: 'New contractor applications will arrive here.',
  );
}

class AdminContractorsPage extends StatelessWidget {
  const AdminContractorsPage({super.key});
  @override
  Widget build(BuildContext context) => const DataListPage(
    title: 'Contractors',
    subtitle: 'Active construction businesses on the platform.',
    loader: ApiService.getAdminContractors,
    icon: Icons.business_outlined,
    emptyTitle: 'No contractors',
    emptyMessage: 'Approved contractors will appear here.',
  );
}

class AdminSubscriptionsPage extends StatelessWidget {
  const AdminSubscriptionsPage({super.key});
  @override
  Widget build(BuildContext context) => const DataListPage(
    title: 'Subscriptions',
    subtitle: 'Plan status across companies.',
    loader: ApiService.getAdminSubscriptions,
    icon: Icons.workspace_premium_outlined,
    emptyTitle: 'No subscriptions',
    emptyMessage: 'Subscription records will appear here.',
  );
}

class AdminRevenuePage extends StatelessWidget {
  const AdminRevenuePage({super.key});
  @override
  Widget build(BuildContext context) => DataListPage(
    title: 'Analytics',
    subtitle: 'Platform revenue and usage analytics.',
    loader: () async => [await ApiService.getAdminAnalytics()],
    icon: Icons.insights_outlined,
    emptyTitle: 'No analytics',
    emptyMessage: 'Revenue analytics will appear here.',
  );
}

class AdminPaymentsPage extends StatelessWidget {
  const AdminPaymentsPage({super.key});
  @override
  Widget build(BuildContext context) => const DataListPage(
    title: 'Platform payments',
    subtitle: 'Payment activity across workspaces.',
    loader: ApiService.getPayments,
    icon: Icons.payments_outlined,
    emptyTitle: 'No payments',
    emptyMessage: 'Payment records will appear here.',
  );
}

class AdminAuditPage extends StatelessWidget {
  const AdminAuditPage({super.key});
  @override
  Widget build(BuildContext context) => const _StaticWorkspacePage(
    title: 'Audit logs',
    subtitle: 'Platform event history.',
    icon: Icons.history_rounded,
    message:
        'The reference backend has an audit endpoint ready for connection. Add the admin logs API route to this client to view traceable workspace activity.',
  );
}

class AdminDesignCreditsPage extends StatelessWidget {
  const AdminDesignCreditsPage({super.key});
  @override
  Widget build(BuildContext context) => const DataListPage(
    title: 'Design credits',
    subtitle: 'Credit purchase verification queue.',
    loader: ApiService.getDesignWalletPurchases,
    icon: Icons.auto_awesome_outlined,
    emptyTitle: 'No credit requests',
    emptyMessage: 'Design credit purchase requests will appear here.',
  );
}
