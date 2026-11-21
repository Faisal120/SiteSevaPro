import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../widgets/common.dart';

class SitesScreen extends StatefulWidget {
  const SitesScreen({super.key, required this.api, required this.canCreate});

  final ApiClient api;
  final bool canCreate;

  @override
  State<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends State<SitesScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _sites = [];

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
      final payload = await widget.api.get('/sites');
      if (mounted) setState(() => _sites = asList(payload));
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Sites load nahi ho paaye.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addSite() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => CreateSiteDialog(api: widget.api),
    );
    if (created == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const LoadingView()
        : _error != null
        ? ErrorView(message: _error!, onRetry: _load)
        : _sites.isEmpty
        ? const EmptyView(
            message: 'Abhi koi site nahi hai. Pehli site create karein.',
            icon: Icons.apartment_rounded,
          )
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: _sites.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final site = Map<String, dynamic>.from(_sites[index] as Map);
                return Card(
                  color: Colors.white,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SiteDetailScreen(
                          api: widget.api,
                          siteId: site['id'].toString(),
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  site['name']?.toString() ?? 'Site',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              Chip(
                                label: Text(
                                  site['status']?.toString() ?? 'ACTIVE',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            site['location']?.toString() ?? 'Location not set',
                          ),
                          const SizedBox(height: 14),
                          LinearProgressIndicator(
                            value:
                                ((site['progress'] as num?)?.toDouble() ?? 0) /
                                100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          const SizedBox(height: 6),
                          Text('${site['progress'] ?? 0}% complete'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );

    return Stack(
      children: [
        Positioned.fill(child: body),
        if (widget.canCreate)
          Positioned(
            right: 18,
            bottom: 18,
            child: FloatingActionButton.extended(
              heroTag: 'add-site',
              onPressed: _addSite,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New site'),
            ),
          ),
      ],
    );
  }
}

class SiteDetailScreen extends StatefulWidget {
  const SiteDetailScreen({super.key, required this.api, required this.siteId});

  final ApiClient api;
  final String siteId;

  @override
  State<SiteDetailScreen> createState() => _SiteDetailScreenState();
}

class _SiteDetailScreenState extends State<SiteDetailScreen> {
  Map<String, dynamic>? _site;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final payload = await widget.api.get('/sites/${widget.siteId}');
      if (mounted) {
        setState(() => _site = Map<String, dynamic>.from(payload as Map));
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_site?['name']?.toString() ?? 'Site details')),
      body: _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : _site == null
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                RecordCard(record: _site!),
                const SizedBox(height: 20),
                Text(
                  'Site modules',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: MediaQuery.sizeOf(context).width > 600
                      ? 3
                      : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.5,
                  children: [
                    _SiteModule(
                      icon: Icons.groups_rounded,
                      title: 'Labour',
                      onTap: () => _openModule('Labour', '/labour'),
                    ),
                    _SiteModule(
                      icon: Icons.inventory_2_rounded,
                      title: 'Materials',
                      onTap: () => _openModule('Materials', '/materials'),
                    ),
                    _SiteModule(
                      icon: Icons.payments_rounded,
                      title: 'Payments',
                      onTap: () => _openModule('Payments', '/payments'),
                    ),
                    _SiteModule(
                      icon: Icons.receipt_long_rounded,
                      title: 'Reports',
                      onTap: () => _openModule('Reports', '/reports'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  void _openModule(String title, String endpoint) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _SiteRecordsScreen(
          api: widget.api,
          title: title,
          endpoint: endpoint,
          siteId: widget.siteId,
        ),
      ),
    );
  }
}

class _SiteModule extends StatelessWidget {
  const _SiteModule({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    child: InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    ),
  );
}

class _SiteRecordsScreen extends StatefulWidget {
  const _SiteRecordsScreen({
    required this.api,
    required this.title,
    required this.endpoint,
    required this.siteId,
  });

  final ApiClient api;
  final String title;
  final String endpoint;
  final String siteId;

  @override
  State<_SiteRecordsScreen> createState() => _SiteRecordsScreenState();
}

class _SiteRecordsScreenState extends State<_SiteRecordsScreen> {
  List<dynamic>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.api.get(
        widget.endpoint,
        query: {'site_id': widget.siteId},
      );
      if (mounted) setState(() => _items = asList(data));
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: _error != null
        ? ErrorView(message: _error!, onRetry: _load)
        : _items == null
        ? const LoadingView()
        : _items!.isEmpty
        ? EmptyView(message: '${widget.title} data abhi nahi hai.')
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items!.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, index) => RecordCard(
                record: Map<String, dynamic>.from(_items![index] as Map),
              ),
            ),
          ),
  );
}

class CreateSiteDialog extends StatefulWidget {
  const CreateSiteDialog({super.key, required this.api});

  final ApiClient api;

  @override
  State<CreateSiteDialog> createState() => _CreateSiteDialogState();
}

class _CreateSiteDialogState extends State<CreateSiteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _budget = TextEditingController();
  final _description = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _budget.dispose();
    _description.dispose();
    super.dispose();
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final now = DateTime.now();
      await widget.api.post(
        '/sites',
        body: {
          'name': _name.text.trim(),
          'location': _location.text.trim(),
          'budget': double.parse(_budget.text),
          'description': _description.text.trim(),
          'start_date': _date(now),
          'end_date': _date(DateTime(now.year + 1, now.month, now.day)),
          'floors': 1,
          'status': 'ACTIVE',
          'progress': 0,
        },
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Create site'),
    content: SizedBox(
      width: 460,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_name, 'Site name'),
              _field(_location, 'Location'),
              _field(_budget, 'Budget', numeric: true),
              _field(_description, 'Description', required: false),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _busy ? null : _submit,
        child: Text(_busy ? 'Creating…' : 'Create'),
      ),
    ],
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool numeric = false,
    bool required = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return 'Required';
        }
        if (numeric && double.tryParse(value ?? '') == null) {
          return 'Valid number enter karein';
        }
        return null;
      },
    ),
  );
}
