import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/l10n/app_translations.dart';
import '../../../core/providers/profile_provider.dart';
import '../../dashboard/widgets/avatar_badge.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;
  String? _gender;
  DateTime? _dob;
  String? _avatarPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider);
    _nameCtrl = TextEditingController(text: p.name);
    _ageCtrl = TextEditingController(text: p.age?.toString() ?? '');
    _gender = p.gender;
    _dob = p.dob;
    _avatarPath = p.avatarPath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (file == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final dest =
          File('${dir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await File(file.path).copy(dest.path);
      // Clean up previous avatar if stored locally
      if (_avatarPath != null && _avatarPath != dest.path) {
        final old = File(_avatarPath!);
        if (await old.exists()) {
          try {
            await old.delete();
          } catch (_) {}
        }
      }
      if (!mounted) return;
      setState(() => _avatarPath = dest.path);
    } catch (_) {
      // ignore — user feedback via lack of image change
    }
  }

  void _showPhotoSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(context.tr('from_gallery')),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: Text(context.tr('from_camera')),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_avatarPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: Text(context.tr('remove_photo')),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _avatarPath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = _dob ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      initialDate: initial,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    final ageText = _ageCtrl.text.trim();
    final age = ageText.isEmpty ? null : int.tryParse(ageText);
    final profile = UserProfile(
      name: _nameCtrl.text.trim(),
      age: age,
      gender: _gender,
      dob: _dob,
      avatarPath: _avatarPath,
    );
    await ref.read(profileProvider.notifier).update(profile);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('profile_saved'))),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('edit_profile'))),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Stack(
                  children: [
                    Hero(
                      tag: 'profile-avatar',
                      child: AvatarBadge(
                        profile: UserProfile(
                          name: _nameCtrl.text,
                          avatarPath: _avatarPath,
                        ),
                        size: 120,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: cs.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _showPhotoSheet,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.camera_alt_rounded,
                                color: cs.onPrimary, size: 20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton.icon(
                  onPressed: _showPhotoSheet,
                  icon: const Icon(Icons.image_rounded),
                  label: Text(context.tr('change_photo')),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameCtrl,
                maxLength: 30,
                decoration: InputDecoration(
                  labelText: context.tr('name'),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  counterText: '',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r"[\p{L} ]", unicode: true)),
                ],
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return context.tr('name_required');
                  if (t.length > 30) return context.tr('name_too_long');
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.tr('age'),
                  prefixIcon: const Icon(Icons.cake_outlined),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = int.tryParse(v);
                  if (n == null || n < 1 || n > 120) {
                    return '1-120';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: context.tr('gender'),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    isExpanded: true,
                    value: _gender,
                    hint: Text(context.tr('not_set')),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(context.tr('not_set')),
                      ),
                      for (final g in [
                        'male',
                        'female',
                        'other',
                        'prefer_not'
                      ])
                        DropdownMenuItem(
                          value: g,
                          child: Text(context.tr('gender_$g')),
                        ),
                    ],
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickDob,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_rounded,
                            color: cs.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('date_of_birth'),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                              Text(
                                _dob == null
                                    ? context.tr('not_set')
                                    : DateFormat.yMMMMd().format(_dob!),
                                style:
                                    Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                        if (_dob != null)
                          IconButton(
                            onPressed: () => setState(() => _dob = null),
                            icon: const Icon(Icons.clear_rounded),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(context.tr('save')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
