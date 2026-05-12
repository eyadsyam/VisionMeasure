import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_translations.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../history/providers/history_provider.dart';
import '../../../models/vision_record.dart';
import '../widgets/avatar_badge.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final recordsAsync = ref.watch(historyRecordsProvider);
    final records = recordsAsync.valueOrNull ?? const <VisionRecord>[];
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF0F172A)]
                : [const Color(0xFFF0FDFA), const Color(0xFFF8FAFC)],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // ── Patient header ──
              SliverToBoxAdapter(
                child: _PatientHeader(profile: profile, isDark: isDark, cs: cs),
              ),
              // ── Primary CTA ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: _PrimaryCTA(onTap: () => context.push('/tests')),
                ),
              ),
              // ── Stats ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: _StatsRow(records: records),
                ),
              ),
              // ── Latest result ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: _LatestResultCard(records: records, isDark: isDark, cs: cs),
                ),
              ),
              // ── Quick actions ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Text(
                    context.tr('dashboard_quick_actions'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverList.list(
                  children: [
                    _QuickAction(
                      icon: Icons.edit_note_rounded,
                      title: context.tr('manual_entry'),
                      subtitle: context.tr('manual_entry_sub'),
                      color: const Color(0xFF6366F1),
                      onTap: () => context.push('/manual-entry'),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _QuickAction(
                      icon: Icons.show_chart_rounded,
                      title: context.tr('view_history'),
                      subtitle: context.tr('view_history_sub'),
                      color: const Color(0xFFF59E0B),
                      onTap: () => context.go('/history'),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _QuickAction(
                      icon: Icons.tips_and_updates_rounded,
                      title: context.tr('eye_health_tips'),
                      subtitle: context.tr('eye_health_tips_sub'),
                      color: const Color(0xFF22C55E),
                      onTap: () => context.push('/tips'),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),
                    _DisclaimerBanner(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────── Patient Header ───────────────────
class _PatientHeader extends StatelessWidget {
  final UserProfile profile;
  final bool isDark;
  final ColorScheme cs;
  const _PatientHeader({required this.profile, required this.isDark, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 8),
      child: Row(
        children: [
          AvatarBadge(profile: profile, size: 52, onTap: () => context.push('/profile-edit')),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name.isEmpty
                      ? context.tr('app_name')
                      : context.tr('hi_user', args: {'name': profile.name}),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('dashboard_welcome_sub'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
              ),
            ),
            child: IconButton(
              tooltip: context.tr('settings'),
              onPressed: () => context.push('/settings'),
              icon: Icon(Icons.settings_outlined, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────── Primary CTA ───────────────────
class _PrimaryCTA extends StatelessWidget {
  final VoidCallback onTap;
  const _PrimaryCTA({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.visibility_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('dashboard_begin_test'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('dashboard_begin_test_sub'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: Colors.white.withValues(alpha: 0.8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────── Stats Row ───────────────────
class _StatsRow extends StatelessWidget {
  final List<VisionRecord> records;
  const _StatsRow({required this.records});

  @override
  Widget build(BuildContext context) {
    final total = records.length;
    final lastLabel = _lastLabel(context, records);
    final trend = _trend(records);
    return Row(
      children: [
        Expanded(child: _StatCard(icon: Icons.analytics_outlined, label: context.tr('stat_total_tests'), value: '$total', color: const Color(0xFF0D9488))),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(icon: Icons.calendar_today_rounded, label: context.tr('stat_last_test'), value: lastLabel, color: const Color(0xFF6366F1))),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(icon: trend.$2, label: context.tr('stat_trend'), value: trend.$1, color: trend.$3)),
      ],
    );
  }

  String _lastLabel(BuildContext context, List<VisionRecord> recs) {
    if (recs.isEmpty) return context.tr('stat_never');
    final latest = recs.first.createdAt;
    final diff = DateTime.now().difference(latest).inDays;
    if (diff <= 0) return context.tr('stat_today');
    if (diff == 1) return context.tr('stat_yesterday');
    if (diff < 30) return context.tr('stat_days_ago', args: {'n': '$diff'});
    return DateFormat.yMMMd().format(latest);
  }

  (String, IconData, Color) _trend(List<VisionRecord> recs) {
    final seVals = recs.map((r) => r.odSphericalEquivalent).whereType<double>().toList();
    if (seVals.length < 2) return ('—', Icons.horizontal_rule_rounded, const Color(0xFF94A3B8));
    final delta = seVals.first - seVals.last;
    if (delta.abs() < 0.25) return ('stable', Icons.trending_flat_rounded, const Color(0xFF6366F1));
    if (delta > 0) return ('improving', Icons.trending_up_rounded, const Color(0xFF22C55E));
    return ('worsening', Icons.trending_down_rounded, const Color(0xFFF59E0B));
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon; final String label; final String value; final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String displayValue = value;
    if (['stable', 'improving', 'worsening'].contains(value)) displayValue = context.tr('trend_$value');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Text(displayValue, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─────────────────── Latest Result Card ───────────────────
class _LatestResultCard extends StatelessWidget {
  final List<VisionRecord> records;
  final bool isDark;
  final ColorScheme cs;
  const _LatestResultCard({required this.records, required this.isDark, required this.cs});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(Icons.remove_red_eye_outlined, size: 40, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(context.tr('dashboard_no_results'), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(context.tr('dashboard_no_results_sub'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }
    final latest = records.first;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('/history/${latest.id}'),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(context.tr('dashboard_last_results'), style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                    const Spacer(),
                    Text(DateFormat.yMMMd().format(latest.createdAt), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _EyeResult(label: context.tr('right_eye'), acuity: latest.odAcuity ?? '—', se: latest.odSphericalEquivalent, cs: cs)),
                    Container(width: 1, height: 48, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    Expanded(child: _EyeResult(label: context.tr('left_eye'), acuity: latest.osAcuity ?? '—', se: latest.osSphericalEquivalent, cs: cs)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EyeResult extends StatelessWidget {
  final String label; final String acuity; final double? se; final ColorScheme cs;
  const _EyeResult({required this.label, required this.acuity, this.se, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(acuity, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        if (se != null)
          Text('SE: ${se! >= 0 ? '+' : ''}${se!.toStringAsFixed(2)}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
      ],
    );
  }
}

// ─────────────────── Quick Action ───────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon; final String title; final String subtitle;
  final Color color; final VoidCallback onTap; final bool isDark;
  const _QuickAction({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────── Disclaimer ───────────────────
class _DisclaimerBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.15) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFFFCD34D).withValues(alpha: 0.2) : const Color(0xFFF59E0B).withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFF59E0B)),
          const SizedBox(width: 10),
          Expanded(child: Text(context.tr('medical_disclaimer'), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4))),
        ],
      ),
    );
  }
}
