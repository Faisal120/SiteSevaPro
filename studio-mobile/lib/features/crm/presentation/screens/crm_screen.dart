import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/crm_models.dart';
import '../../providers/crm_provider.dart';
import '../widgets/crm_widgets.dart';

class CrmScreen extends ConsumerWidget {
  const CrmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final state = ref.watch(crmControllerProvider);
    if (user == null) return const SizedBox.shrink();
    return state.when(
      loading: () => const _CrmLoadingView(),
      error: (error, stackTrace) => _CrmErrorView(
        error: error,
        onRetry: () => ref.read(crmControllerProvider.notifier).load(),
      ),
      data: (data) => _CrmWorkspace(user: user, data: data),
    );
  }
}

class _CrmWorkspace extends ConsumerWidget {
  const _CrmWorkspace({required this.user, required this.data});

  final AuthUser user;
  final CrmWorkspaceData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = CrmPermissions(role: user.role);
    final action = ref.watch(crmActionControllerProvider);
    final controller = ref.read(crmControllerProvider.notifier);
    return AppPage(
      title: 'CRM',
      subtitle: 'Leads, relationships and follow-up control for your company.',
      actions: [
        IconButton(
          tooltip: 'Refresh CRM',
          onPressed: action.isLoading ? null : controller.refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
        if (_canCreate(permissions, data.workspace) && data.apiAvailable)
          FilledButton.icon(
            onPressed: action.isLoading
                ? null
                : () => _openCreate(context, ref, data.workspace),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 46),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
          ),
      ],
      child: RefreshIndicator(
        color: AppTheme.orange,
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
          children: [
            CrmHeroCard(
              role: user.role,
              data: data,
              canWrite: _canCreate(permissions, data.workspace),
              onCreate: () => _openCreate(context, ref, data.workspace),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: .05, end: 0),
            if (data.isOffline) ...[
              const SizedBox(height: 14),
              CrmOfflineBanner(cachedAt: data.fetchedAt),
            ],
            const SizedBox(height: 18),
            if (!data.apiAvailable) ...[
              CrmApiNotice(
                message: data.apiMessage ?? 'CRM API is not available.',
                onRetry: controller.load,
              ),
              const SizedBox(height: 18),
            ],
            CrmMetricStrip(metrics: data.metrics),
            const SizedBox(height: 20),
            CrmWorkspaceTabs(
              selected: data.workspace,
              onChanged: controller.setWorkspace,
            ),
            const SizedBox(height: 13),
            TextFormField(
              key: const ValueKey('crm-search'),
              initialValue: data.query,
              onChanged: controller.setQuery,
              decoration: const InputDecoration(
                hintText: 'Search records, companies or contacts',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 18),
            if (data.visibleRecords.isEmpty)
              CrmEmptyState(
                workspace: data.workspace,
                apiAvailable: data.apiAvailable,
                canWrite: _canCreate(permissions, data.workspace),
                onCreate: () => _openCreate(context, ref, data.workspace),
              )
            else
              ...data.visibleRecords.indexed.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CrmRecordCard(
                    record: entry.$2,
                    onComplete: entry.$2 is CrmActivity &&
                            permissions.canWriteActivities
                        ? () => _completeActivity(
                              context,
                              ref,
                              (entry.$2 as CrmActivity).id,
                            )
                        : null,
                  ).animate(delay: (entry.$1.clamp(0, 8) * 42).ms).fadeIn(
                    duration: 220.ms,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeActivity(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final completed = await ref
        .read(crmActionControllerProvider.notifier)
        .completeActivity(id);
    if (!completed && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${ref.read(crmActionControllerProvider).value.error ?? 'Could not complete activity.'}',
          ),
        ),
      );
    }
  }

  Future<void> _openCreate(
    BuildContext context,
    WidgetRef ref,
    CrmWorkspace workspace,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) => CrmCreateSheet(workspace: workspace),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${workspace.label} record created.')),
      );
    }
  }

  bool _canCreate(CrmPermissions permissions, CrmWorkspace workspace) =>
      switch (workspace) {
        CrmWorkspace.leads => permissions.canWriteLeads,
        CrmWorkspace.clients || CrmWorkspace.vendors =>
          permissions.canWriteContacts,
        CrmWorkspace.activities => permissions.canWriteActivities,
        CrmWorkspace.quotations => permissions.canWriteQuotations,
      };
}

class CrmCreateSheet extends ConsumerStatefulWidget {
  const CrmCreateSheet({super.key, required this.workspace});

  final CrmWorkspace workspace;

  @override
  ConsumerState<CrmCreateSheet> createState() => _CrmCreateSheetState();
}

class _CrmCreateSheetState extends ConsumerState<CrmCreateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _company = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _source = TextEditingController();
  final _value = TextEditingController();
  final _city = TextEditingController();
  final _gstin = TextEditingController();
  final _description = TextEditingController();
  final _contactId = TextEditingController();
  CrmContactKind _contactKind = CrmContactKind.client;
  CrmActivityKind _activityKind = CrmActivityKind.followUp;

  @override
  void initState() {
    super.initState();
    if (widget.workspace == CrmWorkspace.vendors) {
      _contactKind = CrmContactKind.vendor;
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _company,
      _email,
      _phone,
      _source,
      _value,
      _city,
      _gstin,
      _description,
      _contactId,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(crmActionControllerProvider);
    final error = action.value.hasError ? '${action.value.error}' : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _createTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'This record will be submitted to the authenticated CRM workspace.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.muted,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(
                error,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.danger,
                ),
              ),
            ],
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 16, bottom: 14),
                child: _fields(context),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: action.isLoading ? null : _submit,
                icon: action.isLoading
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_outlined, size: 18),
                label: Text(action.isLoading ? 'Submitting...' : 'Submit record'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fields(BuildContext context) {
    switch (widget.workspace) {
      case CrmWorkspace.leads:
        return Column(
          children: [
            _field(_name, 'Contact name', required: true),
            _field(_company, 'Company'),
            _field(_email, 'Email', keyboard: TextInputType.emailAddress),
            _field(_phone, 'Phone', keyboard: TextInputType.phone),
            _field(_source, 'Source e.g. referral, website'),
            _field(_value, 'Estimated value', keyboard: TextInputType.number),
          ],
        );
      case CrmWorkspace.clients || CrmWorkspace.vendors:
        return Column(
          children: [
            _field(_name, 'Contact name', required: true),
            _field(_company, 'Company'),
            DropdownButtonFormField<CrmContactKind>(
              initialValue: _contactKind,
              decoration: const InputDecoration(labelText: 'Relationship type'),
              items: const [
                DropdownMenuItem(
                  value: CrmContactKind.client,
                  child: Text('Client'),
                ),
                DropdownMenuItem(
                  value: CrmContactKind.vendor,
                  child: Text('Vendor'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _contactKind = value);
              },
            ),
            _field(_email, 'Email', keyboard: TextInputType.emailAddress),
            _field(_phone, 'Phone', keyboard: TextInputType.phone),
            _field(_city, 'City'),
            _field(_gstin, 'GSTIN'),
          ],
        );
      case CrmWorkspace.activities:
        return Column(
          children: [
            DropdownButtonFormField<CrmActivityKind>(
              initialValue: _activityKind,
              decoration: const InputDecoration(labelText: 'Activity type'),
              items: CrmActivityKind.values
                  .where((kind) => kind != CrmActivityKind.unknown)
                  .map(
                    (kind) => DropdownMenuItem(
                      value: kind,
                      child: Text(kind.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _activityKind = value);
              },
            ),
            _field(_name, 'Title', required: true),
            _field(_contactId, 'Contact ID'),
            _field(_description, 'Notes', maxLines: 3),
          ],
        );
      case CrmWorkspace.quotations:
        return Column(
          children: [
            _field(_name, 'Quotation title', required: true),
            _field(_contactId, 'Contact ID', required: true),
            _field(_value, 'Amount', required: true, keyboard: TextInputType.number),
          ],
        );
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? keyboard,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (value) => value == null || value.trim().isEmpty
                ? '$label is required'
                : null
          : null,
    ),
  );

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final controller = ref.read(crmActionControllerProvider.notifier);
    final saved = switch (widget.workspace) {
      CrmWorkspace.leads => await controller.createLead(
        CrmLeadInput(
          name: _name.text.trim(),
          company: _company.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          source: _source.text.trim(),
          value: double.tryParse(_value.text.trim()) ?? 0,
        ),
      ),
      CrmWorkspace.clients || CrmWorkspace.vendors =>
        await controller.createContact(
          CrmContactInput(
            kind: _contactKind,
            name: _name.text.trim(),
            company: _company.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim(),
            city: _city.text.trim(),
            gstin: _gstin.text.trim(),
          ),
        ),
      CrmWorkspace.activities => await controller.createActivity(
        CrmActivityInput(
          kind: _activityKind,
          title: _name.text.trim(),
          description: _description.text.trim(),
          contactId: _contactId.text.trim(),
          scheduledAt: null,
        ),
      ),
      CrmWorkspace.quotations => await controller.createQuotation(
        CrmQuotationInput(
          title: _name.text.trim(),
          contactId: _contactId.text.trim(),
          amount: double.tryParse(_value.text.trim()) ?? 0,
          validUntil: null,
        ),
      ),
    };
    if (saved && mounted) Navigator.of(context).pop(true);
  }

  String get _createTitle => switch (widget.workspace) {
    CrmWorkspace.leads => 'Create lead',
    CrmWorkspace.clients => 'Add client',
    CrmWorkspace.vendors => 'Add vendor',
    CrmWorkspace.activities => 'Create follow-up',
    CrmWorkspace.quotations => 'Create quotation',
  };
}

class _CrmLoadingView extends StatelessWidget {
  const _CrmLoadingView();

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'CRM',
    subtitle: 'Loading relationship workspace...',
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      children: const [
        AppSkeleton(height: 240, radius: 30),
        SizedBox(height: 16),
        AppSkeleton(height: 92, radius: 22),
        SizedBox(height: 14),
        AppSkeleton(height: 52, radius: 18),
        SizedBox(height: 12),
        AppSkeleton(height: 112, radius: 24),
      ],
    ),
  );
}

class _CrmErrorView extends StatelessWidget {
  const _CrmErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'CRM',
    subtitle: 'Relationship workspace',
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      children: [
        EmptyPanel(
          title: 'CRM unavailable',
          message: '$error',
          icon: Icons.cloud_off_rounded,
          actionLabel: 'Reconnect',
          onAction: onRetry,
        ),
      ],
    ),
  );
}
