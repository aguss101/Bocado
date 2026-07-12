import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_module/theme/App.dart';
import 'package:flutter_module/theme/ColorblindNotifier.dart';

void main() {
  group('ColorToken.resolve', () {
    test('devuelve el color base cuando el modo daltónico está apagado', () {
      const config = ColorblindConfig(enabled: false, profile: ColorblindProfile.protanopia);
      expect(BocadoPalette.error.resolve(config), BocadoPalette.error.base);
      expect(BocadoPalette.primary.resolve(config), BocadoPalette.primary.base);
    });

    test('devuelve la variante correcta por cada perfil cuando está encendido', () {
      expect(
        BocadoPalette.error.resolve(const ColorblindConfig(enabled: true, profile: ColorblindProfile.protanopia)),
        BocadoPalette.error.protanopia,
      );
      expect(
        BocadoPalette.error.resolve(const ColorblindConfig(enabled: true, profile: ColorblindProfile.deuteranopia)),
        BocadoPalette.error.deuteranopia,
      );
      expect(
        BocadoPalette.error.resolve(const ColorblindConfig(enabled: true, profile: ColorblindProfile.tritanopia)),
        BocadoPalette.error.tritanopia,
      );
    });

    test('premium y rating divergen cuando el modo está encendido', () {
      const config = ColorblindConfig(enabled: true, profile: ColorblindProfile.protanopia);
      expect(
        BocadoPalette.premium.resolve(config) == BocadoPalette.rating.resolve(config),
        isFalse,
      );
    });
  });

  group('cvdNeutral', () {
    test('no altera el color cuando el modo está apagado', () {
      const base = Color(0xFF3D3732);
      expect(cvdNeutral(base, const ColorblindConfig(enabled: false)), base);
    });

    test('preserva la luminancia (solo rota el tono) cuando está encendido', () {
      const base = Color(0xFFE8CCB1);
      final resultado = cvdNeutral(base, const ColorblindConfig(enabled: true, profile: ColorblindProfile.protanopia));
      expect(
        HSLColor.fromColor(resultado).lightness,
        closeTo(HSLColor.fromColor(base).lightness, 0.001),
      );
    });
  });
}
