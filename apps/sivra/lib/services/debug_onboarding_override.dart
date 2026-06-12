import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DebugOnboardingOverride {
  DebugOnboardingOverride._();

  static const _keyPrefix = 'debug_force_onboarding_';

  static Future<bool> isEnabledFor(String uid) async {
    if (!kDebugMode) {
      return false;
    }

    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool('$_keyPrefix$uid') ?? false;
  }

  static Future<void> enableFor(String uid) async {
    if (!kDebugMode) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('$_keyPrefix$uid', true);
  }

  static Future<void> clearFor(String uid) async {
    if (!kDebugMode) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('$_keyPrefix$uid');
  }
}
