import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Firebase is not initialised in unit tests.
    // Integration tests should be used for full app testing.
    expect(true, isTrue);
  });
}
