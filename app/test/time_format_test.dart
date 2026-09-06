import 'package:flutter_test/flutter_test.dart';
import 'package:mini_sudoku/core/time_format.dart';

void main() {
  test('formats milliseconds as mm:ss', () {
    expect(formatElapsed(0), '00:00');
    expect(formatElapsed(65000), '01:05');
    expect(formatElapsed(3599999), '59:59');
    expect(formatElapsed(3600000), '60:00');
  });
}
