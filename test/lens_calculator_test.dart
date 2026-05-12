import 'package:flutter_test/flutter_test.dart';
import 'package:vision_measure/core/utils/lens_calculator.dart';

void main() {
  group('LensCalculator.sphericalEquivalent', () {
    test('computes sphere + cyl/2', () {
      expect(LensCalculator.sphericalEquivalent(-1.0, -0.5), -1.25);
      expect(LensCalculator.sphericalEquivalent(2.0, 1.0), 2.5);
      expect(LensCalculator.sphericalEquivalent(0, 0), 0);
    });
  });

  group('LensCalculator.classify', () {
    test('emmetropia near zero', () {
      expect(LensCalculator.classify(0, 0), 'emmetropia');
      expect(LensCalculator.classify(0.1, 0), 'emmetropia');
    });

    test('myopia for negative sphere', () {
      expect(LensCalculator.classify(-0.5, 0), 'myopia');
      expect(LensCalculator.classify(-3.0, -0.25), 'myopia');
    });

    test('hyperopia for positive sphere', () {
      expect(LensCalculator.classify(1.0, 0), 'hyperopia');
    });

    test('astigmatism when cylinder significant', () {
      expect(LensCalculator.classify(0, -1.0), 'astigmatism');
      expect(LensCalculator.classify(-0.5, -1.5), 'astigmatism');
    });
  });

  group('recommendLensType', () {
    test('toric when astigmatism present', () {
      final t = LensCalculator.recommendLensType(
        odSphere: -1.0,
        odCylinder: -1.25,
        osSphere: -0.75,
        osCylinder: 0,
      );
      expect(t, 'toric');
    });

    test('bifocal when age >= 40 without astigmatism', () {
      final t = LensCalculator.recommendLensType(
        odSphere: -1.0,
        odCylinder: 0,
        osSphere: -1.0,
        osCylinder: 0,
        age: 45,
      );
      expect(t, 'bifocal');
    });

    test('single_vision default', () {
      final t = LensCalculator.recommendLensType(
        odSphere: -1.0,
        odCylinder: 0,
        osSphere: -1.0,
        osCylinder: 0,
        age: 20,
      );
      expect(t, 'single_vision');
    });
  });
}
