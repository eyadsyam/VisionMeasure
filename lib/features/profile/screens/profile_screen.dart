import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_translations.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/widgets/avatar_badge.dart';
import '../../history/providers/history_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final records = ref.watch(historyRecordsProvider).valueOrNull ?? const [];
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String genderLabel(String? code) {
      if (code == null) return context.tr('not_set');
      return context.tr('gender_$code');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('profile')),
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
              onPressed: () => context.push('/settings'),
              icon: Icon(
                Icons.settings_outlined,
                color: cs.onSurfaceVariant,
                size: 20,
              ),
              tooltip: context.tr('settings'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Profile header
            Center(
              child: Column(
                children: [
                  Hero(
                    tag: 'profile-avatar',
                    child: AvatarBadge(profile: profile, size: 104),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    profile.name.isEmpty ? '—' : profile.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonal(
                    onPressed: () => context.push('/profile-edit'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text(context.tr('edit_profile')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Info card
            Container(
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
                children: [
                  _infoRow(
                    context,
                    Icons.cake_rounded,
                    const Color(0xFFF59E0B),
                    context.tr('age'),
                    profile.effectiveAge?.toString() ?? context.tr('not_set'),
                    isDark: isDark,
                  ),
                  Divider(
                    height: 1,
                    indent: 56,
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                  _infoRow(
                    context,
                    Icons.person_outline_rounded,
                    const Color(0xFF6366F1),
                    context.tr('gender'),
                    genderLabel(profile.gender),
                    isDark: isDark,
                  ),
                  Divider(
                    height: 1,
                    indent: 56,
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                  _infoRow(
                    context,
                    Icons.calendar_month_rounded,
                    const Color(0xFF0D9488),
                    context.tr('date_of_birth'),
                    profile.dob != null
                        ? DateFormat.yMMMMd(
                                Localizations.localeOf(context).toString())
                            .format(profile.dob!)
                        : context.tr('not_set'),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Stats row
            Row(
              children: [
                Expanded(
                  child: _statTile(
                    context,
                    Icons.bar_chart_rounded,
                    '${records.length}',
                    context.tr('stat_total_tests'),
                    AppTheme.primaryGradient,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statTile(
                    context,
                    Icons.event_rounded,
                    records.isEmpty
                        ? '—'
                        : DateFormat.yMMMd().format(records.first.createdAt),
                    context.tr('stat_last_test'),
                    AppTheme.accentGradient,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Quick links
            _quickLink(
              context,
              Icons.tune_rounded,
              const Color(0xFF0EA5E9),
              context.tr('settings'),
              () => context.push('/settings'),
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _quickLink(
              context,
              Icons.tips_and_updates_rounded,
              const Color(0xFFF59E0B),
              context.tr('eye_health_tips'),
              () => context.push('/tips'),
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _quickLink(
              context,
              Icons.info_outline_rounded,
              const Color(0xFF94A3B8),
              context.tr('about'),
              () => showAboutDialog(
                context: context,
                applicationName: context.tr('app_name'),
                applicationVersion: '1.0.0',
                applicationLegalese: context.tr('about_body'),
              ),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    Color iconColor,
    String label,
    String value, {
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    LinearGradient gradient, {
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _quickLink(
    BuildContext context,
    IconData icon,
    Color iconColor,
    String title,
    VoidCallback onTap, {
    required bool isDark,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155).withValues(alpha: 0.5)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
