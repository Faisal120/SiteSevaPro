import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/estimate_models.dart';
import 'estimate_widgets.dart';

class EstimateDetailHero extends StatelessWidget {
  const EstimateDetailHero({
    super.key,
    required this.document,
    required this.siteName,
  });
  final EstimateDocument document;
  final String siteName;

  @override
  Widget build(BuildContext context) {
    final tone = estimateQualityColor(document.quality);
    return Container(
      constraints: const BoxConstraints(minHeight: 210),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF081321), Color(0xFF17314E), Color(0xFF5E311C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x250A0E17),
            blurRadius: 30,
            offset: Offset(0, 15),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final identity = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Hero(
                    tag: 'estimate-mark-${document.id}',
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.orange,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x55F36B21),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.calculate_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  StatusBadge(label: document.quality.label, tone: tone),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                document.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.9,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.apartment_rounded,
                    color: Color(0xFFBFCBDC),
                    size: 16,
                  ),
                  const SizedBox(width: 7),
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
          final commercial = _HeroCommercial(document: document);
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [identity, const SizedBox(height: 24), commercial],
            );
          }
          return Row(
            children: [
              Expanded(flex: 3, child: identity),
              const SizedBox(width: 28),
              Expanded(flex: 2, child: commercial),
            ],
          );
        },
      ),
    );
  }
}

class _HeroCommercial extends StatelessWidget {
  const _HeroCommercial({required this.document});
  final EstimateDocument document;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .075),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'APPROVED BUDGET',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFFBFCBDC),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: .7,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          compactInr(document.total),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -.8,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _HeroValue(
                label: 'RATE / SQ FT',
                value: compactInr(document.ratePerSqft),
              ),
            ),
            Container(
              width: 1,
              height: 34,
              color: Colors.white.withValues(alpha: .12),
            ),
            Expanded(
              child: _HeroValue(
                label: 'BUILT-UP',
                value: '${document.builtupSqft.round()} sq ft',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _HeroValue extends StatelessWidget {
  const _HeroValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFFBFCBDC),
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class EstimatePlanningNotice extends StatelessWidget {
  const EstimatePlanningNotice({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppTheme.blue.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.blue.withValues(alpha: .16)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.fact_check_outlined, color: AppTheme.blue, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Planning baseline: the current API returns a read-only feasibility calculation, not a tax invoice or signed client quotation.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.muted,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );
}

class EstimateCostComposition extends StatelessWidget {
  const EstimateCostComposition({super.key, required this.document});
  final EstimateDocument document;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PanelTitle(
          icon: Icons.donut_large_rounded,
          title: 'Cost composition',
          message: 'Server allocation of the approved budget',
        ),
        const SizedBox(height: 20),
        _CostLine(
          label: 'Materials',
          value: document.materialCost,
          share: document.materialShare(),
          tone: AppTheme.orange,
        ),
        const SizedBox(height: 14),
        _CostLine(
          label: 'Labour',
          value: document.labourCost,
          share: document.labourShare(),
          tone: AppTheme.blue,
        ),
        const SizedBox(height: 14),
        _CostLine(
          label: 'Overhead',
          value: document.overhead,
          share: document.overheadShare(),
          tone: AppTheme.success,
        ),
        const SizedBox(height: 18),
        const Divider(height: 1),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                'Allocated total',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: AppTheme.muted),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              compactInr(document.calculatedTotal),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        if (document.hasCostMismatch) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Integrity warning: allocated costs do not match the server total.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _CostLine extends StatelessWidget {
  const _CostLine({
    required this.label,
    required this.value,
    required this.share,
    required this.tone,
  });
  final String label;
  final double value;
  final double share;
  final Color tone;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            compactInr(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: share.clamp(0, 1).toDouble()),
              duration: const Duration(milliseconds: 720),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 7,
                  backgroundColor: tone.withValues(alpha: .1),
                  valueColor: AlwaysStoppedAnimation(tone),
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 30,
            child: Text(
              '${(share * 100).toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: tone,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class EstimateMaterialSchedule extends StatelessWidget {
  const EstimateMaterialSchedule({super.key, required this.document});
  final EstimateDocument document;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: _PanelTitle(
            icon: Icons.inventory_2_outlined,
            title: 'Material quantity plan',
            message: 'Indicative quantities calculated by the service',
          ),
        ),
        const Divider(height: 1),
        ...document.materials.lines.indexed.map(
          (entry) => _MaterialRow(
            line: entry.$2,
            index: entry.$1,
            isLast: entry.$1 == document.materials.lines.length - 1,
          ),
        ),
      ],
    ),
  );
}

class _MaterialRow extends StatelessWidget {
  const _MaterialRow({
    required this.line,
    required this.index,
    required this.isLast,
  });
  final EstimateMaterialLine line;
  final int index;
  final bool isLast;

  IconData get icon => switch (line.name) {
    'Cement' => Icons.view_in_ar_outlined,
    'Steel' => Icons.reorder_rounded,
    'Sand' => Icons.landscape_outlined,
    'Aggregate' => Icons.grain_rounded,
    _ => Icons.grid_view_rounded,
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
    decoration: BoxDecoration(
      border: isLast
          ? null
          : const Border(bottom: BorderSide(color: AppTheme.line)),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.orange.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppTheme.orange, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            line.name,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          _quantity(line.quantity),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -.3,
          ),
        ),
        const SizedBox(width: 5),
        SizedBox(
          width: 40,
          child: Text(
            line.unit,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
          ),
        ),
      ],
    ),
  ).animate(delay: (index * 45).ms).fadeIn().slideX(begin: .025, end: 0);
}

class EstimateAssumptions extends StatelessWidget {
  const EstimateAssumptions({super.key, required this.document});
  final EstimateDocument document;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle(
          icon: Icons.tune_rounded,
          title: 'Planning assumptions',
          message: 'Inputs used by the calculation service',
        ),
        const SizedBox(height: 18),
        _InfoRow(
          label: 'Plot area',
          value: '${document.input.plotAreaSqft.round()} sq ft',
        ),
        _InfoRow(
          label: 'Built-up area',
          value: '${document.builtupSqft.round()} sq ft',
        ),
        _InfoRow(label: 'Floors', value: '${document.input.floors}'),
        _InfoRow(
          label: 'Basement',
          value: document.input.basement ? 'Included' : 'Not included',
        ),
        _InfoRow(
          label: 'Construction',
          value: document.input.constructionType.label,
        ),
        _InfoRow(label: 'Quality', value: document.quality.label),
        _InfoRow(
          label: 'Type factor',
          value: document.typeFactor.toStringAsFixed(2),
          isLast: true,
        ),
      ],
    ),
  );
}

class EstimateCommercialSummary extends StatelessWidget {
  const EstimateCommercialSummary({super.key, required this.document});
  final EstimateDocument document;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle(
          icon: Icons.receipt_long_outlined,
          title: 'Commercial summary',
          message: 'Values persisted on this estimate record',
        ),
        const SizedBox(height: 20),
        _CommercialValue(
          label: 'Approved budget',
          value: compactInr(document.total),
        ),
        _CommercialValue(
          label: 'Rate per sq ft',
          value: compactInr(document.ratePerSqft),
        ),
        _CommercialValue(
          label: 'Material allocation',
          value: compactInr(document.materialCost),
        ),
        _CommercialValue(
          label: 'Labour allocation',
          value: compactInr(document.labourCost),
        ),
        _CommercialValue(
          label: 'Overhead allocation',
          value: compactInr(document.overhead),
          isLast: true,
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppTheme.warning.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'GST, discount, payment schedule, terms and client approval are not stored by the current estimate endpoint.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.warning,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );
}

class EstimateBrandingContext extends StatelessWidget {
  const EstimateBrandingContext({
    super.key,
    required this.branding,
    required this.onConfigure,
  });
  final EstimateBranding? branding;
  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) {
    final value = branding;
    final companyName = value?.companyName;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(
            icon: Icons.branding_watermark_outlined,
            title: 'Document identity',
            message: companyName?.isNotEmpty == true
                ? companyName!
                : 'Company branding is not configured',
          ),
          const SizedBox(height: 18),
          if (value?.preferredLogo != null) ...[
            Container(
              height: 62,
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.line),
              ),
              child: Image.network(
                value!.preferredLogo!,
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
                errorBuilder: (context, error, stackTrace) => const Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppTheme.muted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          _ReadinessRow(
            label: 'Quotation logo',
            ready: value?.preferredLogo != null,
          ),
          _ReadinessRow(label: 'GST identity', ready: value?.gstNumber != null),
          _ReadinessRow(
            label: 'Digital signature',
            ready: value?.hasSignature == true,
          ),
          _ReadinessRow(label: 'Company stamp', ready: value?.hasStamp == true),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onConfigure,
            icon: const Icon(Icons.open_in_new_rounded, size: 17),
            label: const Text('Open branding settings'),
          ),
        ],
      ),
    );
  }
}

class EstimateUnavailableActions extends StatelessWidget {
  const EstimateUnavailableActions({super.key});

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle(
          icon: Icons.lock_clock_outlined,
          title: 'Proposal controls',
          message: 'Requires additional backend contracts',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _UnavailableChip(icon: Icons.edit_outlined, label: 'Edit'),
            _UnavailableChip(icon: Icons.approval_outlined, label: 'Approve'),
            _UnavailableChip(icon: Icons.picture_as_pdf_outlined, label: 'PDF'),
            _UnavailableChip(icon: Icons.table_view_outlined, label: 'Excel'),
            _UnavailableChip(icon: Icons.history_rounded, label: 'Versions'),
            _UnavailableChip(icon: Icons.draw_outlined, label: 'Signature'),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'These controls remain disabled rather than generating local documents that the server cannot verify or reproduce.',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppTheme.muted, height: 1.45),
        ),
      ],
    ),
  );
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.orange.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: AppTheme.orange, size: 19),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 9),
    decoration: BoxDecoration(
      border: isLast
          ? null
          : const Border(bottom: BorderSide(color: AppTheme.line)),
    ),
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
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

class _CommercialValue extends StatelessWidget {
  const _CommercialValue({
    required this.label,
    required this.value,
    this.isLast = false,
  });
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      border: isLast
          ? null
          : const Border(bottom: BorderSide(color: AppTheme.line)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppTheme.muted),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({required this.label, required this.ready});
  final String label;
  final bool ready;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(
          ready ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: ready ? AppTheme.success : AppTheme.muted,
          size: 18,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          ready ? 'Ready' : 'Missing',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: ready ? AppTheme.success : AppTheme.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _UnavailableChip extends StatelessWidget {
  const _UnavailableChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: AppTheme.line.withValues(alpha: .55),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppTheme.muted),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

String _quantity(double value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1);
}
