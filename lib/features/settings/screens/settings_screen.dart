import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_translations.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../models/vision_record.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader(title: context.tr('appearance')),
            _SettingsCard(
              isDark: isDark,
              children: [
                _SettingsTile(
                  icon: Icons.brightness_6_rounded,
                  iconColor: const Color(0xFF6366F1),
                  title: context.tr('theme'),
                  subtitle: _themeLabel(context, settings.themeMode),
                  onTap: () => _pickTheme(context, ref),
                ),
                Divider(
                  height: 1,
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
                _SettingsTile(
                  icon: Icons.language_rounded,
                  iconColor: const Color(0xFF0EA5E9),
                  title: context.tr('language'),
                  subtitle: AppTranslations.languageName(
                    settings.locale.languageCode,
                  ),
                  onTap: () => _pickLanguage(context, ref),
                ),
                Divider(
                  height: 1,
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
                _SettingsTile(
                  icon: Icons.aspect_ratio_rounded,
                  iconColor: const Color(0xFFEAB308),
                  title: 'معايرة الشاشة (Screen Calibration)',
                  subtitle: 'ضبط القياسات لنتائج دقيقة',
                  onTap: () => context.push('/calibration'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionHeader(title: context.tr('reminder')),
            _SettingsCard(
              isDark: isDark,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Text(
                    context.tr('reminder_desc'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.alarm_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: settings.nextTestDate == null
                      ? context.tr('no_reminder')
                      : DateFormat.yMMMMd().format(settings.nextTestDate!),
                  trailing: settings.nextTestDate == null
                      ? TextButton(
                          onPressed: () => _pickReminder(context, ref),
                          child: Text(context.tr('set_reminder')),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _pickReminder(context, ref),
                              icon: const Icon(Icons.edit_rounded, size: 20),
                            ),
                            IconButton(
                              tooltip: context.tr('clear_reminder'),
                              onPressed: () => ref
                                  .read(settingsProvider.notifier)
                                  .setReminder(null),
                              icon: const Icon(Icons.close_rounded, size: 20),
                            ),
                          ],
                        ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionHeader(title: context.tr('profile')),
            _SettingsCard(
              isDark: isDark,
              children: [
                _SettingsTile(
                  icon: Icons.person_outline_rounded,
                  iconColor: const Color(0xFF0D9488),
                  title: context.tr('edit_profile'),
                  onTap: () => context.push('/profile-edit'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionHeader(
              title: context.tr('danger_zone'),
              color: cs.error,
            ),
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF7F1D1D).withValues(alpha: 0.2)
                    : const Color(0xFFFEE2E2).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                      : const Color(0xFFEF4444).withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.delete_sweep_outlined,
                    iconColor: cs.error,
                    title: context.tr('clear_all_records'),
                    titleColor: cs.error,
                    onTap: () => _confirmClearRecords(context),
                  ),
                  Divider(
                    height: 1,
                    color: cs.error.withValues(alpha: 0.15),
                  ),
                  _SettingsTile(
                    icon: Icons.restart_alt_rounded,
                    iconColor: cs.error,
                    title: context.tr('reset_app'),
                    titleColor: cs.error,
                    onTap: () => _confirmResetApp(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionHeader(title: context.tr('about')),
            _SettingsCard(
              isDark: isDark,
              children: [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: const Color(0xFF94A3B8),
                  title: context.tr('app_name'),
                  subtitle: '${context.tr('version')} 1.0.0',
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: context.tr('app_name'),
                    applicationVersion: '1.0.0',
                    applicationLegalese: context.tr('about_body'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _themeLabel(BuildContext context, ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return context.tr('theme_light');
      case ThemeMode.dark:
        return context.tr('theme_dark');
      case ThemeMode.system:
        return context.tr('theme_system');
    }
  }

  void _pickTheme(BuildContext context, WidgetRef ref) {
    final current = ref.read(settingsProvider).themeMode;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            for (final m in ThemeMode.values)
              RadioListTile<ThemeMode>(
                value: m,
                groupValue: current,
                title: Text(_themeLabel(context, m)),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(settingsProvider.notifier).setThemeMode(v);
                    Navigator.pop(ctx);
                  }
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _pickLanguage(BuildContext context, WidgetRef ref) {
    final current = ref.read(settingsProvider).locale;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            for (final l in AppTranslations.supportedLocales)
              RadioListTile<String>(
                value: l.languageCode,
                groupValue: current.languageCode,
                title: Text(AppTranslations.languageName(l.languageCode)),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(settingsProvider.notifier).setLocale(Locale(v));
                    Navigator.pop(ctx);
                  }
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickReminder(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      initialDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) {
      ref.read(settingsProvider.notifier).setReminder(picked);
    }
  }

  Future<void> _confirmClearRecords(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('clear_all_records')),
        content: Text(context.tr('clear_records_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await Hive.box<VisionRecord>('vision_records').clear();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('records_cleared'))),
      );
    }
  }

  Future<void> _confirmResetApp(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('reset_app')),
        content: Text(context.tr('reset_app_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('reset')),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await Hive.box<VisionRecord>('vision_records').clear();
      await ref.read(profileProvider.notifier).clear();
      await ref.read(settingsProvider.notifier).clear();
      if (!context.mounted) return;
      context.go('/');
    }
  }
}

class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;
  const _SettingsCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155).withValues(alpha: 0.5)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                )
              : null),
      onTap: onTap,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color? color;
  const _SectionHeader({required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 10),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
