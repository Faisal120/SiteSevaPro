import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../widgets/common.dart';

class GenericCollectionScreen extends StatefulWidget {
  const GenericCollectionScreen({
    super.key,
    required this.api,
    required this.title,
    required this.endpoint,
    this.query,
    this.emptyMessage,
  });

  final ApiClient api;
  final String title;
  final String endpoint;
  final Map<String, String>? query;
  final String? emptyMessage;

  @override
  State<GenericCollectionScreen> createState() =>
      _GenericCollectionScreenState();
}

class _GenericCollectionScreenState extends State<GenericCollectionScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];

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
      final payload = await widget.api.get(
        widget.endpoint,
        query: widget.query,
      );
      if (mounted) setState(() => _items = asList(payload));
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Data load nahi ho paaya.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _loading
          ? const LoadingView()
          : _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : _items.isEmpty
          ? EmptyView(
              message:
                  widget.emptyMessage ?? '${widget.title} data abhi nahi hai.',
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return RecordCard(
                    record: item is Map
                        ? Map<String, dynamic>.from(item)
                        : {'value': item},
                  );
                },
              ),
            ),
    );
  }
}
