import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/document_models.dart';
import '../../../sites/models/site_models.dart';

class DocumentHeroCard extends StatelessWidget {
  const DocumentHeroCard({
    super.key,
    required this.role,
    required this.apiAvailable,
    required this.canUpload,
    required this.onUpload,
  });

  final String role;
  final bool apiAvailable;
  final bool canUpload;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final label = role.toUpperCase() == 'CLIENT'
        ? 'PROJECT FILE ROOM'
        : role.toUpperCase() == 'SUPERVISOR'
        ? 'FIELD DOCUMENT CONTROL'
        : 'PROJECT DOCUMENT CENTER';
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 19),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF080F1D), Color(0xFF0E396B), Color(0xFF1E73D8)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260A2D5A),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -52,
            top: -62,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: .08),
                  width: 30,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Every project file, one trusted workspace.',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.7,
                  height: 1.13,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                apiAvailable
                    ? 'Keep drawings, commercial files, evidence and approvals connected to the right project.'
                    : 'Document Center is ready, but the connected FastAPI service has not enabled document routes yet.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: .72),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              if (canUpload && apiAvailable)
                _HeroAction(onTap: onUpload)
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .12),
                    ),
                  ),
                  child: Text(
                    apiAvailable
                        ? 'Read-only workspace'
                        : 'Awaiting Document API',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Upload files',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.upload_file_rounded, color: AppTheme.ink, size: 16),
        ],
      ),
    ),
  );
}

class DocumentMetricStrip extends StatelessWidget {
  const DocumentMetricStrip({super.key, required this.metrics});

  final DocumentMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final items = [
      _Metric(
        'Files',
        '${metrics.total}',
        Icons.folder_copy_outlined,
        AppTheme.blue,
      ),
      _Metric(
        'Shared',
        '${metrics.shared}',
        Icons.group_outlined,
        AppTheme.success,
      ),
      _Metric(
        'Media',
        '${metrics.media}',
        Icons.perm_media_outlined,
        AppTheme.orange,
      ),
      _Metric(
        'Storage',
        _storageLabel(metrics.totalBytes),
        Icons.cloud_outlined,
        const Color(0xFF7C5CE7),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) => SizedBox(
                width: 154,
                child: _MetricCard(metric: items[index]),
              ),
            ),
          );
        }
        const spacing = 10.0;
        return Row(
          children: items
              .map(
                (metric) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: metric == items.last ? 0 : spacing,
                    ),
                    child: _MetricCard(metric: metric),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon, this.tone);

  final String label;
  final String value;
  final IconData icon;
  final Color tone;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.all(13),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: metric.tone.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(metric.icon, color: metric.tone, size: 17),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                metric.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                metric.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class DocumentKindChips extends StatelessWidget {
  const DocumentKindChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final DocumentKind? selected;
  final ValueChanged<DocumentKind?> onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    clipBehavior: Clip.none,
    child: Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            selected: selected == null,
            onSelected: (_) => onChanged(null),
            avatar: const Icon(Icons.grid_view_rounded, size: 16),
            label: const Text('All files'),
          ),
        ),
        ...DocumentKind.values.map(
          (kind) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected == kind,
              onSelected: (_) => onChanged(kind),
              avatar: Icon(documentKindIcon(kind), size: 16),
              label: Text(kind.label),
            ),
          ),
        ),
      ],
    ),
  );
}

class DocumentSiteFilter extends StatelessWidget {
  const DocumentSiteFilter({
    super.key,
    required this.sites,
    required this.selected,
    required this.onChanged,
  });

  final List<SiteSummary> sites;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: selected ?? '',
    isExpanded: true,
    decoration: const InputDecoration(
      labelText: 'Project',
      prefixIcon: Icon(Icons.apartment_outlined),
    ),
    items: [
      const DropdownMenuItem(value: '', child: Text('All projects')),
      ...sites.map(
        (site) => DropdownMenuItem(value: site.id, child: Text(site.name)),
      ),
    ],
    onChanged: (value) =>
        onChanged(value == null || value.isEmpty ? null : value),
  );
}

class DocumentApiNotice extends StatelessWidget {
  const DocumentApiNotice({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: AppTheme.warning.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppTheme.warning.withValues(alpha: .2)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.api_outlined, color: AppTheme.warning, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Document service not connected',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 7),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppTheme.warning,
                ),
                child: const Text('Retry connection'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class DocumentOfflineBanner extends StatelessWidget {
  const DocumentOfflineBanner({super.key, required this.cachedAt});

  final DateTime cachedAt;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: AppTheme.orange.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.orange.withValues(alpha: .18)),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: AppTheme.orange, size: 18),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            'Offline snapshot • Last synced ${appDate(cachedAt)}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.orange,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class DocumentRecordCard extends StatelessWidget {
  const DocumentRecordCard({
    super.key,
    required this.document,
    required this.onOpen,
  });

  final DocumentRecord document;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    onTap: onOpen,
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        DocumentThumbnail(document: document),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                document.name.isEmpty ? document.fileLabel : document.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              Wrap(
                spacing: 6,
                runSpacing: 3,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (document.siteName.isNotEmpty)
                    Text(
                      document.siteName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.blue,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (document.siteName.isNotEmpty &&
                      document.fileLabel.isNotEmpty &&
                      document.fileLabel != document.name)
                    const Text('•', style: TextStyle(color: AppTheme.muted)),
                  if (document.fileLabel.isNotEmpty &&
                      document.fileLabel != document.name)
                    Text(
                      document.fileLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.muted,
                        height: 1.35,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  DocumentStatusPill(
                    label: document.kind.label,
                    tone: documentKindTone(document.kind),
                  ),
                  if (document.sharedWithClient)
                    const DocumentStatusPill(
                      label: 'Shared',
                      tone: AppTheme.success,
                    ),
                  Text(
                    [
                      document.sizeLabel,
                      appDate(document.createdAt),
                    ].join(' • '),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
      ],
    ),
  );
}

class DocumentThumbnail extends StatelessWidget {
  const DocumentThumbnail({super.key, required this.document});

  final DocumentRecord document;

  @override
  Widget build(BuildContext context) {
    final imageUrl = document.thumbnailUrl.isNotEmpty
        ? document.thumbnailUrl
        : document.isImage
        ? document.url
        : '';
    return Container(
      width: 54,
      height: 64,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: documentKindTone(document.kind).withValues(alpha: .1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: imageUrl.isEmpty
          ? Icon(
              documentKindIcon(document.kind),
              color: documentKindTone(document.kind),
              size: 24,
            )
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                documentKindIcon(document.kind),
                color: documentKindTone(document.kind),
                size: 24,
              ),
            ),
    );
  }
}

class DocumentStatusPill extends StatelessWidget {
  const DocumentStatusPill({
    super.key,
    required this.label,
    required this.tone,
  });

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: tone.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: tone,
        fontSize: 8,
        fontWeight: FontWeight.w800,
        letterSpacing: .3,
      ),
    ),
  );
}

class DocumentEmptyState extends StatelessWidget {
  const DocumentEmptyState({
    super.key,
    required this.apiAvailable,
    required this.canUpload,
    required this.onUpload,
  });

  final bool apiAvailable;
  final bool canUpload;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) => EmptyPanel(
    title: apiAvailable ? 'No files match this view' : 'Files will appear here',
    message: apiAvailable
        ? canUpload
              ? 'Upload the first project file to create a trusted record for your team.'
              : 'Files shared with your role will appear here once the project team publishes them.'
        : 'Connect the Document Center FastAPI module to load real project files.',
    icon: apiAvailable ? Icons.folder_open_outlined : Icons.api_outlined,
    actionLabel: apiAvailable && canUpload ? 'Upload files' : null,
    onAction: apiAvailable && canUpload ? onUpload : null,
  );
}

IconData documentKindIcon(DocumentKind kind) => switch (kind) {
  DocumentKind.drawing => Icons.architecture_outlined,
  DocumentKind.boq => Icons.format_list_numbered_rounded,
  DocumentKind.estimate => Icons.calculate_outlined,
  DocumentKind.agreement => Icons.gavel_outlined,
  DocumentKind.invoice => Icons.receipt_long_outlined,
  DocumentKind.bill => Icons.request_quote_outlined,
  DocumentKind.report => Icons.description_outlined,
  DocumentKind.photo => Icons.image_outlined,
  DocumentKind.video => Icons.video_library_outlined,
  DocumentKind.other => Icons.insert_drive_file_outlined,
};

Color documentKindTone(DocumentKind kind) => switch (kind) {
  DocumentKind.drawing || DocumentKind.boq => AppTheme.blue,
  DocumentKind.estimate || DocumentKind.invoice => const Color(0xFF7C5CE7),
  DocumentKind.agreement || DocumentKind.bill => AppTheme.orange,
  DocumentKind.report => AppTheme.success,
  DocumentKind.photo || DocumentKind.video => const Color(0xFF0EA5A8),
  DocumentKind.other => AppTheme.muted,
};

String _storageLabel(int bytes) {
  if (bytes <= 0) return '0 MB';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
