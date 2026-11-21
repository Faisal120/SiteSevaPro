import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/contractor_application.dart';
import '../../providers/auth_provider.dart';
import '../widgets/auth_shell.dart';

class ContractorApplicationScreen extends ConsumerStatefulWidget {
  const ContractorApplicationScreen({super.key});

  @override
  ConsumerState<ContractorApplicationScreen> createState() =>
      _ContractorApplicationScreenState();
}

class _ContractorApplicationScreenState
    extends ConsumerState<ContractorApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyName = TextEditingController();
  final _ownerName = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _gst = TextEditingController();
  final _activeProjects = TextEditingController();
  final _employeeCount = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _companyName.dispose();
    _ownerName.dispose();
    _mobile.dispose();
    _email.dispose();
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _gst.dispose();
    _activeProjects.dispose();
    _employeeCount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _error = null);
    try {
      await ref
          .read(contractorApplicationProvider.notifier)
          .submit(
            ContractorApplicationInput(
              companyName: _companyName.text,
              ownerName: _ownerName.text,
              mobile: _mobile.text,
              email: _email.text,
              officeAddress: _address.text,
              city: _city.text,
              state: _state.text,
              gstNumber: _gst.text,
              activeProjects: int.tryParse(_activeProjects.text) ?? 0,
              employeeCount: int.tryParse(_employeeCount.text) ?? 0,
            ),
          );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final applicationState = ref.watch(contractorApplicationProvider);
    final application = applicationState.valueOrNull;
    return AuthShell(
      formMaxWidth: 720,
      child: application == null
          ? _ApplicationForm(
              formKey: _formKey,
              companyName: _companyName,
              ownerName: _ownerName,
              mobile: _mobile,
              email: _email,
              address: _address,
              city: _city,
              state: _state,
              gst: _gst,
              activeProjects: _activeProjects,
              employeeCount: _employeeCount,
              error: _error,
              loading: applicationState.isLoading,
              onBack: _backToLogin,
              onSubmit: _submit,
            )
          : _ApplicationSuccess(application: application, onBack: _backToLogin),
    );
  }

  void _backToLogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
    }
  }
}

class _ApplicationForm extends StatelessWidget {
  const _ApplicationForm({
    required this.formKey,
    required this.companyName,
    required this.ownerName,
    required this.mobile,
    required this.email,
    required this.address,
    required this.city,
    required this.state,
    required this.gst,
    required this.activeProjects,
    required this.employeeCount,
    required this.error,
    required this.loading,
    required this.onBack,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController companyName;
  final TextEditingController ownerName;
  final TextEditingController mobile;
  final TextEditingController email;
  final TextEditingController address;
  final TextEditingController city;
  final TextEditingController state;
  final TextEditingController gst;
  final TextEditingController activeProjects;
  final TextEditingController employeeCount;
  final String? error;
  final bool loading;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Form(
    key: formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: loading ? null : onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Back to sign in'),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Bring your company\nto SiteSeva',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -1.15,
            height: 1.12,
          ),
        ).animate().fadeIn(duration: 320.ms).slideY(begin: .1, end: 0),
        const SizedBox(height: 10),
        Text(
          'Submit the operating details your SiteSeva team needs to create a contractor workspace. Every field below is sent directly to the application API.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.muted, height: 1.55),
        ),
        const SizedBox(height: 28),
        if (error != null) ...[
          AuthErrorBanner(message: error!),
          const SizedBox(height: 16),
        ],
        Text(
          'BUSINESS DETAILS',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.muted,
            fontWeight: FontWeight.w800,
            letterSpacing: .9,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 610;
            final fieldWidth = twoColumns
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 14,
              children: [
                SizedBox(
                  width: fieldWidth,
                  child: _RequiredField(
                    controller: companyName,
                    label: 'Company name',
                    icon: Icons.business_rounded,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: _RequiredField(
                    controller: ownerName,
                    label: 'Owner name',
                    icon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Work email',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                    validator: (value) {
                      final input = value?.trim() ?? '';
                      return input.contains('@') && input.contains('.')
                          ? null
                          : 'Enter a valid email';
                    },
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: TextFormField(
                    controller: mobile,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    decoration: const InputDecoration(
                      labelText: 'Mobile number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (value) {
                      final digits = (value ?? '').replaceAll(
                        RegExp(r'\D'),
                        '',
                      );
                      return digits.length >= 10
                          ? null
                          : 'Enter a valid mobile number';
                    },
                  ),
                ),
                SizedBox(
                  width: constraints.maxWidth,
                  child: _RequiredField(
                    controller: address,
                    label: 'Office address',
                    icon: Icons.location_on_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: _RequiredField(
                    controller: city,
                    label: 'City',
                    icon: Icons.location_city_rounded,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: _RequiredField(
                    controller: state,
                    label: 'State',
                    icon: Icons.map_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: TextFormField(
                    controller: gst,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'GST number (optional)',
                      prefixIcon: Icon(Icons.receipt_long_outlined),
                    ),
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: _NonNegativeNumberField(
                    controller: activeProjects,
                    label: 'Active projects',
                    icon: Icons.apartment_rounded,
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: _NonNegativeNumberField(
                    controller: employeeCount,
                    label: 'Team size',
                    icon: Icons.groups_2_outlined,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.orange.withValues(alpha: .06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.orange.withValues(alpha: .14)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: AppTheme.orange,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Submitting creates a pending contractor application. It does not create credentials until the backend approves the application.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.muted,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AuthPrimaryButton(
          label: loading ? 'Submitting application...' : 'Submit application',
          icon: Icons.arrow_forward_rounded,
          loading: loading,
          onPressed: loading ? null : onSubmit,
        ),
      ],
    ),
  );
}

class _ApplicationSuccess extends StatelessWidget {
  const _ApplicationSuccess({required this.application, required this.onBack});

  final ContractorApplication application;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 32),
      Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: .11),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(
          Icons.check_rounded,
          color: AppTheme.success,
          size: 32,
        ),
      ).animate().scale(begin: const Offset(.7, .7), duration: 360.ms).fadeIn(),
      const SizedBox(height: 26),
      Text(
        'Application received',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -1.1,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        '${application.companyName} is now in the SiteSeva review queue. Sign-in becomes available after the application is approved and credentials are issued.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted, height: 1.6),
      ),
      const SizedBox(height: 28),
      Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.line),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D0A0E17),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ResultRow(label: 'Status', value: application.status),
                const Divider(height: 26),
                _ResultRow(label: 'Owner', value: application.ownerName),
                const Divider(height: 26),
                _ResultRow(label: 'Email', value: application.email),
                const Divider(height: 26),
                SelectionArea(
                  child: _ResultRow(
                    label: 'Application ID',
                    value: application.id,
                  ),
                ),
              ],
            ),
          )
          .animate(delay: 100.ms)
          .fadeIn(duration: 350.ms)
          .slideY(begin: .08, end: 0),
      const SizedBox(height: 24),
      AuthPrimaryButton(
        label: 'Return to sign in',
        icon: Icons.login_rounded,
        onPressed: onBack,
      ),
    ],
  );
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 120,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

class _RequiredField extends StatelessWidget {
  const _RequiredField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    textInputAction: textInputAction,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    validator: (value) =>
        (value?.trim().isNotEmpty ?? false) ? null : '$label is required',
  );
}

class _NonNegativeNumberField extends StatelessWidget {
  const _NonNegativeNumberField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    textInputAction: TextInputAction.next,
    decoration: InputDecoration(
      labelText: label,
      hintText: '0',
      prefixIcon: Icon(icon),
    ),
    validator: (value) {
      if (value == null || value.trim().isEmpty) return null;
      final parsed = int.tryParse(value.trim());
      return parsed != null && parsed >= 0 ? null : 'Enter 0 or more';
    },
  );
}
