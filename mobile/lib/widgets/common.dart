import 'dart:convert';

import 'package:flutter/material.dart';

String prettyLabel(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String displayValue(dynamic value) {
  if (value == null) return '—';
  if (value is bool) return value ? 'Yes' : 'No';
  if (value is num) {
    if (value is double && value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
  if (value is List) return value.isEmpty ? '—' : value.join(', ');
  if (value is Map) return jsonEncode(value);
  final text = value.toString();
  return text.length > 120 ? '${text.substring(0, 117)}…' : text;
}

List<dynamic> asList(dynamic payload) {
  if (payload is List) return payload;
  if (payload is Map) {
    for (final key in ['items', 'data', 'results', 'notifications']) {
      if (payload[key] is List) return payload[key] as List;
    }
    for (final value in payload.values) {
      if (value is List) return value;
    }
  }
  return payload == null ? [] : [payload];
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

class RecordCard extends StatelessWidget {
  const RecordCard({super.key, required this.record, this.actions = const []});

  final Map<String, dynamic> record;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    const preferred = [
      'name',
      'full_name',
      'company_name',
      'title',
      'email',
      'status',
      'role',
      'location',
      'trade',
      'amount',
      'plan',
      'created_at',
    ];
    final entries = <MapEntry<String, dynamic>>[];
    for (final key in preferred) {
      if (record[key] != null) entries.add(MapEntry(key, record[key]));
    }
    for (final entry in record.entries) {
      if (entries.length >= 6) break;
      if (!preferred.contains(entry.key) &&
          entry.key != 'id' &&
          !entry.key.startsWith('_') &&
          entry.value != null) {
        entries.add(entry);
      }
    }
    final title =
        record['name'] ??
        record['full_name'] ??
        record['company_name'] ??
        record['title'] ??
        record['email'] ??
        'Record';

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toString(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            for (final entry in entries.where((e) => e.value != title))
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 112,
                      child: Text(
                        prettyLabel(entry.key),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                    Expanded(child: Text(displayValue(entry.value))),
                  ],
                ),
              ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}
