import 'package:flutter_test/flutter_test.dart';
import 'package:vision_measure/core/constants/snellen_data.dart';

void main() {
  test('snellenRows has 7 progressively smaller entries', () {
    expect(snellenRows.length, 7);
    for (var i = 1; i < snellenRows.length; i++) {
      expect(
        snellenRows[i].size <= snellenRows[i - 1].size,
        true,
        reason: 'row $i should be <= row ${i - 1}',
      );
    }
  });

  test('estimatedSphereForAcuity returns expected mapping', () {
    expect(estimatedSphereForAcuity('6/6'), 0.0);
    expect(estimatedSphereForAcuity('6/12'), -1.0);
    expect(estimatedSphereForAcuity('6/60'), -4.5);
    expect(estimatedSphereForAcuity('unknown'), 0.0);
  });
}
