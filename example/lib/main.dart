import 'package:dio_scope/dio_scope.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// OPTIONAL: Firebase Crashlytics adapter.
//
// dio_scope has NO Firebase dependency. To send crashes to Crashlytics, add
// `firebase_crashlytics` to *your* app and copy this ~15-line adapter, then
// pass it to `DioScope.init(crashReporter: FirebaseCrashReporter())` below.
//
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
//
// class FirebaseCrashReporter implements CrashReporter {
//   final _c = FirebaseCrashlytics.instance;
//   @override
//   Future<void> recordError(Object error, StackTrace? stack,
//       {String? reason, bool fatal = false, Map<String, Object?>? information}) async {
//     if (information != null) {
//       for (final e in information.entries) {
//         await _c.setCustomKey(e.key, '${e.value}');
//       }
//     }
//     await _c.recordError(error, stack, reason: reason, fatal: fatal);
//   }
//   @override
//   Future<void> log(String message) => _c.log(message);
//   @override
//   Future<void> setCustomKey(String key, Object value) => _c.setCustomKey(key, value);
//   @override
//   Future<void> setUserIdentifier(String id) => _c.setUserIdentifier(id);
// }
// ---------------------------------------------------------------------------

void main() {
  // Run everything in a guarded zone so uncaught async errors are captured.
  runDioScopeGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();

    DioScope.init(
      // Demo: force the console on in every build mode. In a real app use
      // `DioScopeVisibility.debug` (or `nonRelease`), optionally with a `gate`.
      visibility: DioScopeVisibility.always,
      // crashReporter: FirebaseCrashReporter(),
      environment: 'development',
      console: const DebugConsoleOptions(accent: DioScopeAccent.blue),
    );

    // Route uncaught framework + platform errors to the console + reporter.
    installDioScopeErrorHandling();

    DioScope.setFcmToken(
      'demo:cVX9k2f7Qe-Sample-FCM-Token-0000-1111-2222-3333-4444-5555',
    );
    DioScope.log('App started in development mode', tag: 'boot');

    runApp(const ExampleApp());
  });
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'dio_scope example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      // Float the debug launcher above every route.
      builder: (context, child) => DioScopeOverlay(child: child!),
      home: const HomePage(),
    );
  }
}

/// A tiny "data layer" showing the intended usage: a [DioApiClient] behind an
/// [ApiClient], wrapped by [safeApiCall] to produce a [Result].
class DemoApi {
  final ApiClient _client = DioApiClient(
    const ApiClientConfig(baseUrl: 'https://jsonplaceholder.typicode.com/'),
  );

  Future<Result<List<dynamic>>> loadPosts() =>
      safeApiCall(() async => (await _client.get('/posts')).data as List);

  Future<Result<dynamic>> loadMissing() =>
      safeApiCall(() async => (await _client.get('/posts/99999999')).data);

  Future<Result<dynamic>> createPost() => safeApiCall(
    () async => (await _client.post(
      '/posts',
      data: {'title': 'dio_scope', 'body': 'hello world', 'userId': 1},
    )).data,
  );

  Future<Result<dynamic>> serverError() => safeApiCall(
    () async => (await _client.get('https://httpbin.org/status/500')).data,
  );

  Future<Result<dynamic>> timeout() => safeApiCall(
    () async => (await _client.get(
      'https://httpbin.org/delay/5',
      options: Options(receiveTimeout: const Duration(seconds: 2)),
    )).data,
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _api = DemoApi();
  String _status = 'Tap a button, then open the debug console (bug button).';

  Future<void> _run(String label, Future<Result<dynamic>> Function() call) async {
    setState(() => _status = '$label…');
    final result = await call();
    if (!mounted) return;
    setState(() {
      _status = result.when(
        onOk: (data) {
          final preview = data is List ? '${data.length} items' : '$data';
          return '✅ $label → ${preview.length > 80 ? '${preview.substring(0, 80)}…' : preview}';
        },
        onError: (f) => '⚠️ $label → ${f.type.name}: ${f.message}',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('dio_scope example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_status),
            ),
          ),
          const SizedBox(height: 16),
          _section('Requests (appear in Network + safeCall)'),
          _btn('GET posts (200)', () => _run('GET posts', _api.loadPosts)),
          _btn('POST post (201)', () => _run('POST post', _api.createPost)),
          _btn('GET missing (404)', () => _run('GET missing', _api.loadMissing)),
          _btn('GET 500 (server)', () => _run('GET 500', _api.serverError)),
          _btn('GET slow (timeout)', () => _run('GET slow', _api.timeout)),
          const SizedBox(height: 16),
          _section('Logs'),
          _btn('Log info', () => DioScope.log('Info log from example', tag: 'demo')),
          _btn('Log warning', () => DioScope.log('Careful!', level: LogLevel.warning, tag: 'demo')),
          _btn('Log error', () => DioScope.log('Something failed', level: LogLevel.error, tag: 'demo')),
          const SizedBox(height: 16),
          _section('Errors'),
          _btn('Record handled error', () {
            try {
              throw const FormatException('Manually recorded error');
            } catch (e, s) {
              DioScope.recordError(e, s, source: 'main.dart:demo');
            }
          }),
          _btn('Throw in callback (framework)', () {
            throw StateError('Uncaught error from a button callback');
          }),
          _btn('Throw async (zone/platform)', () {
            Future<void>(() => throw StateError('Uncaught async error'));
          }),
          const SizedBox(height: 16),
          _section('Console'),
          _btn('Open console', () => DioScope.showConsole(context)),
          const SizedBox(height: 16),
          _section('Navigation (test console back handling)'),
          _btn(
            'Open product details',
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ProductDetailsScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        letterSpacing: 0.6,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );

  Widget _btn(String label, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: FilledButton.tonal(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        alignment: Alignment.centerLeft,
        minimumSize: const Size.fromHeight(48),
      ),
      child: Text(label),
    ),
  );
}

/// A pushed second screen, used to verify that opening the console over it and
/// pressing the system back / edge-swipe closes the *console* — not this screen
/// or the whole app.
class ProductDetailsScreen extends StatelessWidget {
  /// Creates the demo product-details screen.
  const ProductDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Open the debug console (bug button), then press the system back '
          'button or edge-swipe. The console should close and leave this '
          'screen exactly as it is.',
        ),
      ),
    );
  }
}
