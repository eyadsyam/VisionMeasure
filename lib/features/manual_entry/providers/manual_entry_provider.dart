import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/lens_calculator.dart';

class ManualEntryState {
  final double odSphere;
  final double odCylinder;
  final double odAxis;
  final double osSphere;
  final double osCylinder;
  final double osAxis;
  final int? age;

  const ManualEntryState({
    this.odSphere = 0,
    this.odCylinder = 0,
    this.odAxis = 90,
    this.osSphere = 0,
    this.osCylinder = 0,
    this.osAxis = 90,
    this.age,
  });

  ManualEntryState copyWith({
    double? odSphere,
    double? odCylinder,
    double? odAxis,
    double? osSphere,
    double? osCylinder,
    double? osAxis,
    int? age,
  }) {
    return ManualEntryState(
      odSphere: odSphere ?? this.odSphere,
      odCylinder: odCylinder ?? this.odCylinder,
      odAxis: odAxis ?? this.odAxis,
      osSphere: osSphere ?? this.osSphere,
      osCylinder: osCylinder ?? this.osCylinder,
      osAxis: osAxis ?? this.osAxis,
      age: age ?? this.age,
    );
  }

  LensCalculationResult calculate() {
    return LensCalculator.calculate(
      odSphere: odSphere,
      odCylinder: odCylinder,
      osSphere: osSphere,
      osCylinder: osCylinder,
      age: age,
    );
  }
}

class ManualEntryNotifier extends StateNotifier<ManualEntryState> {
  ManualEntryNotifier() : super(const ManualEntryState());

  void update(ManualEntryState Function(ManualEntryState) reducer) {
    state = reducer(state);
  }

  void reset() => state = const ManualEntryState();
}

final manualEntryProvider =
    StateNotifierProvider<ManualEntryNotifier, ManualEntryState>(
  (ref) => ManualEntryNotifier(),
);
