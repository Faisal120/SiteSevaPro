import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/profile_models.dart';

class ProfileCompanyHero extends StatelessWidget {
  const ProfileCompanyHero({
    super.key,
    required this.data,
    required this.onRefresh,
  });

  final ProfileCompanyData data;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final user = data.user;
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _display(user.name, 'SiteSeva member'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          user.email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFFCDDBF6),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _HeroPill(label: user.roleLabel, icon: Icons.badge_outlined),
            if (data.company.name.isNotEmpty)
              _HeroPill(
                label: data.company.name,
                icon: Icons.business_outlined,
              ),
          ],
        ),
      ],
    );
    final refresh = IconButton(
      onPressed: onRefresh,
      tooltip: 'Refresh profile',
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: .12),
        foregroundColor: Colors.white,
      ),
      icon: const Icon(Icons.refresh_rounded),
    );
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.navy, Color(0xFF153A78), AppTheme.blue],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26101A2D),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 390
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Avatar(
                        label: _initials(user.name),
                        logoUrl: data.company.logoUrl ?? data.branding.logoUrl,
                        size: 56,
                        light: true,
                      ),
                      const Spacer(),
                      refresh,
                    ],
                  ),
                  const SizedBox(height: 14),
                  identity,
                ],
              )
            : Row(
                children: [
                  _Avatar(
                    label: _initials(user.name),
                    logoUrl: data.company.logoUrl ?? data.branding.logoUrl,
                    size: 64,
                    light: true,
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: identity),
                  refresh,
                ],
              ),
      ),
    );
  }
}

class ProfileTabBar extends StatelessWidget {
  const ProfileTabBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ProfileCompanyTab selected;
  final ValueChanged<ProfileCompanyTab> onChanged;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.all(5),
    child: Row(
      children: ProfileCompanyTab.values.map((tab) {
        final active = tab == selected;
        return Expanded(
          child: InkWell(
            onTap: () => onChanged(tab),
            borderRadius: BorderRadius.circular(17),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: active ? AppTheme.ink : Colors.transparent,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Text(
                tab.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: active ? Colors.white : AppTheme.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}

class ProfileConnectionBanner extends StatelessWidget {
  const ProfileConnectionBanner({
    super.key,
    required this.data,
    required this.onRetry,
  });

  final ProfileCompanyData data;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final offline = data.isOffline || !data.apiAvailable;
    final message = offline
        ? data.apiMessage ?? 'Showing the last synced profile from this device.'
        : data.brandingApiAvailable
        ? null
        : data.brandingApiMessage;
    if (message == null || message.isEmpty) return const SizedBox.shrink();
    final tone = offline ? AppTheme.warning : AppTheme.blue;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tone.withValues(alpha: .18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            offline ? Icons.cloud_off_rounded : Icons.info_outline_rounded,
            color: tone,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tone,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({super.key, required this.data});

  final ProfileCompanyData data;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Personal profile'),
        const SizedBox(height: 8),
        ProfileValueRow(
          icon: Icons.person_outline_rounded,
          label: 'Full name',
          value: data.user.name,
        ),
        ProfileValueRow(
          icon: Icons.alternate_email_rounded,
          label: 'Email',
          value: data.user.email,
        ),
        ProfileValueRow(
          icon: Icons.account_tree_outlined,
          label: 'Workspace role',
          value: data.user.roleLabel,
        ),
        ProfileValueRow(
          icon: Icons.fingerprint_rounded,
          label: 'Account ID',
          value: _display(data.user.id, 'Not returned by API'),
          compactValue: true,
          last: true,
        ),
      ],
    ),
  );
}

class CompanySummaryCard extends StatelessWidget {
  const CompanySummaryCard({
    super.key,
    required this.data,
    required this.onOpenBranding,
  });

  final ProfileCompanyData data;
  final VoidCallback onOpenBranding;

  @override
  Widget build(BuildContext context) {
    final company = data.company;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(
                label: _initials(company.name),
                logoUrl: company.logoUrl ?? data.branding.logoUrl,
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _display(company.name, 'Company not configured'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      company.location.isEmpty
                          ? 'Workspace identity'
                          : company.location,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onOpenBranding,
                tooltip: 'Open branding',
                icon: const Icon(Icons.open_in_new_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ProfileValueRow(
            icon: Icons.mail_outline_rounded,
            label: 'Business email',
            value: _display(company.email ?? data.branding.email, 'Not provided'),
          ),
          ProfileValueRow(
            icon: Icons.phone_outlined,
            label: 'Business phone',
            value: _display(company.phone ?? data.branding.phone, 'Not provided'),
          ),
          ProfileValueRow(
            icon: Icons.receipt_long_outlined,
            label: 'GSTIN',
            value: _display(
              company.gstNumber ?? data.branding.gstNumber,
              'Not provided',
            ),
          ),
          ProfileValueRow(
            icon: Icons.location_on_outlined,
            label: 'Registered address',
            value: _display(
              company.address ?? data.branding.address,
              'Not provided',
            ),
            last: true,
          ),
        ],
      ),
    );
  }
}

class BrandingEditorCard extends StatefulWidget {
  const BrandingEditorCard({
    super.key,
    required this.data,
    required this.enabled,
    required this.onSave,
    required this.onUploadLogo,
    this.saving = false,
    this.uploading = false,
  });

  final ProfileCompanyData data;
  final bool enabled;
  final ValueChanged<BrandingUpdate> onSave;
  final VoidCallback onUploadLogo;
  final bool saving;
  final bool uploading;

  @override
  State<BrandingEditorCard> createState() => _BrandingEditorCardState();
}

class _BrandingEditorCardState extends State<BrandingEditorCard> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController company;
  late final TextEditingController email;
  late final TextEditingController phone;
  late final TextEditingController address;
  late final TextEditingController website;
  late final TextEditingController gst;

  @override
  void initState() {
    super.initState();
    company = TextEditingController();
    email = TextEditingController();
    phone = TextEditingController();
    address = TextEditingController();
    website = TextEditingController();
    gst = TextEditingController();
    _hydrate();
  }

  @override
  void didUpdateWidget(covariant BrandingEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.fetchedAt != widget.data.fetchedAt) _hydrate();
  }

  @override
  void dispose() {
    company.dispose();
    email.dispose();
    phone.dispose();
    address.dispose();
    website.dispose();
    gst.dispose();
    super.dispose();
  }

  void _hydrate() {
    final data = widget.data;
    final branding = data.branding;
    final profile = data.company;
    company.text = _firstNonEmpty([branding.companyName, profile.name]);
    email.text = _firstNonEmpty([branding.email, profile.email]);
    phone.text = _firstNonEmpty([branding.phone, profile.phone]);
    address.text = _firstNonEmpty([branding.address, profile.address]);
    website.text = _firstNonEmpty([branding.website, profile.website]);
    gst.text = _firstNonEmpty([branding.gstNumber, profile.gstNumber]);
  }

  void _save() {
    if (!(formKey.currentState?.validate() ?? false)) return;
    widget.onSave(
      BrandingUpdate(
        companyName: company.text,
        email: email.text,
        phone: phone.text,
        address: address.text,
        website: website.text,
        gstNumber: gst.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locked = !widget.enabled;
    return SurfaceCard(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: SectionTitle(title: 'Company branding')),
                if (locked)
                  const StatusBadge(label: 'Read only', tone: AppTheme.muted)
                else
                  StatusBadge(
                    label: widget.data.brandingApiAvailable
                        ? 'Editable'
                        : 'API unavailable',
                    tone: widget.data.brandingApiAvailable
                        ? AppTheme.success
                        : AppTheme.warning,
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              locked
                  ? 'Only contractors can change the workspace identity.'
                  : 'This identity is used on estimates, reports and the workspace header.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.muted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _Avatar(
                  label: _initials(company.text),
                  logoUrl: widget.data.company.logoUrl ?? widget.data.branding.logoUrl,
                  size: 54,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.data.branding.logoUrl == null
                        ? 'No company logo connected'
                        : 'Company logo connected',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: locked || widget.uploading ? null : widget.onUploadLogo,
                  child: Text(widget.uploading ? 'Uploading...' : 'Change logo'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _field(
              company,
              'Company name',
              Icons.business_outlined,
              enabled: !locked,
              required: true,
            ),
            const SizedBox(height: 12),
            _field(
              email,
              'Business email',
              Icons.mail_outline_rounded,
              enabled: !locked,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _field(
              phone,
              'Business phone',
              Icons.phone_outlined,
              enabled: !locked,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _field(
              address,
              'Registered address',
              Icons.location_on_outlined,
              enabled: !locked,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            _field(
              website,
              'Website',
              Icons.language_rounded,
              enabled: !locked,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            _field(
              gst,
              'GSTIN',
              Icons.receipt_long_outlined,
              enabled: !locked,
            ),
            if (!locked) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: widget.saving || !widget.data.brandingApiAvailable
                    ? null
                    : _save,
                icon: widget.saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(widget.saving ? 'Saving changes...' : 'Save branding'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    required bool enabled,
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) => TextFormField(
    controller: controller,
    enabled: enabled,
    keyboardType: keyboardType,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
    ),
    validator: required
        ? (value) => value == null || value.trim().isEmpty
            ? '$label is required'
            : null
        : null,
  );
}

class WorkspaceAccessCard extends StatelessWidget {
  const WorkspaceAccessCard({
    super.key,
    required this.data,
    required this.onOpen,
  });

  final ProfileCompanyData data;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Workspace controls'),
        const SizedBox(height: 8),
        ProfileActionTile(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          subtitle: 'Payments, attendance and site updates',
          onTap: () => onOpen('/notifications'),
        ),
        ProfileActionTile(
          icon: Icons.shield_outlined,
          title: 'Security',
          subtitle: 'Session access and account protection',
          onTap: () => onOpen('/security'),
        ),
        ProfileActionTile(
          icon: Icons.tune_rounded,
          title: 'Preferences',
          subtitle: 'Theme and workspace defaults',
          onTap: () => onOpen('/preferences'),
        ),
        if (data.permissions.canManageSubscription)
          ProfileActionTile(
            icon: Icons.workspace_premium_outlined,
            title: 'Subscription',
            subtitle: data.user.plan?.trim().isNotEmpty == true
                ? 'Current plan: ${data.user.plan}'
                : 'Plan details are not returned by the API',
            onTap: () => onOpen('/subscription'),
          ),
        if (data.permissions.canManageSubscription)
          ProfileActionTile(
            icon: Icons.auto_awesome_rounded,
            title: 'AI credits wallet',
            subtitle: 'Usage ledger and verified credit purchases',
            onTap: () => onOpen('/wallet'),
          ),
        ProfileActionTile(
          icon: Icons.support_agent_rounded,
          title: 'Help center',
          subtitle: 'Get support for your workspace',
          onTap: () => onOpen('/help'),
          last: true,
        ),
      ],
    ),
  );
}

class ProfileActionTile extends StatelessWidget {
  const ProfileActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : 8),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.blue.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppTheme.blue, size: 19),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
            ],
          ),
        ),
      ),
    ),
  );
}

class ProfileValueRow extends StatelessWidget {
  const ProfileValueRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.compactValue = false,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool compactValue;
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
        Icon(icon, color: AppTheme.muted, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: compactValue ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class ProfileEmptyState extends StatelessWidget {
  const ProfileEmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      EmptyPanel(
        title: title,
        message: message,
        icon: Icons.person_off_outlined,
        actionLabel: 'Retry',
        onAction: onRetry,
      ),
    ],
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.label,
    required this.size,
    this.logoUrl,
    this.light = false,
  });

  final String label;
  final double size;
  final String? logoUrl;
  final bool light;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: light ? Colors.white : AppTheme.ink,
      borderRadius: BorderRadius.circular(size * .3),
      border: light
          ? Border.all(color: Colors.white.withValues(alpha: .45), width: 2)
          : null,
    ),
    child: logoUrl == null || logoUrl!.isEmpty
        ? Center(
            child: Text(
              label,
              style: TextStyle(
                color: light ? AppTheme.blue : Colors.white,
                fontSize: size * .28,
                fontWeight: FontWeight.w800,
              ),
            ),
          )
        : Image.network(
            logoUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Center(
              child: Text(
                label,
                style: TextStyle(
                  color: light ? AppTheme.blue : Colors.white,
                  fontSize: size * .28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
  );
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFFBFD6FF)),
        const SizedBox(width: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ),
      ],
    ),
  );
}

String _display(String? value, String fallback) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _initials(String? value) {
  final words = (value ?? '').trim().split(RegExp(r'\s+'));
  final initials = words
      .where((word) => word.isNotEmpty)
      .take(2)
      .map((word) => word[0].toUpperCase())
      .join();
  return initials.isEmpty ? 'S' : initials;
}

String _firstNonEmpty(List<String?> values) =>
    values.map((value) => value?.trim() ?? '').firstWhere(
      (value) => value.isNotEmpty,
      orElse: () => '',
    );

enum ProfileCompanyTab {
  profile('Profile'),
  company('Company'),
  access('Access');

  const ProfileCompanyTab(this.label);
  final String label;
}
