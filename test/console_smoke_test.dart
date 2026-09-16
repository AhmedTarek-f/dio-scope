import 'package:dio_scope/dio_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Tabs are tapped by their (unique) icons to avoid colliding with the Network
// filter bar's "Errors" chip.
final _logsTab = find.byIcon(Icons.notes);
final _errorsTab = find.byIcon(Icons.warning_amber_rounded);

void main() {
  setUp(() => DioScope.init(visibility: DioScopeVisibility.always));
  tearDown(DioScope.dispose);

  testWidgets('renders empty states and switches tabs', (tester) async {
    final console = DioScope.buildConsole();
    expect(console, isNotNull);
    await tester.pumpWidget(MaterialApp(home: console));
    await tester.pump();

    // Network tab empty state.
    expect(find.text('No network requests yet'), findsOneWidget);

    // Switch to Logs.
    await tester.tap(_logsTab);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('No logs to show'), findsOneWidget);

    // Switch to Errors (success empty state).
    await tester.tap(_errorsTab);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('No errors detected 🎉'), findsOneWidget);
  });

  testWidgets('a captured error shows on the Errors tab badge count', (tester) async {
    DioScope.recordError(
      StateError('boom'),
      StackTrace.current,
      severity: ErrorSeverity.exception,
      title: 'Test error',
    );
    final console = DioScope.buildConsole();
    await tester.pumpWidget(MaterialApp(home: console));
    await tester.pump();

    await tester.tap(_errorsTab);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Test error'), findsOneWidget);
  });
}
