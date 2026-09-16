import 'package:flutter_test/flutter_test.dart';

import 'package:dio_scope_example/main.dart';

void main() {
  testWidgets('renders the example home page', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    // Use pump (not pumpAndSettle) because the launcher runs looping animations.
    await tester.pump();
    expect(find.text('dio_scope example'), findsWidgets);
  });
}
