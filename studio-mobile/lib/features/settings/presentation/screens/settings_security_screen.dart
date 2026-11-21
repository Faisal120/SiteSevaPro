import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/settings_models.dart';
import '../../providers/settings_provider.dart';

class SettingsSecurityScreen extends ConsumerStatefulWidget {
  const SettingsSecurityScreen({
    super.key,
    this.initialTab = SettingsTab.preferences,
  });

  final SettingsTab initialTab;

  @override
  ConsumerState<SettingsSecurityScreen> createState() =>
      _SettingsSecurityScreenState();
}

class _SettingsSecurityScreenState
    extends ConsumerState<SettingsSecurityScreen> {
  late SettingsTab _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsControllerProvider);
    return AppPage(
      title: 'Settings',
      subtitle: 'Security, appearance and workspace plan controls.',
      actions: [
        IconButton(
          tooltip: 'Refresh settings',
          onPressed: () =>
              ref.read(settingsControllerProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: state.when(
        loading: _loading,
        error: (error, _) => _error(error),
        data: _content,
      ),
    );
  }

  Widget _loading() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
    children: const [
      AppSkeleton(height: 58),
      SizedBox(height: 14),
      AppSkeleton(height: 280),
    ],
  );

  Widget _error(Object error) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      EmptyPanel(
        title: 'Settings unavailable',
        message: '$error',
        icon: Icons.settings_outlined,
        actionLabel: 'Retry',
        onAction: () => ref.read(settingsControllerProvider.notifier).load(),
      ),
    ],
  );

  Widget _content(SettingsWorkspaceData data) => LayoutBuilder(
    builder: (context, constraints) {
      final pane = switch (_tab) {
        SettingsTab.preferences => _PreferencesPanel(data: data),
        SettingsTab.security => _SecurityPanel(data: data),
        SettingsTab.subscription => _SubscriptionPanel(data: data),
      };
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SettingsHero(data: data)
                      .animate()
                      .fadeIn(duration: 260.ms)
                      .slideY(begin: .04, end: 0),
                  const SizedBox(height: 14),
                  _SettingsTabs(
                    selected: _tab,
                    onChanged: (tab) => setState(() => _tab = tab),
                  ),
                  const SizedBox(height: 18),
                  pane
                      .animate()
                      .fadeIn(duration: 220.ms)
                      .slideY(begin: .025, end: 0),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({required this.data});
  final SettingsWorkspaceData data;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppTheme.navy, Color(0xFF16428A)],
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.tune_rounded, color: Colors.white),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.user.companyName?.trim().isNotEmpty == true
                    ? data.user.companyName!
                    : data.user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.isOffline
                    ? 'Using the authenticated device session'
                    : '${data.user.roleLabel} workspace controls',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFFCBDAF8)),
              ),
            ],
          ),
        ),
        StatusBadge(
          label: data.subscription.hasPlan
              ? data.subscription.plan
              : 'Plan pending',
          tone: const Color(0xFF9FC4FF),
        ),
      ],
    ),
  );
}

class _SettingsTabs extends StatelessWidget {
  const _SettingsTabs({required this.selected, required this.onChanged});
  final SettingsTab selected;
  final ValueChanged<SettingsTab> onChanged;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.all(5),
    child: Row(
      children: SettingsTab.values
          .map(
            (tab) => Expanded(
              child: InkWell(
                onTap: () => onChanged(tab),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: tab == selected ? AppTheme.ink : Colors.transparent,
                  ),
                  child: Text(
                    tab.label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: tab == selected ? Colors.white : AppTheme.muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    ),
  );
}

class _PreferencesPanel extends ConsumerWidget {
  const _PreferencesPanel({required this.data});
  final SettingsWorkspaceData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appThemeModeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: 'Appearance'),
              const SizedBox(height: 5),
              Text(
                'Saved securely on this device and applied across SiteSeva.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: ThemeMode.values
                    .map(
                      (item) => ChoiceChip(
                        selected: mode == item,
                        onSelected: (_) => ref
                            .read(appThemeModeProvider.notifier)
                            .setThemeMode(item),
                        avatar: Icon(_themeIcon(item), size: 17),
                        label: Text(_themeLabel(item)),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: 'Workspace defaults'),
              const SizedBox(height: 10),
              _WorkspacePreferenceEditor(
                initial: data.preferences,
                canEdit: data.user.isContractor && !data.isOffline,
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _themeIcon(ThemeMode mode) => switch (mode) {
    ThemeMode.light => Icons.light_mode_outlined,
    ThemeMode.dark => Icons.dark_mode_outlined,
    ThemeMode.system => Icons.brightness_auto_rounded,
  };

  String _themeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
    ThemeMode.system => 'System',
  };
}

class _WorkspacePreferenceEditor extends ConsumerStatefulWidget {
  const _WorkspacePreferenceEditor({
    required this.initial,
    required this.canEdit,
  });

  final WorkspacePreferences initial;
  final bool canEdit;

  @override
  ConsumerState<_WorkspacePreferenceEditor> createState() =>
      _WorkspacePreferenceEditorState();
}

class _WorkspacePreferenceEditorState
    extends ConsumerState<_WorkspacePreferenceEditor> {
  late String _language;
  late String _currency;
  late String _units;

  @override
  void initState() {
    super.initState();
    _language = _supportedLanguage(widget.initial.language);
    _currency = _supportedCurrency(widget.initial.currency);
    _units = _supportedUnits(widget.initial.measurementSystem);
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(preferencesControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _language,
          decoration: const InputDecoration(
            labelText: 'Language',
            prefixIcon: Icon(Icons.language_rounded),
          ),
          items: const [
            DropdownMenuItem(value: 'en', child: Text('English')),
            DropdownMenuItem(value: 'hi', child: Text('Hindi')),
          ],
          onChanged: widget.canEdit
              ? (value) => setState(() => _language = value ?? _language)
              : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _units,
          decoration: const InputDecoration(
            labelText: 'Measurement units',
            prefixIcon: Icon(Icons.straighten_rounded),
          ),
          items: const [
            DropdownMenuItem(value: 'METRIC', child: Text('Metric')),
            DropdownMenuItem(value: 'IMPERIAL', child: Text('Imperial')),
          ],
          onChanged: widget.canEdit
              ? (value) => setState(() => _units = value ?? _units)
              : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _currency,
          decoration: const InputDecoration(
            labelText: 'Currency',
            prefixIcon: Icon(Icons.currency_rupee_rounded),
          ),
          items: const [
            DropdownMenuItem(value: 'INR', child: Text('Indian Rupee (INR)')),
            DropdownMenuItem(value: 'USD', child: Text('US Dollar (USD)')),
          ],
          onChanged: widget.canEdit
              ? (value) => setState(() => _currency = value ?? _currency)
              : null,
        ),
        const SizedBox(height: 10),
        Text(
          'Workspace timezone: ${widget.initial.timezone}',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
        ),
        if (widget.canEdit) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: saving.isLoading ? null : _save,
              child: Text(
                saving.isLoading
                    ? 'Saving defaults...'
                    : 'Save workspace defaults',
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 8),
          Text(
            'Only the contractor can update company-wide defaults.',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
          ),
        ],
      ],
    );
  }

  Future<void> _save() async {
    final updated = WorkspacePreferences(
      language: _language,
      currency: _currency,
      measurementSystem: _units,
      timezone: widget.initial.timezone,
    );
    final saved = await ref
        .read(preferencesControllerProvider.notifier)
        .save(updated);
    if (!mounted) return;
    if (saved) {
      await ref.read(settingsControllerProvider.notifier).refresh();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Workspace defaults saved.'
              : '${ref.read(preferencesControllerProvider).error ?? 'Defaults could not be saved.'}',
        ),
      ),
    );
  }

  String _supportedLanguage(String value) => value == 'hi' ? value : 'en';

  String _supportedCurrency(String value) => value == 'USD' ? value : 'INR';

  String _supportedUnits(String value) =>
      value == 'IMPERIAL' ? value : 'METRIC';
}

class _SecurityPanel extends ConsumerWidget {
  const _SecurityPanel({required this.data});
  final SettingsWorkspaceData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(title: 'Account security'),
            const SizedBox(height: 5),
            Text(
              'Your current JWT session is held in encrypted device storage.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
            const SizedBox(height: 14),
            _SecurityAction(
              icon: Icons.key_outlined,
              title: 'Change password',
              message: 'Update your authenticated SiteSeva account password.',
              label: 'Update',
              onTap: () => _showPasswordSheet(context, ref),
            ),
            const _UnavailablePreference(
              icon: Icons.fingerprint_rounded,
              title: 'Biometric unlock',
              message:
                  'Requires device biometric enrollment and a server-backed session policy.',
            ),
            const _UnavailablePreference(
              icon: Icons.security_rounded,
              title: 'Two-factor authentication',
              message:
                  'Requires the 2FA enrollment and verification endpoints.',
              last: true,
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(title: 'Device access'),
            const SizedBox(height: 7),
            Text(
              'Device management is not displayed until the backend returns verified sessions. No device list is fabricated here.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.muted,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Future<void> _showPasswordSheet(BuildContext context, WidgetRef ref) async {
  final formKey = GlobalKey<FormState>();
  final current = TextEditingController();
  final next = TextEditingController();
  final confirm = TextEditingController();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(passwordChangeControllerProvider);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.viewInsetsOf(context).bottom + 16,
          ),
          child: SurfaceCard(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: 'Change password'),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: current,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current password',
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your current password.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: next,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New password',
                    ),
                    validator: (value) => value == null || value.length < 8
                        ? 'Use at least 8 characters.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirm,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm new password',
                    ),
                    validator: (value) =>
                        value != next.text ? 'Passwords do not match.' : null,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: state.isLoading
                          ? null
                          : () async {
                              if (!(formKey.currentState?.validate() ?? false))
                                return;
                              final changed = await ref
                                  .read(
                                    passwordChangeControllerProvider.notifier,
                                  )
                                  .change(
                                    currentPassword: current.text,
                                    newPassword: next.text,
                                  );
                              if (!context.mounted) return;
                              if (changed) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Password updated successfully.',
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${ref.read(passwordChangeControllerProvider).error ?? 'Password could not be updated.'}',
                                    ),
                                  ),
                                );
                              }
                            },
                      child: Text(
                        state.isLoading
                            ? 'Updating password...'
                            : 'Update password',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
  current.dispose();
  next.dispose();
  confirm.dispose();
}

class _SecurityAction extends StatelessWidget {
  const _SecurityAction({
    required this.icon,
    required this.title,
    required this.message,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String message;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppTheme.line)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 19, color: AppTheme.muted),
        const SizedBox(width: 10),
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
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.muted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        TextButton(onPressed: onTap, child: Text(label)),
      ],
    ),
  );
}

class _SubscriptionPanel extends StatelessWidget {
  const _SubscriptionPanel({required this.data});
  final SettingsWorkspaceData data;

  @override
  Widget build(BuildContext context) {
    final subscription = data.subscription;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SurfaceCard(
          color: AppTheme.navy,
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.orange.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: AppTheme.orangeBright,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.hasPlan ? subscription.plan : 'Plan pending',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subscription.status ??
                          'Plan value from your authenticated account',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFC7D8F6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (!subscription.apiAvailable)
          _UnavailablePanel(
            message:
                subscription.apiMessage ?? 'Subscription API is not connected.',
          )
        else
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(title: 'Subscription details'),
                const SizedBox(height: 12),
                _DetailLine(
                  label: 'Status',
                  value: subscription.status ?? 'Not returned',
                ),
                _DetailLine(
                  label: 'Renewal',
                  value:
                      subscription.renewsAt
                          ?.toLocal()
                          .toString()
                          .split(' ')
                          .first ??
                      'Not returned',
                ),
                _DetailLine(
                  label: 'AI credits',
                  value:
                      subscription.aiCreditsRemaining?.toString() ??
                      'Open wallet for live balance',
                  last: true,
                ),
              ],
            ),
          ),
        if (data.plans.isNotEmpty) ...[
          const SizedBox(height: 14),
          const SectionTitle(title: 'Available plans'),
          const SizedBox(height: 10),
          ...data.plans.map(
            (plan) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (plan.price != null)
                          Text(
                            '${plan.currency == 'INR' ? '₹' : '${plan.currency} '}${plan.price!.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppTheme.blue,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                      ],
                    ),
                    if (plan.description != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        plan.description!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                      ),
                    ],
                    if (plan.features.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        plan.features.take(3).join(' · '),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
        if (data.permissions.canManageSubscription) ...[
          const SizedBox(height: 14),
          Consumer(
            builder: (context, ref, _) {
              final renewal = ref.watch(subscriptionRenewalControllerProvider);
              return FilledButton.icon(
                onPressed: renewal.isLoading
                    ? null
                    : () async {
                        final requested = await ref
                            .read(
                              subscriptionRenewalControllerProvider.notifier,
                            )
                            .request();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              requested
                                  ? 'Renewal request submitted for verification.'
                                  : '${ref.read(subscriptionRenewalControllerProvider).error ?? 'Renewal request could not be submitted.'}',
                            ),
                          ),
                        );
                      },
                icon: renewal.isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.autorenew_rounded),
                label: Text(
                  renewal.isLoading
                      ? 'Submitting renewal...'
                      : 'Request subscription renewal',
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => context.go('/wallet'),
            icon: const Icon(Icons.toll_rounded),
            label: const Text('Open AI credits wallet'),
          ),
        ],
      ],
    );
  }
}

class _UnavailablePreference extends StatelessWidget {
  const _UnavailablePreference({
    required this.icon,
    required this.title,
    required this.message,
    this.last = false,
  });
  final IconData icon;
  final String title;
  final String message;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(top: 12, bottom: last ? 0 : 12),
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(bottom: BorderSide(color: AppTheme.line)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: AppTheme.muted),
        const SizedBox(width: 10),
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
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.muted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const StatusBadge(label: 'API pending', tone: AppTheme.warning),
      ],
    ),
  );
}

class _UnavailablePanel extends StatelessWidget {
  const _UnavailablePanel({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, color: AppTheme.warning),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.muted, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.label,
    required this.value,
    this.last = false,
  });
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(top: 10, bottom: last ? 0 : 10),
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(bottom: BorderSide(color: AppTheme.line)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
          ),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}
