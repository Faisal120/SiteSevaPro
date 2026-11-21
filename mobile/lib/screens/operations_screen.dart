import 'package:flutter/material.dart';

import '../core/api_client.dart';
import 'generic_collection_screen.dart';

class OperationsScreen extends StatelessWidget {
  const OperationsScreen({super.key, required this.api, required this.role});

  final ApiClient api;
  final String role;

  @override
  Widget build(BuildContext context) {
    final modules = <_Module>[
      const _Module('Labour', '/labour', Icons.groups_rounded),
      const _Module('Materials', '/materials', Icons.inventory_2_rounded),
      const _Module('Payments', '/payments', Icons.payments_rounded),
      const _Module('Expenses', '/expenses', Icons.receipt_long_rounded),
      const _Module('Daily reports', '/reports', Icons.summarize_rounded),
      const _Module('Documents', '/documents', Icons.folder_copy_rounded),
      const _Module(
        'Notifications',
        '/notifications',
        Icons.notifications_rounded,
      ),
      const _Module(
        'Plans',
        '/subscription/plans',
        Icons.workspace_premium_rounded,
      ),
      if (role == 'CONTRACTOR') ...[
        const _Module('Team', '/team', Icons.supervisor_account_rounded),
        const _Module('Vendors', '/vendors', Icons.storefront_rounded),
        const _Module('Estimates', '/estimates', Icons.calculate_rounded),
        const _Module('BOQ', '/boq', Icons.table_chart_rounded),
        const _Module('Designs', '/design', Icons.architecture_rounded),
        const _Module('CRM', '/crm/overview', Icons.handshake_rounded),
        const _Module(
          'Planning',
          '/planning/overview',
          Icons.calendar_month_rounded,
        ),
      ],
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text(
          'Operations',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Daily construction workflow aur records',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 230,
            mainAxisExtent: 132,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: modules.length,
          itemBuilder: (context, index) {
            final module = modules[index];
            return Card(
              color: Colors.white,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => GenericCollectionScreen(
                      api: api,
                      title: module.title,
                      endpoint: module.endpoint,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        module.icon,
                        color: Theme.of(context).colorScheme.primary,
                        size: 30,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        module.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Module {
  const _Module(this.title, this.endpoint, this.icon);

  final String title;
  final String endpoint;
  final IconData icon;
}
