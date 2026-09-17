import 'package:dio_scope/dio_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression tests for the floating-launcher / DioScopeOverlay path:
//   * the launcher must keep opening the console after it has been dragged;
//   * the OS back gesture must close the console (or an open sheet/dialog)
//     without touching the host app's own navigation.
//
// Motion is reduced so the launcher's repeating idle animations don't keep the
// pipeline busy; open-console frames are advanced with explicit pumps rather
// than pumpAndSettle for the same reason.

final _bugButton = find.byIcon(Icons.bug_report);
const _consoleTitle = 'Debug Console';

/// Delivers a platform `popRoute` — the same signal an Android system-back /
/// edge-swipe raises — so `WidgetsBindingObserver.didPopRoute` observers run.
Future<void> _simulateSystemBack(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.navigation.name,
    SystemChannels.navigation.codec.encodeMethodCall(
      const MethodCall('popRoute'),
    ),
    (_) {},
  );
}

/// Advances past a transition without waiting for idle animations to settle.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Widget _hostApp({GlobalKey<NavigatorState>? navigatorKey}) => MaterialApp(
  navigatorKey: navigatorKey,
  builder: (context, child) => DioScopeOverlay(child: child!),
  home: const Scaffold(body: Center(child: Text('Home'))),
);

void main() {
  setUp(
    () => DioScope.init(
      visibility: DioScopeVisibility.always,
      console: const DebugConsoleOptions(reduceMotion: true),
    ),
  );
  tearDown(DioScope.dispose);

  testWidgets('launcher tap opens the console', (tester) async {
    await tester.pumpWidget(_hostApp());
    await tester.pump();
    expect(_bugButton, findsOneWidget);

    await tester.tap(_bugButton);
    await _settle(tester);

    expect(find.text(_consoleTitle), findsOneWidget);
  });

  testWidgets('launcher still opens the console after being dragged', (
    tester,
  ) async {
    await tester.pumpWidget(_hostApp());
    await tester.pump();

    // Drag the FAB to a new edge. This used to leave the internal drag guard
    // stuck, silently swallowing every later tap until an app restart.
    await tester.drag(_bugButton, const Offset(120, -200));
    await _settle(tester);

    // A clean tap must still open the console.
    await tester.tap(_bugButton);
    await _settle(tester);

    expect(find.text(_consoleTitle), findsOneWidget);
  });

  testWidgets('system back closes the console, not the host app', (
    tester,
  ) async {
    await tester.pumpWidget(_hostApp());
    await tester.pump();

    await tester.tap(_bugButton);
    await _settle(tester);
    expect(find.text(_consoleTitle), findsOneWidget);

    await _simulateSystemBack(tester);
    await _settle(tester);

    // Console dismissed; the host screen is untouched.
    expect(find.text(_consoleTitle), findsNothing);
    expect(find.text('Home'), findsOneWidget);
    // Launcher is back once the console is closed.
    expect(_bugButton, findsOneWidget);
  });

  testWidgets('system back does not pop the host route while the console is open', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(_hostApp(navigatorKey: navigatorKey));
    await tester.pump();

    // Push a second host route (a stand-in for a "Product details" screen).
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const Scaffold(body: Center(child: Text('Product Details'))),
      ),
    );
    await _settle(tester);
    expect(find.text('Product Details'), findsOneWidget);

    await tester.tap(_bugButton);
    await _settle(tester);
    expect(find.text(_consoleTitle), findsOneWidget);

    await _simulateSystemBack(tester);
    await _settle(tester);

    // The console closed; Product details is still on top of the host stack.
    expect(find.text(_consoleTitle), findsNothing);
    expect(find.text('Product Details'), findsOneWidget);
  });

  testWidgets('system back closes an open console dialog before the console', (
    tester,
  ) async {
    await tester.pumpWidget(_hostApp());
    await tester.pump();

    await tester.tap(_bugButton);
    await _settle(tester);
    expect(find.text(_consoleTitle), findsOneWidget);

    // Open the clear-data dialog — it is pushed onto the console's own nested
    // Navigator, so back should pop it before it pops the console.
    await tester.tap(find.byIcon(Icons.delete_outline));
    await _settle(tester);
    expect(find.text('Clear debug data?'), findsOneWidget);

    // First back: dialog closes, console stays.
    await _simulateSystemBack(tester);
    await _settle(tester);
    expect(find.text('Clear debug data?'), findsNothing);
    expect(find.text(_consoleTitle), findsOneWidget);

    // Second back: console closes.
    await _simulateSystemBack(tester);
    await _settle(tester);
    expect(find.text(_consoleTitle), findsNothing);
  });
}
