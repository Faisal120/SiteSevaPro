import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_file_share.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/document_models.dart';
import '../../providers/document_provider.dart';
import '../../../sites/models/site_models.dart';
import '../widgets/document_widgets.dart';

class DocumentCenterScreen extends ConsumerWidget {
  const DocumentCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final state = ref.watch(documentControllerProvider);
    if (user == null) return const SizedBox.shrink();
    return state.when(
      loading: () => const _DocumentLoadingView(),
      error: (error, stackTrace) => _DocumentErrorView(
        error: error,
        onRetry: () => ref.read(documentControllerProvider.notifier).load(),
      ),
      data: (data) => _DocumentWorkspace(user: user, data: data),
    );
  }
}

class _DocumentWorkspace extends ConsumerWidget {
  const _DocumentWorkspace({required this.user, required this.data});

  final AuthUser user;
  final DocumentsWorkspaceData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = DocumentPermissions(role: user.role);
    final action = ref.watch(documentActionControllerProvider);
    final controller = ref.read(documentControllerProvider.notifier);
    return AppPage(
      title: 'Document Center',
      subtitle: 'One trusted file room for every project decision.',
      actions: [
        IconButton(
          tooltip: 'Refresh documents',
          onPressed: action.isLoading ? null : controller.refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
        if (permissions.canUpload && data.apiAvailable)
          FilledButton.icon(
            onPressed: action.isLoading
                ? null
                : () => _openUpload(context, ref, data),
            icon: const Icon(Icons.upload_file_rounded, size: 18),
            label: const Text('Upload'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 46),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
          ),
      ],
      child: RefreshIndicator(
        color: AppTheme.orange,
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
          children: [
            DocumentHeroCard(
              role: user.role,
              apiAvailable: data.apiAvailable,
              canUpload: permissions.canUpload,
              onUpload: () => _openUpload(context, ref, data),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: .05, end: 0),
            if (data.isOffline) ...[
              const SizedBox(height: 14),
              DocumentOfflineBanner(cachedAt: data.fetchedAt),
            ],
            const SizedBox(height: 18),
            if (!data.apiAvailable) ...[
              DocumentApiNotice(
                message: data.apiMessage ?? 'Document API is not available.',
                onRetry: controller.load,
              ),
              const SizedBox(height: 18),
            ],
            DocumentMetricStrip(metrics: data.metrics),
            const SizedBox(height: 20),
            DocumentKindChips(
              selected: data.kind,
              onChanged: controller.setKind,
            ),
            const SizedBox(height: 13),
            LayoutBuilder(
              builder: (context, constraints) {
                final siteFilter = DocumentSiteFilter(
                  sites: data.sites,
                  selected: data.siteId,
                  onChanged: controller.setSite,
                );
                final search = TextFormField(
                  key: const ValueKey('document-search'),
                  initialValue: data.query,
                  onChanged: controller.setQuery,
                  decoration: const InputDecoration(
                    hintText: 'Search files, projects or uploaded by',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                );
                if (constraints.maxWidth < 700) {
                  return Column(
                    children: [siteFilter, const SizedBox(height: 12), search],
                  );
                }
                return Row(
                  children: [
                    Expanded(flex: 2, child: siteFilter),
                    const SizedBox(width: 12),
                    Expanded(flex: 3, child: search),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            if (data.visibleDocuments.isEmpty)
              DocumentEmptyState(
                apiAvailable: data.apiAvailable,
                canUpload: permissions.canUpload,
                onUpload: () => _openUpload(context, ref, data),
              )
            else
              ...data.visibleDocuments.indexed.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DocumentRecordCard(
                    document: entry.$2,
                    onOpen: () => _openDetails(context, ref, entry.$2, permissions),
                  ).animate(delay: (entry.$1.clamp(0, 8) * 42).ms).fadeIn(
                    duration: 220.ms,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUpload(
    BuildContext context,
    WidgetRef ref,
    DocumentsWorkspaceData data,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) => DocumentUploadSheet(
        sites: data.sites,
        canShare: DocumentPermissions(role: user.role).canShare,
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Files uploaded to the project workspace.')),
      );
    }
  }

  Future<void> _openDetails(
    BuildContext context,
    WidgetRef ref,
    DocumentRecord document,
    DocumentPermissions permissions,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) => DocumentDetailsSheet(
        document: document,
        canDelete: permissions.canDelete,
        canShare: permissions.canShare,
        onDownload: () => _download(context, ref, document),
        onToggleSharing: () => _toggleSharing(context, ref, document),
        onDelete: () => _delete(context, ref, document),
      ),
    );
  }

  Future<void> _download(
    BuildContext context,
    WidgetRef ref,
    DocumentRecord document,
  ) async {
    final bytes = await ref
        .read(documentActionControllerProvider.notifier)
        .download(document);
    if (!context.mounted) return;
    if (bytes == null) {
      _showActionError(context, ref, 'Could not download this file.');
      return;
    }
    await AppFileShare.bytes(
      bytes: bytes,
      fileName: document.fileLabel,
      mimeType: document.mimeType.isEmpty
          ? 'application/octet-stream'
          : document.mimeType,
      subject: document.name,
    );
  }

  Future<void> _toggleSharing(
    BuildContext context,
    WidgetRef ref,
    DocumentRecord document,
  ) async {
    final changed = await ref
        .read(documentActionControllerProvider.notifier)
        .updateSharing(document.id, !document.sharedWithClient);
    if (!changed && context.mounted) {
      _showActionError(context, ref, 'Sharing settings could not be updated.');
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    DocumentRecord document,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete file?'),
        content: Text('Remove “${document.name}” from the project workspace?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await ref
        .read(documentActionControllerProvider.notifier)
        .delete(document.id);
    if (!context.mounted) return;
    if (deleted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File deleted.')),
      );
    } else {
      _showActionError(context, ref, 'Could not delete this file.');
    }
  }

  void _showActionError(BuildContext context, WidgetRef ref, String fallback) {
    final error = ref.read(documentActionControllerProvider).value.error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error?.toString() ?? fallback)),
    );
  }
}

class DocumentDetailsSheet extends StatelessWidget {
  const DocumentDetailsSheet({
    super.key,
    required this.document,
    required this.canDelete,
    required this.canShare,
    required this.onDownload,
    required this.onToggleSharing,
    required this.onDelete,
  });

  final DocumentRecord document;
  final bool canDelete;
  final bool canShare;
  final VoidCallback onDownload;
  final VoidCallback onToggleSharing;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.line,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            DocumentThumbnail(document: document),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    document.kind.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (document.description?.isNotEmpty == true) ...[
          const SizedBox(height: 18),
          Text(
            document.description!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.muted,
              height: 1.45,
            ),
          ),
        ],
        const SizedBox(height: 18),
        _DetailLine(label: 'Project', value: document.siteName.isEmpty ? 'Company workspace' : document.siteName),
        _DetailLine(label: 'File', value: document.fileLabel),
        _DetailLine(label: 'Size', value: document.sizeLabel),
        _DetailLine(label: 'Uploaded', value: appDate(document.createdAt)),
        if (document.createdBy.isNotEmpty)
          _DetailLine(label: 'Uploaded by', value: document.createdBy),
        const SizedBox(height: 18),
        if (document.isImage && document.url.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                document.url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Text('Preview unavailable'),
                ),
              ),
            ),
          ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onDownload,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download and share'),
          ),
        ),
        if (canShare)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onToggleSharing,
              icon: Icon(
                document.sharedWithClient
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              label: Text(
                document.sharedWithClient
                    ? 'Remove client access'
                    : 'Share with client',
              ),
            ),
          ),
        if (canDelete)
          TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete file'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
          ),
      ],
    ),
  );
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(
          width: 80,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class DocumentUploadSheet extends ConsumerStatefulWidget {
  const DocumentUploadSheet({
    super.key,
    required this.sites,
    required this.canShare,
  });

  final List<SiteSummary> sites;
  final bool canShare;

  @override
  ConsumerState<DocumentUploadSheet> createState() =>
      _DocumentUploadSheetState();
}

class _DocumentUploadSheetState extends ConsumerState<DocumentUploadSheet> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<DocumentFileAsset> _assets = const [];
  DocumentKind _kind = DocumentKind.other;
  String? _siteId;
  bool _sharedWithClient = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(documentActionControllerProvider);
    final actionError = action.value.hasError ? '${action.value.error}' : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Upload project files',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Files are uploaded securely and registered against the selected project.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.muted,
              ),
            ),
            if (_error != null || actionError != null) ...[
              const SizedBox(height: 12),
              Text(
                _error ?? actionError!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.danger,
                ),
              ),
            ],
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 16, bottom: 14),
                child: Column(
                  children: [
                    _field(_name, 'File name (optional)'),
                    DropdownButtonFormField<DocumentKind>(
                      initialValue: _kind,
                      decoration: const InputDecoration(labelText: 'File type'),
                      items: DocumentKind.values
                          .map(
                            (kind) => DropdownMenuItem(
                              value: kind,
                              child: Text(kind.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _kind = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _siteId ?? '',
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Project'),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('Company workspace'),
                        ),
                        ...widget.sites.map(
                          (site) => DropdownMenuItem(
                            value: site.id,
                            child: Text(site.name),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(
                        () => _siteId = value == null || value.isEmpty ? null : value,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _field(_description, 'Description (optional)', maxLines: 3),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: action.isLoading ? null : _pickFiles,
                      icon: const Icon(Icons.attach_file_rounded),
                      label: Text(
                        _assets.isEmpty
                            ? 'Choose files'
                            : '${_assets.length} file${_assets.length == 1 ? '' : 's'} selected',
                      ),
                    ),
                    if (_assets.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _assets
                              .map(
                                (asset) => Chip(
                                  avatar: Icon(
                                    documentKindIcon(_kind),
                                    size: 16,
                                  ),
                                  label: Text(
                                    asset.filename,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                    if (widget.canShare)
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _sharedWithClient,
                        onChanged: (value) =>
                            setState(() => _sharedWithClient = value),
                        title: const Text('Share with client'),
                        subtitle: const Text('Make this file visible in the client workspace.'),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: action.isLoading ? null : _submit,
                icon: action.isLoading
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_outlined, size: 18),
                label: Text(action.isLoading ? 'Uploading...' : 'Upload files'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
    ),
  );

  Future<void> _pickFiles() async {
    final assets = await ref.read(documentFilePickerProvider).pickFiles();
    if (!mounted) return;
    setState(() {
      _assets = assets;
      _error = assets.isEmpty ? 'Choose at least one supported file.' : null;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_assets.isEmpty) {
      setState(() => _error = 'Choose at least one supported file.');
      return;
    }
    setState(() => _error = null);
    var uploaded = 0;
    for (final asset in _assets) {
      final name = _name.text.trim().isEmpty
          ? _withoutExtension(asset.filename)
          : _name.text.trim();
      final saved = await ref
          .read(documentActionControllerProvider.notifier)
          .upload(
            asset,
            DocumentUploadInput(
              name: name,
              kind: _kind,
              siteId: _siteId ?? '',
              description: _description.text,
              sharedWithClient: widget.canShare && _sharedWithClient,
            ),
          );
      if (!saved) {
        if (mounted) {
          setState(
            () => _error =
                '${ref.read(documentActionControllerProvider).value.error ?? 'Upload failed.'}',
          );
        }
        break;
      }
      uploaded++;
    }
    if (uploaded > 0 && mounted) Navigator.of(context).pop(true);
  }
}

class _DocumentLoadingView extends StatelessWidget {
  const _DocumentLoadingView();

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Document Center',
    subtitle: 'Loading project file room...',
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      children: const [
        AppSkeleton(height: 240, radius: 30),
        SizedBox(height: 16),
        AppSkeleton(height: 92, radius: 22),
        SizedBox(height: 14),
        AppSkeleton(height: 52, radius: 18),
        SizedBox(height: 12),
        AppSkeleton(height: 96, radius: 24),
      ],
    ),
  );
}

class _DocumentErrorView extends StatelessWidget {
  const _DocumentErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Document Center',
    subtitle: 'Project file room',
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      children: [
        EmptyPanel(
          title: 'Document Center unavailable',
          message: '$error',
          icon: Icons.cloud_off_rounded,
          actionLabel: 'Reconnect',
          onAction: onRetry,
        ),
      ],
    ),
  );
}

String _withoutExtension(String filename) {
  final dot = filename.lastIndexOf('.');
  return dot > 0 ? filename.substring(0, dot) : filename;
}
