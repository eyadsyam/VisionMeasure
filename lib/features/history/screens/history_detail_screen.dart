import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/l10n/app_translations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/clinical_analysis.dart';
import '../../../models/vision_record.dart';
import '../providers/history_provider.dart';

class HistoryDetailScreen extends ConsumerWidget {
  final String id;
  const HistoryDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(recordByIdProvider(id));
    final all = ref.watch(historyRecordsProvider).valueOrNull ?? const [];
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (record == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('record'))),
        body: Center(child: Text(context.tr('record_not_found'))),
      );
    }

    final fmt = DateFormat('MMMM d, yyyy • HH:mm');
    final isManual = record.testType == 'manual';
    final report = ClinicalReport.fromJsonString(record.notes);

    final badgeGradient = isManual
        ? AppTheme.warmGradient
        : AppTheme.primaryGradient;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('record')),
        actions: [
          Container(
            margin: const EdgeInsetsDirectional.only(end: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B)
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              tooltip: context.tr('share_pdf'),
              onPressed: () => _sharePdf(context, record),
              icon: Icon(
                Icons.picture_as_pdf_rounded,
                color: cs.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF134E4A).withValues(alpha: 0.4)
                  : const Color(0xFFCCFBF1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF14B8A6).withValues(alpha: 0.2)
                    : const Color(0xFF14B8A6).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: badgeGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: badgeGradient.colors.first
                                .withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        isManual
                            ? Icons.edit_note_rounded
                            : Icons.visibility_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              record.testType.toUpperCase(),
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            fmt.format(record.createdAt),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (record.faceDistanceCm != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.straighten_rounded,
                        size: 16,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${context.tr('test_distance')}: ~${record.faceDistanceCm!.toStringAsFixed(0)} cm',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
                if (report == null && record.notes != null && record.notes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.notes_rounded,
                        size: 16,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          record.notes!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (report != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.analytics_rounded, size: 16, color: cs.primary),
                            const SizedBox(width: 6),
                            Text(
                              context.tr('clinical_assessment'),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(report.overallAssessment, style: const TextStyle(fontSize: 12, height: 1.4)),
                        if (report.binocularFlags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ...report.binocularFlags.map((f) => Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(color: Colors.red)),
                              Expanded(child: Text(f, style: const TextStyle(fontSize: 11, color: Colors.red))),
                            ],
                          )),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _EyeCard(
            title: context.tr('right_eye'),
            gradient: AppTheme.primaryGradient,
            sphere: record.odSphere,
            cylinder: record.odCylinder,
            axis: record.odAxis,
            acuity: record.odAcuity,
            se: record.odSphericalEquivalent,
            isDark: isDark,
            condition: report?.od.condition,
            severity: report?.od.severity,
            flags: report?.od.flags,
          ),
          const SizedBox(height: 12),
          _EyeCard(
            title: context.tr('left_eye'),
            gradient: AppTheme.accentGradient,
            sphere: record.osSphere,
            cylinder: record.osCylinder,
            axis: record.osAxis,
            acuity: record.osAcuity,
            se: record.osSphericalEquivalent,
            isDark: isDark,
            condition: report?.os.condition,
            severity: report?.os.severity,
            flags: report?.os.flags,
          ),
          const SizedBox(height: 20),
          if (all.length >= 2) _TrendChart(all: all),
          const SizedBox(height: 20),
          // Disclaimer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF78350F).withValues(alpha: 0.15)
                  : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFFFCD34D).withValues(alpha: 0.2)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: isDark
                      ? const Color(0xFFFCD34D)
                      : const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr('medical_disclaimer'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePdf(BuildContext context, VisionRecord r) async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '—';
    final doc = pw.Document();
    final fmt = DateFormat('yyyy-MM-dd HH:mm');
    final report = ClinicalReport.fromJsonString(r.notes);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final ttf = await PdfGoogleFonts.cairoRegular();
    final ttfBold = await PdfGoogleFonts.cairoBold();

    String dd(double? v) => v == null ? '—' : v.toStringAsFixed(2);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        build: (ctx) => pw.Directionality(
          textDirection: isAr ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  context.tr('report_title'),
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
                pw.SizedBox(height: 4),
                pw.Text(context.tr('generated', args: {'date': fmt.format(r.createdAt)})),
                pw.Text(context.tr('patient', args: {'name': name})),
                pw.SizedBox(height: 18),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: const {
                  0: pw.FlexColumnWidth(1),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _hcell(''),
                      _hcell(context.tr('right_eye')),
                      _hcell(context.tr('left_eye')),
                    ],
                  ),
                  pw.TableRow(children: [
                    _cell(context.tr('sphere')),
                    _cell(dd(r.odSphere)),
                    _cell(dd(r.osSphere)),
                  ]),
                  pw.TableRow(children: [
                    _cell(context.tr('cylinder')),
                    _cell(dd(r.odCylinder)),
                    _cell(dd(r.osCylinder)),
                  ]),
                  pw.TableRow(children: [
                    _cell(context.tr('axis')),
                    _cell(r.odAxis?.toStringAsFixed(0) ?? '—'),
                    _cell(r.osAxis?.toStringAsFixed(0) ?? '—'),
                  ]),
                  pw.TableRow(children: [
                    _cell(context.tr('spherical_equivalent')),
                    _cell(dd(r.odSphericalEquivalent)),
                    _cell(dd(r.osSphericalEquivalent)),
                  ]),
                  pw.TableRow(children: [
                    _cell(context.tr('acuity')),
                    _cell(r.odAcuity ?? '—'),
                    _cell(r.osAcuity ?? '—'),
                  ]),
                ],
              ),
              pw.SizedBox(height: 14),
              pw.Text('${context.tr('choose_test_type')}: ${r.testType}'),
              if (r.faceDistanceCm != null)
                pw.Text(
                  '${context.tr('test_distance')}: ~${r.faceDistanceCm!.toStringAsFixed(0)} cm',
                ),
              if (report == null && r.notes != null && r.notes!.isNotEmpty)
                pw.Text('${context.tr('notes')}: ${r.notes}'),
              pw.SizedBox(height: 14),
              pw.Text(
                context.tr('clinical_interpretation'),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              if (report != null) ...[
                pw.Text(report.overallAssessment),
                if (report.binocularFlags.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  ...report.binocularFlags.map((f) => pw.Text('• $f', style: const pw.TextStyle(color: PdfColors.red))),
                ],
                pw.SizedBox(height: 8),
                pw.Text('${context.tr('right_eye')}: ${report.od.condition}${report.od.severity.isNotEmpty ? ' (${report.od.severity})' : ''}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                if (report.od.flags.isNotEmpty) ...[
                  ...report.od.flags.map((f) => pw.Text('  - $f')),
                ],
                pw.SizedBox(height: 4),
                pw.Text('${context.tr('left_eye')}: ${report.os.condition}${report.os.severity.isNotEmpty ? ' (${report.os.severity})' : ''}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                if (report.os.flags.isNotEmpty) ...[
                  ...report.os.flags.map((f) => pw.Text('  - $f')),
                ],
              ] else ...[
                pw.Text(_interpretAcuity(context.tr('right_eye'), r.odAcuity)),
                pw.SizedBox(height: 4),
                pw.Text(_interpretAcuity(context.tr('left_eye'), r.osAcuity)),
              ],
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Text(
                context.tr('disclaimer_pdf'),
                style:
                    pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
      ),
      ),
    );
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'VisionMeasure_${r.id.substring(0, 6)}.pdf',
    );
  }

  String _interpretAcuity(String eye, String? acuity) {
    if (acuity == null || acuity == '—') return '$eye: No data';
    if (acuity == '>6/60') return '$eye: $acuity — Severe visual impairment. Urgent referral recommended.';
    final parts = acuity.split('/');
    if (parts.length != 2) return '$eye: $acuity';
    final denom = int.tryParse(parts[1]) ?? 6;
    if (denom <= 6) return '$eye: $acuity — Normal vision. No correction needed.';
    if (denom <= 9) return '$eye: $acuity — Mild reduction. Monitor and retest in 6 months.';
    if (denom <= 18) return '$eye: $acuity — Moderate impairment. Corrective lenses recommended.';
    if (denom <= 36) return '$eye: $acuity — Significant impairment. Eye exam strongly advised.';
    return '$eye: $acuity — Severe impairment. Urgent referral recommended.';
  }

  pw.Widget _hcell(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(
          text,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      );

  pw.Widget _cell(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text),
      );
}

class _EyeCard extends StatelessWidget {
  final String title;
  final LinearGradient gradient;
  final double? sphere;
  final double? cylinder;
  final double? axis;
  final String? acuity;
  final double? se;
  final bool isDark;
  final String? condition;
  final String? severity;
  final List<String>? flags;

  const _EyeCard({
    required this.title,
    required this.gradient,
    this.sphere,
    this.cylinder,
    this.axis,
    this.acuity,
    this.se,
    required this.isDark,
    this.condition,
    this.severity,
    this.flags,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155).withValues(alpha: 0.5)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color:
                          gradient.colors.first.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.visibility_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (condition != null && condition!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$condition${severity != null && severity!.isNotEmpty ? ' ($severity)' : ''}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _row(context, context.tr('sphere'), sphere?.toStringAsFixed(2)),
          _row(context, context.tr('cylinder'), cylinder?.toStringAsFixed(2)),
          _row(context, context.tr('axis'), axis?.toStringAsFixed(0)),
          _row(context, context.tr('spherical_equivalent'),
              se?.toStringAsFixed(2)),
          if (acuity != null) _row(context, context.tr('acuity'), acuity!),
          if (flags != null && flags!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...flags!.map((f) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_rounded, size: 14, color: Colors.orange),
                const SizedBox(width: 6),
                Expanded(child: Text(f, style: const TextStyle(fontSize: 11, color: Colors.orange))),
              ],
            )),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String k, String? v) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ),
          Text(
            v ?? '—',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<VisionRecord> all;
  const _TrendChart({required this.all});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sorted = [...all]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final odSpots = <FlSpot>[];
    final osSpots = <FlSpot>[];
    for (var i = 0; i < sorted.length; i++) {
      final r = sorted[i];
      if (r.odSphericalEquivalent != null) {
        odSpots.add(FlSpot(i.toDouble(), r.odSphericalEquivalent!));
      }
      if (r.osSphericalEquivalent != null) {
        osSpots.add(FlSpot(i.toDouble(), r.osSphericalEquivalent!));
      }
    }

    if (odSpots.isEmpty && osSpots.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155).withValues(alpha: 0.5)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  size: 18,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                context.tr('trend_over_time'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: cs.outlineVariant,
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (v) => FlLine(
                    color: cs.outlineVariant,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles:
                        SideTitles(showTitles: true, reservedSize: 30),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles:
                        SideTitles(showTitles: true, reservedSize: 20),
                  ),
                ),
                lineBarsData: [
                  if (odSpots.isNotEmpty)
                    LineChartBarData(
                      spots: odSpots,
                      isCurved: true,
                      color: const Color(0xFF0D9488),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF0D9488)
                            .withValues(alpha: 0.08),
                      ),
                    ),
                  if (osSpots.isNotEmpty)
                    LineChartBarData(
                      spots: osSpots,
                      isCurved: true,
                      color: const Color(0xFF6366F1),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF6366F1)
                            .withValues(alpha: 0.08),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _legend(color: const Color(0xFF0D9488), label: 'OD'),
              const SizedBox(width: 16),
              _legend(color: const Color(0xFF6366F1), label: 'OS'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }
}
