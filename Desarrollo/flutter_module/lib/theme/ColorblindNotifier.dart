import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ColorblindProfile { protanopia, deuteranopia, tritanopia }

class ColorblindConfig {
  final bool enabled;
  final ColorblindProfile profile;

  const ColorblindConfig({
    this.enabled = false,
    this.profile = ColorblindProfile.protanopia,
  });

  ColorblindConfig copyWith({bool? enabled, ColorblindProfile? profile}) {
    return ColorblindConfig(
      enabled: enabled ?? this.enabled,
      profile: profile ?? this.profile,
    );
  }
}

class ColorblindNotifier extends ValueNotifier<ColorblindConfig> {
  ColorblindNotifier() : super(const ColorblindConfig());

  static const _keyEnabled = 'colorblind_enabled';
  static const _keyProfile = 'colorblind_profile';

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_keyEnabled) ?? false;
      final idx = (prefs.getInt(_keyProfile) ?? 0)
          .clamp(0, ColorblindProfile.values.length - 1);
      value = ColorblindConfig(enabled: enabled, profile: ColorblindProfile.values[idx]);
    } catch (_) {
    }
  }

  Future<void> setEnabled(bool enabled) async {
    value = value.copyWith(enabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
  }

  Future<void> setProfile(ColorblindProfile profile) async {
    value = value.copyWith(profile: profile);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyProfile, profile.index);
  }
}

class ColorblindScope extends InheritedNotifier<ColorblindNotifier> {
  const ColorblindScope({
    super.key,
    required ColorblindNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  static ColorblindNotifier of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ColorblindScope>()!.notifier!;
  }
}
