import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../models/profile_models.dart';
import '../../providers/profile_company_provider.dart';
import '../widgets/profile_company_widgets.dart';

class ProfileCompanyScreen extends ConsumerStatefulWidget {
  const ProfileCompanyScreen({
    super.key,
    this.initialTab = ProfileCompanyTab.profile,
  });

  final ProfileCompanyTab initialTab;

  @override
  ConsumerState<ProfileCompanyScreen> createState() =>
      _ProfileCompanyScreenState();
}

class _ProfileCompanyScreenState extends ConsumerState<ProfileCompanyScreen> {
  late ProfileCompanyTab selectedTab;
  bool saving = false;
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileCompanyControllerProvider);
    return AppPage(
      title: 'Profile & Company',
      subtitle: 'Your identity, workspace access and company controls.',
      actions: [
        IconButton(
          onPressed: () => ref
              .read(profileCompanyControllerProvider.notifier)
              .refresh(),
          tooltip: 'Refresh profile',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: state.when(
        loading: () => _loading(),
        error: (error, stackTrace) => ProfileEmptyState(
          title: 'Profile unavailable',
          message: '$error',
          onRetry: () => ref
              .read(profileCompanyControllerProvider.notifier)
              .load(),
        ),
        data: (data) => _content(data),
      ),
    );
  }

  Widget _loading() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
    children: const [
      AppSkeleton(height: 170),
      SizedBox(height: 14),
      AppSkeleton(height: 58),
      SizedBox(height: 14),
      AppSkeleton(height: 300),
    ],
  );

  Widget _content(ProfileCompanyData data) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 980;
      final body = switch (selectedTab) {
        ProfileCompanyTab.profile => _profileTab(data, wide),
        ProfileCompanyTab.company => _companyTab(data, wide),
        ProfileCompanyTab.access => _accessTab(data, wide),
      };
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileCompanyHero(
                  data: data,
                  onRefresh: () => ref
                      .read(profileCompanyControllerProvider.notifier)
                      .refresh(),
                ).animate().fadeIn(duration: 280.ms).slideY(begin: .04, end: 0),
                const SizedBox(height: 14),
                ProfileConnectionBanner(
                  data: data,
                  onRetry: () => ref
                      .read(profileCompanyControllerProvider.notifier)
                      .refresh(),
                ),
                if (data.isOffline || !data.apiAvailable)
                  const SizedBox(height: 14),
                const SizedBox(height: 14),
                ProfileTabBar(
                  selected: selectedTab,
                  onChanged: (tab) => setState(() => selectedTab = tab),
                ),
                const SizedBox(height: 18),
                body.animate().fadeIn(duration: 260.ms).slideY(begin: .03, end: 0),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out of this device'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _profileTab(ProfileCompanyData data, bool wide) {
    final cards = [
      ProfileInfoCard(data: data),
      CompanySummaryCard(data: data, onOpenBranding: _openCompanyTab),
    ];
    return _responsiveCards(cards, wide);
  }

  Widget _companyTab(ProfileCompanyData data, bool wide) {
    final editor = BrandingEditorCard(
      data: data,
      enabled: data.permissions.canEditBranding,
      saving: saving,
      uploading: uploading,
      onSave: _saveBranding,
      onUploadLogo: _pickLogo,
    );
    final summary = CompanySummaryCard(data: data, onOpenBranding: _openCompanyTab);
    return _responsiveCards([editor, summary], wide);
  }

  Widget _accessTab(ProfileCompanyData data, bool wide) {
    final access = WorkspaceAccessCard(data: data, onOpen: context.go);
    final plan = _planCard(data);
    return _responsiveCards([access, plan], wide);
  }

  Widget _responsiveCards(List<Widget> cards, bool wide) {
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: cards
            .indexed
            .map(
              (entry) => Padding(
                padding: EdgeInsets.only(bottom: entry.$1 == cards.length - 1 ? 0 : 14),
                child: entry.$2,
              ),
            )
            .toList(),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: cards
          .map(
            (card) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: card == cards.first ? 7 : 0,
                  left: card == cards.last ? 7 : 0,
                ),
                child: card,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _planCard(ProfileCompanyData data) {
    final plan = data.user.plan?.trim() ?? '';
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Plan & workspace status'),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.orange.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: AppTheme.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.isEmpty ? 'Plan not returned' : plan,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      plan.isEmpty
                          ? 'The current auth response does not include subscription details.'
                          : 'Plan value returned by the authenticated workspace session.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppTheme.blue.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock_outline_rounded, color: AppTheme.blue, size: 18),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Billing, credit balance and renewal dates are intentionally not estimated. They will appear when the subscription API is connected.',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.blue,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBranding(BrandingUpdate input) async {
    setState(() => saving = true);
    try {
      await ref.read(profileCompanyControllerProvider.notifier).saveBranding(input);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company branding saved.')),
        );
      }
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _pickLogo() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1600,
    );
    if (file == null) return;
    setState(() => uploading = true);
    try {
      await ref
          .read(profileCompanyControllerProvider.notifier)
          .uploadLogo(bytes: await file.readAsBytes(), filename: file.name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company logo updated.')),
        );
      }
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  void _openCompanyTab() => setState(() => selectedTab = ProfileCompanyTab.company);

  void _showError(Object error) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$error')),
  );

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go('/login');
  }
}
