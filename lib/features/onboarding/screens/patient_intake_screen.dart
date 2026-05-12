import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/l10n/app_translations.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/theme/app_theme.dart';

class PatientIntakeScreen extends ConsumerStatefulWidget {
  const PatientIntakeScreen({super.key});

  @override
  ConsumerState<PatientIntakeScreen> createState() =>
      _PatientIntakeScreenState();
}

class _PatientIntakeScreenState extends ConsumerState<PatientIntakeScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _saving = false;

  // Step 1: Name
  final _nameKey = GlobalKey<FormFieldState>();
  final _nameCtrl = TextEditingController();

  // Step 2: DOB + Gender
  DateTime? _dob;
  String? _gender;

  // Step 3: Medical history
  bool _wearsGlasses = false;
  bool _wearsContacts = false;
  bool _hasPrevConditions = false;
  bool _familyHistory = false;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeIn;

  static const _totalSteps = 4;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    // Pre-fill from existing profile
    final profile = ref.read(profileProvider);
    _nameCtrl.text = profile.name;
    _dob = profile.dob;
    _gender = profile.gender;
    _wearsGlasses = profile.wearsGlasses;
    _wearsContacts = profile.wearsContacts;
    _hasPrevConditions = profile.hasPreviousConditions;
    _familyHistory = profile.familyHistoryEyeDisease;
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pageController.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0) {
      if (_nameCtrl.text.trim().isEmpty) {
        _nameKey.currentState?.validate();
        return;
      }
    }
    if (_currentPage < _totalSteps - 1) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _finishIntake() async {
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    final profile = ref.read(profileProvider).copyWith(
          name: _nameCtrl.text.trim(),
          dob: _dob,
          gender: _gender,
          wearsGlasses: _wearsGlasses,
          wearsContacts: _wearsContacts,
          hasPreviousConditions: _hasPrevConditions,
          familyHistoryEyeDisease: _familyHistory,
        );
    await ref.read(profileProvider.notifier).update(profile);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF0D2D2C)]
                : [const Color(0xFFF0FDFA), const Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Column(
              children: [
                // Top bar with progress
                _buildTopBar(cs, isDark),
                // Page content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: [
                      _buildNameStep(cs, isDark),
                      _buildDobGenderStep(cs, isDark),
                      _buildMedicalStep(cs, isDark),
                      _buildReadyStep(cs, isDark),
                    ],
                  ),
                ),
                // Bottom navigation
                _buildBottomNav(cs, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          // Step indicator
          Row(
            children: [
              if (_currentPage > 0)
                GestureDetector(
                  onTap: _prevPage,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155).withValues(alpha: 0.5)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                )
              else
                const SizedBox(width: 40),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${context.tr('intake_step')} ${_currentPage + 1}/$_totalSteps',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / _totalSteps,
              minHeight: 5,
              backgroundColor: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation(cs.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────── STEP 1: Name ────────────────────────────
  Widget _buildNameStep(ColorScheme cs, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.medical_information_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            context.tr('intake_welcome'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('intake_welcome_sub'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 36),
          _clinicalCard(
            isDark: isDark,
            child: TextFormField(
              key: _nameKey,
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              maxLength: 30,
              autofocus: true,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              decoration: InputDecoration(
                labelText: context.tr('intake_full_name'),
                hintText: context.tr('intake_name_hint'),
                counterText: '',
                prefixIcon: Icon(
                  Icons.person_rounded,
                  color: cs.primary,
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r"[\p{L} ]", unicode: true),
                ),
              ],
              validator: (v) {
                if ((v?.trim() ?? '').isEmpty) {
                  return context.tr('name_required');
                }
                return null;
              },
              onFieldSubmitted: (_) => _nextPage(),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── STEP 2: DOB + Gender ───────────────────────
  Widget _buildDobGenderStep(ColorScheme cs, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          _sectionHeader(
            icon: Icons.calendar_today_rounded,
            title: context.tr('intake_personal_info'),
            subtitle: context.tr('intake_personal_sub'),
            cs: cs,
          ),
          const SizedBox(height: 24),

          // Date of birth
          _clinicalCard(
            isDark: isDark,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.cake_rounded,
                  color: Color(0xFF6366F1),
                  size: 22,
                ),
              ),
              title: Text(
                context.tr('date_of_birth'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                _dob != null
                    ? '${_dob!.day}/${_dob!.month}/${_dob!.year}'
                    : context.tr('intake_tap_to_set'),
                style: TextStyle(
                  color: _dob != null ? cs.primary : cs.onSurfaceVariant,
                  fontWeight:
                      _dob != null ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant,
              ),
              onTap: () => _pickDob(),
            ),
          ),

          const SizedBox(height: 16),

          // Gender selection
          _clinicalCard(
            isDark: isDark,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.wc_rounded,
                          color: Color(0xFF0D9488),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        context.tr('gender'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _genderChip('male', context.tr('gender_male'),
                          Icons.male_rounded, cs, isDark),
                      _genderChip('female', context.tr('gender_female'),
                          Icons.female_rounded, cs, isDark),
                      _genderChip('other', context.tr('gender_other'),
                          Icons.transgender_rounded, cs, isDark),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderChip(
    String value,
    String label,
    IconData icon,
    ColorScheme cs,
    bool isDark,
  ) {
    final selected = _gender == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _gender = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.12)
              : isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? cs.primary
                : isDark
                    ? const Color(0xFF334155).withValues(alpha: 0.5)
                    : const Color(0xFFE2E8F0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? cs.primary : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: const Color(0xFF0D9488),
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  // ──────────────────── STEP 3: Medical History ────────────────────────
  Widget _buildMedicalStep(ColorScheme cs, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          _sectionHeader(
            icon: Icons.medical_services_rounded,
            title: context.tr('intake_medical_history'),
            subtitle: context.tr('intake_medical_sub'),
            cs: cs,
          ),
          const SizedBox(height: 24),

          _medicalToggle(
            isDark: isDark,
            cs: cs,
            icon: Icons.visibility_rounded,
            iconColor: const Color(0xFF6366F1),
            title: context.tr('intake_wear_glasses'),
            subtitle: context.tr('intake_wear_glasses_sub'),
            value: _wearsGlasses,
            onChanged: (v) => setState(() => _wearsGlasses = v),
          ),
          const SizedBox(height: 12),

          _medicalToggle(
            isDark: isDark,
            cs: cs,
            icon: Icons.lens_rounded,
            iconColor: const Color(0xFF0EA5E9),
            title: context.tr('intake_wear_contacts'),
            subtitle: context.tr('intake_wear_contacts_sub'),
            value: _wearsContacts,
            onChanged: (v) => setState(() => _wearsContacts = v),
          ),
          const SizedBox(height: 12),

          _medicalToggle(
            isDark: isDark,
            cs: cs,
            icon: Icons.healing_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: context.tr('intake_prev_conditions'),
            subtitle: context.tr('intake_prev_conditions_sub'),
            value: _hasPrevConditions,
            onChanged: (v) => setState(() => _hasPrevConditions = v),
          ),
          const SizedBox(height: 12),

          _medicalToggle(
            isDark: isDark,
            cs: cs,
            icon: Icons.family_restroom_rounded,
            iconColor: const Color(0xFFEC4899),
            title: context.tr('intake_family_history'),
            subtitle: context.tr('intake_family_history_sub'),
            value: _familyHistory,
            onChanged: (v) => setState(() => _familyHistory = v),
          ),
        ],
      ),
    );
  }

  Widget _medicalToggle({
    required bool isDark,
    required ColorScheme cs,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _clinicalCard(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              activeColor: cs.primary,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                onChanged(v);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────── STEP 4: All Set ────────────────────────────────
  Widget _buildReadyStep(ColorScheme cs, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        children: [
          const SizedBox(height: 48),
          // Success icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF22C55E), Color(0xFF10B981)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 52,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            context.tr('intake_ready_title'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr('intake_ready_sub'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 36),

          // Patient summary card
          _clinicalCard(
            isDark: isDark,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _summaryRow(
                    Icons.person_rounded,
                    context.tr('name'),
                    _nameCtrl.text.trim(),
                    cs,
                  ),
                  if (_dob != null)
                    _summaryRow(
                      Icons.cake_rounded,
                      context.tr('date_of_birth'),
                      '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                      cs,
                    ),
                  if (_gender != null)
                    _summaryRow(
                      Icons.wc_rounded,
                      context.tr('gender'),
                      context.tr('gender_$_gender'),
                      cs,
                    ),
                  if (_wearsGlasses)
                    _summaryRow(
                      Icons.visibility_rounded,
                      context.tr('intake_wear_glasses'),
                      context.tr('intake_yes'),
                      cs,
                    ),
                  if (_wearsContacts)
                    _summaryRow(
                      Icons.lens_rounded,
                      context.tr('intake_wear_contacts'),
                      context.tr('intake_yes'),
                      cs,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    IconData icon,
    String label,
    String value,
    ColorScheme cs,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────── Bottom Navigation ────────────────────────────
  Widget _buildBottomNav(ColorScheme cs, bool isDark) {
    final isLast = _currentPage == _totalSteps - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: FilledButton(
        onPressed: _saving
            ? null
            : isLast
                ? _finishIntake
                : _nextPage,
        style: FilledButton.styleFrom(
          backgroundColor: isLast ? const Color(0xFF22C55E) : cs.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(58),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLast
                        ? context.tr('intake_begin_screening')
                        : context.tr('continue'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isLast
                        ? Icons.play_arrow_rounded
                        : Icons.arrow_forward_rounded,
                    size: 20,
                  ),
                ],
              ),
      ),
    );
  }

  // ──────────────────── Shared Widgets ────────────────────────────────
  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme cs,
  }) {
    return Column(
      children: [
        Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, size: 30, color: Colors.white),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
        ),
      ],
    );
  }

  Widget _clinicalCard({required bool isDark, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155).withValues(alpha: 0.5)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }
}
