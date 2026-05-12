import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/settings_provider.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});
  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  String _lang = 'en';
  int _theme = 0; // 0=system, 1=light, 2=dark

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    final s = ref.read(settingsProvider);
    _lang = s.locale.languageCode;
    _theme = s.themeMode.index;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                // Logo
                Center(
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [cs.primary, cs.primary.withValues(alpha: 0.7)]),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.remove_red_eye_rounded, color: Colors.white, size: 36),
                  ),
                ),
                const SizedBox(height: 20),
                Text('VisionMeasure',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 40),

                // Language section
                Text(_lang == 'ar' ? 'اختر اللغة' : 'Choose Language',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _OptionCard(
                    label: 'English',
                    icon: '🇬🇧',
                    selected: _lang == 'en',
                    isDark: isDark, cs: cs,
                    onTap: () => _setLang('en'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _OptionCard(
                    label: 'العربية',
                    icon: '🇸🇦',
                    selected: _lang == 'ar',
                    isDark: isDark, cs: cs,
                    onTap: () => _setLang('ar'),
                  )),
                ]),
                const SizedBox(height: 28),

                // Theme section
                Text(_lang == 'ar' ? 'اختر المظهر' : 'Choose Theme',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _OptionCard(
                    label: _lang == 'ar' ? 'النظام' : 'System',
                    icon: '⚙️',
                    selected: _theme == 0,
                    isDark: isDark, cs: cs,
                    onTap: () => _setTheme(0),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _OptionCard(
                    label: _lang == 'ar' ? 'فاتح' : 'Light',
                    icon: '☀️',
                    selected: _theme == 1,
                    isDark: isDark, cs: cs,
                    onTap: () => _setTheme(1),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _OptionCard(
                    label: _lang == 'ar' ? 'داكن' : 'Dark',
                    icon: '🌙',
                    selected: _theme == 2,
                    isDark: isDark, cs: cs,
                    onTap: () => _setTheme(2),
                  )),
                ]),

                const Spacer(),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: () => context.go('/patient-intake'),
                    child: Text(
                      _lang == 'ar' ? 'متابعة' : 'Continue',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setLang(String code) {
    setState(() => _lang = code);
    ref.read(settingsProvider.notifier).setLocale(Locale(code));
  }

  void _setTheme(int idx) {
    setState(() => _theme = idx);
    ref.read(settingsProvider.notifier).setThemeMode(ThemeMode.values[idx]);
  }
}

class _OptionCard extends StatelessWidget {
  final String label, icon;
  final bool selected, isDark;
  final ColorScheme cs;
  final VoidCallback onTap;
  const _OptionCard({
    required this.label, required this.icon, required this.selected,
    required this.isDark, required this.cs, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? cs.primary.withValues(alpha: 0.12)
          : isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? cs.primary : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? cs.primary : cs.onSurface,
              fontSize: 13,
            )),
          ]),
        ),
      ),
    );
  }
}
