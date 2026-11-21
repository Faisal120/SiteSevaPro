import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.api,
    required this.role,
    required this.user,
  });

  final ApiClient api;
  final String role;
  final Map<String, dynamic> user;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final endpoint = widget.role == 'SUPER_ADMIN'
          ? '/admin/dashboard'
          : '/dashboard';
      final payload = await widget.api.get(endpoint);
      if (mounted) {
        setState(() {
          _data = payload is Map
              ? Map<String, dynamic>.from(payload)
              : {'data': payload};
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Dashboard load nahi ho paaya.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MapEntry<String, dynamic>> get _metrics {
    return _data.entries
        .where(
          (entry) =>
              entry.value is num ||
              entry.value is String ||
              entry.value is bool,
        )
        .take(10)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);

    final name =
        widget.user['full_name']?.toString().split(' ').first ?? 'User';
    final color = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.primary, const Color(0xFF16463C)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Namaste, $name',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.user['company_name']?.toString() ??
                      prettyLabel(widget.role),
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Overview',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (_metrics.isEmpty)
            const EmptyView(
              message: 'Dashboard metrics abhi available nahi hain.',
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 240,
                mainAxisExtent: 116,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _metrics.length,
              itemBuilder: (context, index) {
                final metric = _metrics[index];
                return Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          displayValue(metric.value),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: color.primary,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          prettyLabel(metric.key),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: color.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          if (_data.entries.any((entry) => entry.value is List)) ...[
            const SizedBox(height: 24),
            Text(
              'Recent activity',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final entry in _data.entries.where(
              (entry) => entry.value is List,
            ))
              _ListSection(
                title: prettyLabel(entry.key),
                values: entry.value as List,
              ),
          ],
        ],
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  const _ListSection({required this.title, required this.values});

  final String title;
  final List values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: Colors.white,
        child: ExpansionTile(
          title: Text('$title (${values.length})'),
          children: values
              .take(5)
              .map(
                (value) => ListTile(
                  dense: true,
                  title: Text(
                    value is Map
                        ? displayValue(value['name'] ?? value['month'] ?? value)
                        : displayValue(value),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
