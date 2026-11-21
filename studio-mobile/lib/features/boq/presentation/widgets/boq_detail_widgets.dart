import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/boq_models.dart';

class BoqDetailHero extends StatelessWidget {
  const BoqDetailHero({
    super.key,
    required this.document,
    required this.siteName,
  });

  final BoqDocument document;
  final String siteName;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 198),
    padding: const EdgeInsets.all(22),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      gradient: const LinearGradient(
        colors: [Color(0xFF081321), Color(0xFF193555), Color(0xFF713718)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 650;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Hero(
                  tag: 'boq-mark-${document.id}',
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.orange,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.format_list_numbered_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const StatusBadge(label: 'ISSUED', tone: AppTheme.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appDate(document.createdAt, fallback: 'Undated issue'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFFBFCBDC),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              document.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -.9,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.apartment_rounded,
                  size: 15,
                  color: Color(0xFFBFCBDC),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    siteName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFBFCBDC),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
        final metrics = _BoqDetailMetrics(document: document);
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 20), metrics],
          );
        }
        return Row(
          children: [
            Expanded(flex: 3, child: title),
            const SizedBox(width: 26),
            Expanded(flex: 2, child: metrics),
          ],
        );
      },
    ),
  );
}

class _BoqDetailMetrics extends StatelessWidget {
  const _BoqDetailMetrics({required this.document});
  final BoqDocument document;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .075),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          compactInr(document.total),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -.7,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'SERVER-CALCULATED TOTAL',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFFBFCBDC),
            fontSize: 8,
            letterSpacing: .6,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _MiniMetric(
              value: '${document.sections.length}',
              label: 'Sections',
            ),
            _MiniMetric(value: '${document.itemCount}', label: 'Items'),
            _MiniMetric(
              value: '${document.builtupSqft.round()}',
              label: 'Sq ft',
            ),
          ],
        ),
      ],
    ),
  );
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFFBFCBDC),
            fontSize: 8,
          ),
        ),
      ],
    ),
  );
}

class BoqIssuedNotice extends StatelessWidget {
  const BoqIssuedNotice({super.key});

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
        const Icon(Icons.lock_outline_rounded, color: AppTheme.blue, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'This is an issued server worksheet. The current backend does not expose line editing, GST, approvals or revision endpoints, so SiteSeva keeps these financial values read-only.',
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

class BoqCostComposition extends StatelessWidget {
  const BoqCostComposition({super.key, required this.document});
  final BoqDocument document;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cost composition',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          'Share of the server-calculated BOQ total.',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
        ),
        const SizedBox(height: 16),
        ...document.sections.indexed.map((entry) {
          final section = entry.$2;
          final share = section.shareOf(document.total).clamp(0, 1);
          final tone = _sectionTone(entry.$1);
          return Padding(
            padding: const EdgeInsets.only(bottom: 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        section.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${(share * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: share.toDouble()),
                  duration: const Duration(milliseconds: 720),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 7,
                      color: tone,
                      backgroundColor: tone.withValues(alpha: .1),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    ),
  );
}

class BoqSourceContext extends StatelessWidget {
  const BoqSourceContext({
    super.key,
    required this.document,
    required this.estimate,
  });
  final BoqDocument document;
  final BoqEstimateSummary? estimate;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.orange.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                estimate == null
                    ? Icons.square_foot_rounded
                    : Icons.calculate_outlined,
                color: AppTheme.orange,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    estimate == null ? 'Measured area' : 'Source estimate',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    estimate?.name ?? 'Direct verified measurement',
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
        const SizedBox(height: 14),
        _ContextRow(
          label: 'Built-up area',
          value: '${document.builtupSqft.round()} sq ft',
        ),
        if (estimate != null) ...[
          _ContextRow(
            label: 'Estimate value',
            value: compactInr(estimate!.total),
          ),
          _ContextRow(
            label: 'Quality band',
            value: estimate!.qualityBand.isEmpty
                ? 'Not set'
                : estimate!.qualityBand,
          ),
        ],
      ],
    ),
  );
}

class _ContextRow extends StatelessWidget {
  const _ContextRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class BoqVendorDirectory extends StatelessWidget {
  const BoqVendorDirectory({super.key, required this.vendors});
  final List<BoqVendorSummary> vendors;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rate validation directory',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          'Live company vendors. Their quoted rates are not yet linked to BOQ rows.',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppTheme.muted, height: 1.4),
        ),
        const SizedBox(height: 13),
        if (vendors.isEmpty)
          Text(
            'No vendors available from the backend.',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
          )
        else
          ...vendors
              .take(5)
              .map(
                (vendor) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: .09),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: AppTheme.success,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vendor.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              vendor.categories.isEmpty
                                  ? vendor.gst ?? 'No category provided'
                                  : vendor.categories.join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppTheme.muted,
                                    fontSize: 9,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ],
    ),
  );
}

class BoqWorksheet extends StatelessWidget {
  const BoqWorksheet({super.key, required this.document});
  final BoqDocument document;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Itemized worksheet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${document.sections.length} sections and ${document.itemCount} measured line items',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                ),
              ],
            ),
          ),
          StatusBadge(
            label: document.rateMismatchCount == 0
                ? 'TOTALS VERIFIED'
                : '${document.rateMismatchCount} CHECKS',
            tone: document.rateMismatchCount == 0
                ? AppTheme.success
                : AppTheme.warning,
          ),
        ],
      ),
      const SizedBox(height: 14),
      ...document.sections.indexed.map(
        (entry) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BoqSectionCard(section: entry.$2, sectionNumber: entry.$1 + 1),
        ),
      ),
      SurfaceCard(
        color: AppTheme.navy,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BOQ TOTAL',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFFBFCBDC),
                      fontWeight: FontWeight.w800,
                      letterSpacing: .7,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Before GST and vendor quote adjustments',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF8797AF),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              compactInr(document.total),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class BoqSectionCard extends StatelessWidget {
  const BoqSectionCard({
    super.key,
    required this.section,
    required this.sectionNumber,
  });
  final BoqSection section;
  final int sectionNumber;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _sectionTone(sectionNumber - 1).withValues(alpha: .07),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _sectionTone(sectionNumber - 1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  '$sectionNumber',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  section.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                compactInr(section.subtotal),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.orange,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 620) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: section.items.indexed.map((entry) {
                    final item = entry.$2;
                    return _MobileItemRow(index: entry.$1 + 1, item: item);
                  }).toList(),
                ),
              );
            }
            return Column(
              children: [
                const _TableHeader(),
                ...section.items.indexed.map(
                  (entry) =>
                      _DesktopItemRow(index: entry.$1 + 1, item: entry.$2),
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppTheme.line)),
    ),
    child: const Row(
      children: [
        SizedBox(width: 38, child: _HeaderText('NO.')),
        Expanded(flex: 4, child: _HeaderText('DESCRIPTION')),
        Expanded(child: _HeaderText('UNIT')),
        Expanded(child: _HeaderText('QTY', align: TextAlign.right)),
        Expanded(child: _HeaderText('RATE', align: TextAlign.right)),
        Expanded(flex: 2, child: _HeaderText('AMOUNT', align: TextAlign.right)),
      ],
    ),
  );
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.value, {this.align = TextAlign.left});
  final String value;
  final TextAlign align;

  @override
  Widget build(BuildContext context) => Text(
    value,
    textAlign: align,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppTheme.muted,
      fontSize: 8,
      fontWeight: FontWeight.w800,
      letterSpacing: .45,
    ),
  );
}

class _DesktopItemRow extends StatelessWidget {
  const _DesktopItemRow({required this.index, required this.item});
  final int index;
  final BoqItem item;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppTheme.line)),
    ),
    child: Row(
      children: [
        SizedBox(width: 38, child: _CellText('$index', muted: true)),
        Expanded(flex: 4, child: _CellText(item.description, strong: true)),
        Expanded(child: _CellText(item.unit, muted: true)),
        Expanded(
          child: _CellText(_quantity(item.quantity), align: TextAlign.right),
        ),
        Expanded(
          child: _CellText(compactInr(item.rate), align: TextAlign.right),
        ),
        Expanded(
          flex: 2,
          child: _CellText(
            compactInr(item.amount),
            align: TextAlign.right,
            strong: true,
          ),
        ),
      ],
    ),
  );
}

class _CellText extends StatelessWidget {
  const _CellText(
    this.value, {
    this.align = TextAlign.left,
    this.muted = false,
    this.strong = false,
  });
  final String value;
  final TextAlign align;
  final bool muted;
  final bool strong;

  @override
  Widget build(BuildContext context) => Text(
    value,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    textAlign: align,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: muted ? AppTheme.muted : null,
      fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
    ),
  );
}

class _MobileItemRow extends StatelessWidget {
  const _MobileItemRow({required this.index, required this.item});
  final int index;
  final BoqItem item;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.orange.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '$index',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.orange,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                item.description,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              compactInr(item.amount),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.orange,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          '${_quantity(item.quantity)} ${item.unit} x ${compactInr(item.rate)}',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
        ),
      ],
    ),
  );
}

String _quantity(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);

Color _sectionTone(int index) => const [
  AppTheme.orange,
  AppTheme.blue,
  AppTheme.success,
  AppTheme.warning,
  Color(0xFF0F7C8A),
  Color(0xFF9A5D28),
  Color(0xFF4669A8),
  Color(0xFF4D765F),
][index % 8];
