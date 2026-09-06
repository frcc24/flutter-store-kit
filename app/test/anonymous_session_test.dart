import 'package:flutter_test/flutter_test.dart';
import 'package:mini_sudoku/core/auth/anonymous_session.dart';

void main() {
  test('without Firebase every answer is null and nothing throws', () async {
    final session = AnonymousSession(auth: null);
    expect(await session.uid(), isNull);
    expect(await session.idToken(), isNull);
    await session.deleteUser();
  });
}
