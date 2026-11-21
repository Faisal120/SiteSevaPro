import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/workforce_models.dart';
import '../../providers/workforce_provider.dart';

Future<String?> showWorkforceCreationSheet(
  BuildContext context,
  WidgetRef ref, {
  required WorkforceStudioData data,
}) {
  ref.read(workforceCreationBriefProvider.notifier).reset();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _WorkforceCreationSheet(data: data),
  );
}

class _WorkforceCreationSheet extends ConsumerWidget {
  const _WorkforceCreationSheet({required this.data});
  final WorkforceStudioData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brief = ref.watch(workforceCreationBriefProvider);
    final action = ref.watch(workforceActionControllerProvider);
    final editor = ref.read(workforceCreationBriefProvider.notifier);
    return FractionallySizedBox(
      heightFactor: .94,
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
                    children: [
                      _CreationHeader(
                        busy: action.isLoading,
                        onClose: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        enabled: !action.isLoading,
                        onChanged: editor.setName,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          hintText: 'Ramesh Kumar',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 13),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final mobile = TextField(
                            enabled: !action.isLoading,
                            onChanged: editor.setMobile,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Mobile (optional)',
                              hintText: '9876543210',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          );
                          final trade = TextField(
                            enabled: !action.isLoading,
                            onChanged: editor.setTrade,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Trade',
                              hintText: 'Mason',
                              prefixIcon: Icon(Icons.handyman_outlined),
                            ),
                          );
                          if (constraints.maxWidth >= 560) {
                            return Row(
                              children: [
                                Expanded(child: mobile),
                                const SizedBox(width: 12),
                                Expanded(child: trade),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              mobile,
                              const SizedBox(height: 13),
                              trade,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 13),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wage = TextField(
                            enabled: !action.isLoading,
                            onChanged: editor.setWage,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Daily wage',
                              hintText: '850',
                              prefixText: 'INR  ',
                              prefixIcon: Icon(Icons.payments_outlined),
                            ),
                          );
                          final site = DropdownButtonFormField<String>(
                            key: ValueKey('member-site-${brief.siteId}'),
                            initialValue: brief.siteId.isEmpty
                                ? null
                                : brief.siteId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Assigned project',
                              prefixIcon: Icon(Icons.apartment_rounded),
                            ),
                            hint: const Text('Choose project'),
                            items: data.sites
                                .map(
                                  (site) => DropdownMenuItem(
                                    value: site.id,
                                    child: Text(
                                      site.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: action.isLoading
                                ? null
                                : (value) {
                                    if (value != null) editor.setSite(value);
                                  },
                          );
                          if (constraints.maxWidth >= 560) {
                            return Row(
                              children: [
                                Expanded(child: wage),
                                const SizedBox(width: 12),
                                Expanded(child: site),
                              ],
                            );
                          }
                          return Column(
                            children: [wage, const SizedBox(height: 13), site],
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Optional identity and contact context',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Only collect identifiers required by your company policy.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        enabled: !action.isLoading,
                        onChanged: editor.setAadhaar,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Aadhaar (optional)',
                          hintText: '12-digit identifier',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 13),
                      TextField(
                        enabled: !action.isLoading,
                        onChanged: editor.setAddress,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Address (optional)',
                          prefixIcon: Icon(Icons.home_work_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _PrivacyNotice(),
                      if (action.hasError) ...[
                        const SizedBox(height: 13),
                        _ActionError(error: action.error!),
                      ],
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: action.isLoading || data.sites.isEmpty
                            ? null
                            : () => _submit(context, ref, brief),
                        icon: action.isLoading
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.person_add_alt_1_rounded),
                        label: Text(
                          action.isLoading
                              ? 'Creating profile...'
                              : 'Create workforce profile',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    WorkforceCreationBrief brief,
  ) async {
    final validation = brief.validationMessage;
    if (validation != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validation)));
      return;
    }
    final member = await ref
        .read(workforceActionControllerProvider.notifier)
        .create(brief);
    if (member != null && context.mounted) {
      Navigator.pop(context, member.id);
    }
  }
}

class _CreationHeader extends StatelessWidget {
  const _CreationHeader({required this.busy, required this.onClose});
  final bool busy;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF173A5E), Color(0xFF2B648C)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.engineering_rounded, color: Colors.white),
      ),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add workforce member',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              'Create one wage-ready project profile.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Close',
        onPressed: busy ? null : onClose,
        icon: const Icon(Icons.close_rounded),
      ),
    ],
  );
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.blue.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.blue.withValues(alpha: .16)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.privacy_tip_outlined, color: AppTheme.blue, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'The current API accepts identity fields but does not expose verification, encryption status or document consent metadata. Optional identifiers remain hidden throughout the app.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.muted,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ActionError extends StatelessWidget {
  const _ActionError({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    final message = error is ApiException
        ? (error as ApiException).message
        : '$error';
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.danger),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
