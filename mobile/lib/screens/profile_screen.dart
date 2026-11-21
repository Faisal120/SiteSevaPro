import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final user = controller.user ?? {};
    final name = user['full_name']?.toString() ?? 'User';
    final initial = name.isEmpty ? 'U' : name[0].toUpperCase();
    return RefreshIndicator(
      onRefresh: controller.refreshUser,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: Text(
                      initial,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(user['email']?.toString() ?? ''),
                  const SizedBox(height: 10),
                  Chip(label: Text(prettyLabel(controller.role))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.white,
            child: Column(
              children: [
                _ProfileRow(label: 'Company', value: user['company_name']),
                _ProfileRow(label: 'Plan', value: user['plan'] ?? 'FREE'),
                _ProfileRow(label: 'Username', value: user['username']),
                _ProfileRow(
                  label: 'Assigned sites',
                  value: user['site_ids'] is List
                      ? (user['site_ids'] as List).length
                      : 0,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: controller.logout,
            icon: const Icon(Icons.logout_rounded),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Sign out'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Connected to ${controller.api.baseUrl}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(label),
    trailing: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Text(
        displayValue(value),
        textAlign: TextAlign.right,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  );
}
