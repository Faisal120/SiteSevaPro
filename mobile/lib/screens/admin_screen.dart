import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../widgets/common.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key, required this.api});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    const modules = [
      _AdminModule(
        'Applications',
        '/admin/applications',
        Icons.assignment_ind_rounded,
      ),
      _AdminModule('Contractors', '/admin/contractors', Icons.business_rounded),
      _AdminModule(
        'Supervisors',
        '/admin/supervisors',
        Icons.engineering_rounded,
      ),
      _AdminModule(
        'Subscriptions',
        '/admin/subscriptions',
        Icons.workspace_premium_rounded,
      ),
      _AdminModule('UPI payments', '/admin/payments', Icons.verified_rounded),
      _AdminModule(
        'Design credits',
        '/design-wallet/purchase/admin',
        Icons.toll_rounded,
      ),
      _AdminModule('Audit log', '/admin/audit', Icons.policy_rounded),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text(
          'Platform control',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Accounts, approvals, payments aur subscriptions',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        for (final module in modules)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              color: Colors.white,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                leading: CircleAvatar(child: Icon(module.icon)),
                title: Text(
                  module.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _AdminDataScreen(api: api, module: module),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AdminModule {
  const _AdminModule(this.title, this.endpoint, this.icon);

  final String title;
  final String endpoint;
  final IconData icon;
}

class _AdminDataScreen extends StatefulWidget {
  const _AdminDataScreen({required this.api, required this.module});

  final ApiClient api;
  final _AdminModule module;

  @override
  State<_AdminDataScreen> createState() => _AdminDataScreenState();
}

class _AdminDataScreenState extends State<_AdminDataScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];
  String? _workingId;

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
      final data = await widget.api.get(widget.module.endpoint);
      if (mounted) setState(() => _items = asList(data));
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Admin data load nahi ho paaya.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _action(
    Map<String, dynamic> record,
    String path, {
    String method = 'POST',
    String success = 'Updated',
  }) async {
    final id = record['id']?.toString() ?? '';
    setState(() => _workingId = id);
    try {
      final result = method == 'PUT'
          ? await widget.api.put(path)
          : await widget.api.post(path);
      if (!mounted) return;
      final credentials = result is Map && result['password'] != null
          ? '\nLogin: ${result['email'] ?? result['username']}\nPassword: ${result['password']}'
          : '';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$success$credentials')));
      await _load();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _workingId = null);
    }
  }

  List<Widget> _actions(Map<String, dynamic> record) {
    final id = record['id']?.toString();
    if (id == null || _workingId == id) {
      return _workingId == id
          ? [
              const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(),
              ),
            ]
          : [];
    }
    if (widget.module.endpoint == '/admin/applications' &&
        record['status']?.toString() == 'PENDING') {
      return [
        FilledButton.icon(
          onPressed: () => _action(
            record,
            '/admin/applications/$id/approve',
            success: 'Application approved',
          ),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Approve'),
        ),
        OutlinedButton(
          onPressed: () => _action(
            record,
            '/admin/applications/$id/reject',
            success: 'Application rejected',
          ),
          child: const Text('Reject'),
        ),
      ];
    }
    if (widget.module.endpoint == '/admin/contractors') {
      final blocked = record['blocked'] == true;
      return [
        OutlinedButton.icon(
          onPressed: () => _action(
            record,
            '/admin/contractors/$id/block?blocked=${!blocked}',
            success: blocked ? 'Contractor unblocked' : 'Contractor blocked',
          ),
          icon: Icon(blocked ? Icons.lock_open_rounded : Icons.block_rounded),
          label: Text(blocked ? 'Unblock' : 'Block'),
        ),
      ];
    }
    if (widget.module.endpoint == '/admin/payments' &&
        record['status']?.toString() == 'PENDING') {
      return [
        FilledButton(
          onPressed: () => _action(
            record,
            '/admin/payments/$id/approve',
            success: 'Payment approved',
          ),
          child: const Text('Approve'),
        ),
        OutlinedButton(
          onPressed: () => _action(
            record,
            '/admin/payments/$id/reject',
            success: 'Payment rejected',
          ),
          child: const Text('Reject'),
        ),
      ];
    }
    if (widget.module.endpoint == '/design-wallet/purchase/admin' &&
        record['status']?.toString() == 'PENDING') {
      return [
        FilledButton(
          onPressed: () => _action(
            record,
            '/design-wallet/purchase/$id/approve',
            success: 'Credits approved',
          ),
          child: const Text('Approve'),
        ),
        OutlinedButton(
          onPressed: () => _action(
            record,
            '/design-wallet/purchase/$id/reject',
            success: 'Request rejected',
          ),
          child: const Text('Reject'),
        ),
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.module.title)),
    body: _loading
        ? const LoadingView()
        : _error != null
        ? ErrorView(message: _error!, onRetry: _load)
        : _items.isEmpty
        ? EmptyView(message: '${widget.module.title} data abhi nahi hai.')
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final item = Map<String, dynamic>.from(_items[index] as Map);
                return RecordCard(record: item, actions: _actions(item));
              },
            ),
          ),
  );
}
