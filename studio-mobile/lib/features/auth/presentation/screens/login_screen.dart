import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../widgets/auth_shell.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showPassword = false;
  bool _rememberSession = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _error = null);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(
            email: _email.text.trim(),
            password: _password.text,
            rememberSession: _rememberSession,
          );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final busy = auth.isLoading;
    return AuthShell(
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.15,
                ),
              ).animate().fadeIn(duration: 320.ms).slideY(begin: .12, end: 0),
              const SizedBox(height: 9),
              Text(
                'Sign in with the email assigned to your SiteSeva workspace. Your access is configured by your organisation.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.muted,
                  height: 1.55,
                ),
              ).animate(delay: 60.ms).fadeIn(duration: 320.ms),
              const SizedBox(height: 30),
              if (_error != null) ...[
                AuthErrorBanner(message: _error!),
                const SizedBox(height: 16),
              ],
              TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [
                      AutofillHints.username,
                      AutofillHints.email,
                    ],
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Work email',
                      hintText: 'you@company.com',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      return email.contains('@') && email.contains('.')
                          ? null
                          : 'Enter a valid work email';
                    },
                  )
                  .animate(delay: 110.ms)
                  .fadeIn(duration: 320.ms)
                  .slideY(begin: .08, end: 0),
              const SizedBox(height: 14),
              TextFormField(
                    controller: _password,
                    obscureText: !_showPassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        tooltip: _showPassword
                            ? 'Hide password'
                            : 'Show password',
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    validator: (value) => (value?.isNotEmpty ?? false)
                        ? null
                        : 'Enter your password',
                    onFieldSubmitted: busy ? null : (_) => _submit(),
                  )
                  .animate(delay: 160.ms)
                  .fadeIn(duration: 320.ms)
                  .slideY(begin: .08, end: 0),
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: busy
                    ? null
                    : () =>
                          setState(() => _rememberSession = !_rememberSession),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      SizedBox.square(
                        dimension: 28,
                        child: Checkbox(
                          value: _rememberSession,
                          onChanged: busy
                              ? null
                              : (value) => setState(
                                  () => _rememberSession = value ?? true,
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Keep me signed in on this device',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              AuthPrimaryButton(
                label: busy ? 'Verifying workspace...' : 'Sign in securely',
                icon: Icons.arrow_forward_rounded,
                loading: busy,
                onPressed: busy ? null : _submit,
              ).animate(delay: 210.ms).fadeIn(duration: 320.ms),
              const SizedBox(height: 26),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.orange.withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.orange.withValues(alpha: .14),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: AppTheme.orange,
                      size: 19,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Contractor, supervisor and client access is assigned by the server after sign-in.',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.muted,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Setting up a company?',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                  ),
                  TextButton(
                    onPressed: busy ? null : () => context.push('/apply'),
                    child: const Text('Apply for access'),
                  ),
                ],
              ),
              Center(
                child: Text(
                  'Password recovery, OTP and social sign-in will appear only when enabled by your SiteSeva backend.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.muted,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
