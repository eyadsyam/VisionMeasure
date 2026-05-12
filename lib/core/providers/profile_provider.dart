import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shared_preferences_provider.dart';

class UserProfile {
  final String name;
  final int? age;
  final String? gender; // 'male' | 'female' | 'other' | 'prefer_not'
  final DateTime? dob;
  final String? avatarPath;
  // Clinical fields
  final bool wearsGlasses;
  final bool wearsContacts;
  final bool hasPreviousConditions;
  final String? previousConditionsNote;
  final bool familyHistoryEyeDisease;

  const UserProfile({
    this.name = '',
    this.age,
    this.gender,
    this.dob,
    this.avatarPath,
    this.wearsGlasses = false,
    this.wearsContacts = false,
    this.hasPreviousConditions = false,
    this.previousConditionsNote,
    this.familyHistoryEyeDisease = false,
  });

  UserProfile copyWith({
    String? name,
    int? age,
    String? gender,
    DateTime? dob,
    String? avatarPath,
    bool? wearsGlasses,
    bool? wearsContacts,
    bool? hasPreviousConditions,
    String? previousConditionsNote,
    bool? familyHistoryEyeDisease,
    bool clearAvatar = false,
    bool clearDob = false,
    bool clearAge = false,
    bool clearGender = false,
    bool clearConditionsNote = false,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: clearAge ? null : (age ?? this.age),
      gender: clearGender ? null : (gender ?? this.gender),
      dob: clearDob ? null : (dob ?? this.dob),
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      wearsGlasses: wearsGlasses ?? this.wearsGlasses,
      wearsContacts: wearsContacts ?? this.wearsContacts,
      hasPreviousConditions:
          hasPreviousConditions ?? this.hasPreviousConditions,
      previousConditionsNote: clearConditionsNote
          ? null
          : (previousConditionsNote ?? this.previousConditionsNote),
      familyHistoryEyeDisease:
          familyHistoryEyeDisease ?? this.familyHistoryEyeDisease,
    );
  }

  int? get effectiveAge {
    if (dob != null) {
      final now = DateTime.now();
      var years = now.year - dob!.year;
      if (now.month < dob!.month ||
          (now.month == dob!.month && now.day < dob!.day)) {
        years--;
      }
      return years;
    }
    return age;
  }

  bool get isComplete =>
      name.isNotEmpty && dob != null && gender != null;
}

class ProfileNotifier extends StateNotifier<UserProfile> {
  final SharedPreferences _prefs;

  ProfileNotifier(this._prefs)
      : super(UserProfile(
          name: _prefs.getString('user_name') ?? '',
          age: _prefs.getInt('user_age'),
          gender: _prefs.getString('user_gender'),
          dob: _prefs.getString('user_dob') != null
              ? DateTime.tryParse(_prefs.getString('user_dob')!)
              : null,
          avatarPath: _prefs.getString('user_avatar_path'),
          wearsGlasses: _prefs.getBool('user_wears_glasses') ?? false,
          wearsContacts: _prefs.getBool('user_wears_contacts') ?? false,
          hasPreviousConditions:
              _prefs.getBool('user_has_prev_conditions') ?? false,
          previousConditionsNote:
              _prefs.getString('user_prev_conditions_note'),
          familyHistoryEyeDisease:
              _prefs.getBool('user_family_history') ?? false,
        ));

  Future<void> update(UserProfile profile) async {
    state = profile;
    await _prefs.setString('user_name', profile.name);
    if (profile.age != null) {
      await _prefs.setInt('user_age', profile.age!);
    } else {
      await _prefs.remove('user_age');
    }
    if (profile.gender != null) {
      await _prefs.setString('user_gender', profile.gender!);
    } else {
      await _prefs.remove('user_gender');
    }
    if (profile.dob != null) {
      await _prefs.setString('user_dob', profile.dob!.toIso8601String());
    } else {
      await _prefs.remove('user_dob');
    }
    if (profile.avatarPath != null) {
      await _prefs.setString('user_avatar_path', profile.avatarPath!);
    } else {
      await _prefs.remove('user_avatar_path');
    }
    // Clinical fields
    await _prefs.setBool('user_wears_glasses', profile.wearsGlasses);
    await _prefs.setBool('user_wears_contacts', profile.wearsContacts);
    await _prefs.setBool(
        'user_has_prev_conditions', profile.hasPreviousConditions);
    if (profile.previousConditionsNote != null) {
      await _prefs.setString(
          'user_prev_conditions_note', profile.previousConditionsNote!);
    } else {
      await _prefs.remove('user_prev_conditions_note');
    }
    await _prefs.setBool(
        'user_family_history', profile.familyHistoryEyeDisease);
  }

  Future<void> clear() async {
    state = const UserProfile();
    await _prefs.remove('user_name');
    await _prefs.remove('user_age');
    await _prefs.remove('user_gender');
    await _prefs.remove('user_dob');
    await _prefs.remove('user_avatar_path');
    await _prefs.remove('user_wears_glasses');
    await _prefs.remove('user_wears_contacts');
    await _prefs.remove('user_has_prev_conditions');
    await _prefs.remove('user_prev_conditions_note');
    await _prefs.remove('user_family_history');
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, UserProfile>(
  (ref) => ProfileNotifier(ref.watch(sharedPreferencesProvider)),
);
