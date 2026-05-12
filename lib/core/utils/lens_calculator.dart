class LensCalculationResult {
  final double odSphericalEquivalent;
  final double osSphericalEquivalent;
  final String odClassification; // 'myopia' | 'hyperopia' | 'astigmatism' | 'emmetropia'
  final String osClassification;
  final String recommendedLensType; // 'single_vision' | 'bifocal' | 'toric'

  const LensCalculationResult({
    required this.odSphericalEquivalent,
    required this.osSphericalEquivalent,
    required this.odClassification,
    required this.osClassification,
    required this.recommendedLensType,
  });
}

class LensCalculator {
  /// Spherical Equivalent = Sphere + (Cylinder / 2)
  static double sphericalEquivalent(double sphere, double cylinder) {
    return sphere + (cylinder / 2.0);
  }

  static String classify(double sphere, double cylinder) {
    final absCyl = cylinder.abs();
    if (absCyl >= 0.75 && sphere.abs() < 0.25) {
      return 'astigmatism';
    }
    if (absCyl >= 0.75) {
      // mixed but dominant astigmatism
      return 'astigmatism';
    }
    if (sphere <= -0.25) return 'myopia';
    if (sphere >= 0.25) return 'hyperopia';
    return 'emmetropia';
  }

  static String recommendLensType({
    required double odSphere,
    required double odCylinder,
    required double osSphere,
    required double osCylinder,
    int? age,
  }) {
    final anyAstig = odCylinder.abs() >= 0.75 || osCylinder.abs() >= 0.75;
    if (anyAstig) return 'toric';
    if ((age ?? 0) >= 40) return 'bifocal';
    return 'single_vision';
  }

  static LensCalculationResult calculate({
    required double odSphere,
    required double odCylinder,
    required double osSphere,
    required double osCylinder,
    int? age,
  }) {
    return LensCalculationResult(
      odSphericalEquivalent: sphericalEquivalent(odSphere, odCylinder),
      osSphericalEquivalent: sphericalEquivalent(osSphere, osCylinder),
      odClassification: classify(odSphere, odCylinder),
      osClassification: classify(osSphere, osCylinder),
      recommendedLensType: recommendLensType(
        odSphere: odSphere,
        odCylinder: odCylinder,
        osSphere: osSphere,
        osCylinder: osCylinder,
        age: age,
      ),
    );
  }

  static String classificationLabel(String key) {
    switch (key) {
      case 'myopia':
        return 'Myopia (nearsighted)';
      case 'hyperopia':
        return 'Hyperopia (farsighted)';
      case 'astigmatism':
        return 'Astigmatism';
      case 'emmetropia':
        return 'Emmetropia (normal)';
      default:
        return key;
    }
  }

  static String lensTypeLabel(String key) {
    switch (key) {
      case 'single_vision':
        return 'Single vision lenses';
      case 'bifocal':
        return 'Bifocal lenses';
      case 'toric':
        return 'Toric lenses (for astigmatism)';
      default:
        return key;
    }
  }
}
