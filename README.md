# dio_scope

A batteries-included networking layer for Flutter: a fully-customizable **Dio**
client, a `safeCall` error boundary with sealed `Result` / `Failure` /
`BaseStatus` types, a **decoupled** crash-reporting hook (Firebase-free), and an
optional in-app **debug console** (Network · Logs · Errors · System) that you can
show in debug, development, or release — or turn off entirely.

```dart
import 'package:dio_scope/dio_scope.dart';
```

## Features

- **One Dio client, fully configurable** — base URL, timeouts, default headers,
  interceptors, or bring your own `Dio`. All verbs (`get`/`post`/`put`/`patch`/
  `delete`) return a transport-agnostic `ApiResponse`; Dio never leaks into your
  data layer.
- **`safeCall`** — wrap a call and get a sealed `Result<T>` (`OkResult` /
  `FailureResult`). Every throw becomes a typed `Failure` (`FailureType` +
  message + status code), with messages you can localize.
- **`BaseStatus<T>`** — an `init`/`loading`/`success`/`error` state cell for your
  Cubits/Blocs (no `flutter_bloc` dependency).
- **Crash reporting, decoupled** — implement `CrashReporter` (a ~15-line Firebase
  Crashlytics adapter is provided) and register it once. Genuine bugs are
  reported; expected states (offline, 401, 404…) are not.
- **In-app debug console** — a draggable launcher opens a dark, DevTools-style
  console: inspect requests (headers, body, timing), stream logs, review captured
  errors with stack traces, and read device/app info.
- **Environment control** — `DioScopeVisibility.debug` / `nonRelease` / `always` /
  `disabled`, plus an optional `gate()` for build flavors or remote flags.

## Install

```yaml
dependencies:
  dio_scope: ^0.2.0
```

## Quick start

```dart
import 'package:dio_scope/dio_scope.dart';
import 'package:flutter/material.dart';

void main() => runDioScopeGuarded(() {
  WidgetsFlutterBinding.ensureInitialized();

  DioScope.init(
    visibility: DioScopeVisibility.nonRelease, // on in debug + profile
    // crashReporter: FirebaseCrashReporter(), // see below
  );
  installDioScopeErrorHandling();

  runApp(const MyApp());
});

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    // Float the debug launcher above every route.
    builder: (context, child) => DioScopeOverlay(child: child!),
    home: const HomePage(),
  );
}
```

## The client + `safeCall` in a repository

```dart
// data source — depends only on ApiClient, never on Dio
class OrdersRemoteDataSource {
  OrdersRemoteDataSource(this._client);
  final ApiClient _client;

  Future<List<OrderModel>> getOrders() async {
    final res = await _client.get('/orders');
    return (res.data['data'] as List).map(OrderModel.fromJson).toList();
  }
}

// repo impl — turn throws into a Result with safeCall
class OrdersRepoImpl with SafeApiCall implements OrdersRepo {
  OrdersRepoImpl(this._ds, this._mapper);
  final OrdersRemoteDataSource _ds;
  final OrdersMapper _mapper;

  @override
  Future<Result<List<OrderEntity>>> getOrders() =>
      safeCall(() async => _mapper.map(await _ds.getOrders()));
}
```

Create the client with as much or as little config as you need:

```dart
final client = DioApiClient(ApiClientConfig(
  baseUrl: 'https://api.example.com/v1/',
  connectTimeout: const Duration(seconds: 30),
  defaultHeaders: {'Accept': 'application/json'},
  interceptors: [
    HeaderInterceptor(
      staticHeaders: {'x-app-origin': 'MOBILE_APP'},
      tokenProvider: () => secureStorage.readToken(), // sync or async
    ),
  ],
  // attachDebugConsole: true (default) auto-adds the console capture interceptor
  // dio: myPreconfiguredDio,   // full override / test seam
));
```

## Consuming a `Result` in a Cubit

```dart
Future<void> loadOrders() async {
  emit(state.copyWith(orders: BaseStatus.loading(data: state.orders.dataOrNull)));
  final result = await _repo.getOrders();
  emit(state.copyWith(orders: result.when(
    onOk: BaseStatus.success,
    onError: BaseStatus.error,
  )));
}
```

`Result` also offers `fold`, `map`, `dataOrNull`, `failureOrNull`, and
`getOrElse`. `Failure` carries `type` (`FailureType`), `message`,
`messageDetails`, `statusCode`, and — for domain semantics the enum can't
express — an optional `code`, an auto-filled `endpoint` (`<METHOD> <path>`), and
a free-form `extra` map (see below).

Customize the copy (e.g. from your l10n) once:

```dart
DioScope.init(
  messages: FailureMessages(
    network: context.l10n.noInternet,
    unauthorized: context.l10n.sessionExpired,
  ),
);
```

## Bring your own error model

`FailureType` stays a small, universal enum (network / timeout / 5xx / 401 /
403 / 404 / 4xx / parsing / cancellation / unknown). Everything project-specific
layers on top, so the same package fits any backend:

- **`dioFailureMapper`** — a total `Failure? Function(DioException, FailureMessages)`.
  `safeCall` calls it first and falls back to `Failure.fromDioException` when it
  returns `null`. Build the whole `Failure` here (localized message via your own
  l10n at call time, `code`, `extra`, …).
- **`Failure.code`** — your domain sub-category (`'STORE_CLOSED'`, `'RATE_LIMITED'`,
  …). Switch on it in the UI; it also flows to the crash reporter.
- **`Failure.extra`** — presentation data the package must not depend on, e.g. an
  illustration to show for this failure.
- **`isExpectedFailure`** — decide what counts as a normal state (kept out of
  crash reports). Defaults to `kExpectedFailureTypes`; widen it to include your
  own `code`s.

```dart
DioScope.init(
  dioFailureMapper: (e, messages) {
    final errorType = (e.response?.data is Map)
        ? e.response!.data['error_type'] as String?
        : null;
    if (errorType == 'STORE_CLOSED') {
      return Failure(
        type: FailureType.badRequest,
        code: 'STORE_CLOSED',
        message: myL10n.storeClosed,          // resolved at call time → localized
        statusCode: e.response?.statusCode,
        details: e,
        extra: {'animation': myAssets.storeClosed},
      );
    }
    return null; // fall back to the built-in mapping
  },
  isExpectedFailure: (f) =>
      kExpectedFailureTypes.contains(f.type) || f.code == 'STORE_CLOSED',
);

// widget layer
final anim = failure.extra['animation'] as MyAsset?;
```

## Debug console visibility

| Visibility | Enabled when |
|---|---|
| `debug` (default) | `kDebugMode` |
| `nonRelease` | debug **and** profile |
| `always` | every build mode |
| `disabled` | never (console inert, capture interceptor is a no-op) |

`gate` is AND-ed with the mode, so you can keep it off until unlocked:

```dart
DioScope.init(visibility: DioScopeVisibility.always, gate: () => prefs.debugUnlocked);
```

Open the console via the floating launcher, or manually with
`DioScope.showConsole(context)`. Feed it data with `DioScope.log(...)`,
`DioScope.recordError(...)`, and `DioScope.setFcmToken(...)`.

## Firebase Crashlytics (or any reporter)

dio_scope has **no** Firebase dependency. Implement `CrashReporter` and register
it — here is the whole Firebase adapter (copy into your app):

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class FirebaseCrashReporter implements CrashReporter {
  final _c = FirebaseCrashlytics.instance;

  @override
  Future<void> recordError(Object error, StackTrace? stack,
      {String? reason, bool fatal = false, Map<String, Object?>? information}) async {
    if (information != null) {
      for (final e in information.entries) {
        await _c.setCustomKey(e.key, '${e.value}');
      }
    }
    await _c.recordError(error, stack, reason: reason, fatal: fatal);
  }

  @override
  Future<void> log(String message) => _c.log(message);
  @override
  Future<void> setCustomKey(String key, Object value) => _c.setCustomKey(key, value);
  @override
  Future<void> setUserIdentifier(String id) => _c.setUserIdentifier(id);
}
```

```dart
DioScope.init(crashReporter: FirebaseCrashReporter());
```

`safeCall` forwards only genuine bugs (server / parsing / unknown) as
**non-fatals**; expected states (network, timeout, cancellation, 401/403/404,
4xx) are skipped so your reports stay signal-rich.

## Global error handling

`installDioScopeErrorHandling()` wires `FlutterError.onError` and
`PlatformDispatcher.instance.onError` to the console Errors tab and the crash
reporter (as **fatal**). `runDioScopeGuarded` adds the `runZonedGuarded` net.

Two gotchas (enforced/di documented by the API):

- **Same-zone rule** — call `WidgetsFlutterBinding.ensureInitialized()` and
  `runApp()` inside `runDioScopeGuarded`'s body (as in Quick Start).
- **Background isolates** — handlers set in `main()` don't exist in a
  `@pragma('vm:entry-point')` isolate (e.g. an FCM background handler); give it
  its own `try/catch` that calls `CrashReporter.recordError`.

For a `BlocObserver`, forward errors yourself:

```dart
class AppBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    DioScope.recordError(error, stackTrace, source: '${bloc.runtimeType}');
    super.onError(bloc, error, stackTrace);
  }
}
```

## Logging

Every error dio_scope captures — `safeCall` failures, uncaught framework/async
errors, and `DioScope.recordError` — is logged through a pluggable
`DioScopeLogger`, and so are your own `DioScope.log(...)` calls. The default
`DefaultDioScopeLogger` writes via `dart:developer.log()` (severity + error
object + stack trace, visible in the IDE/DevTools) and is silent in release by
default (errors still reach the `CrashReporter`).

```dart
DioScope.init(
  logger: DefaultDioScopeLogger(minLevel: LogLevel.debug), // tune, or pass enabled: true for release
  // logger: const SilentDioScopeLogger(),                 // opt out entirely
);
```

Provide your own by implementing `DioScopeLogger` (e.g. wrapping
`package:logger`). Captured errors also stream into the console **Logs** tab at
error level — set `DebugConsoleOptions(logErrorsToConsoleLog: false)` to keep
the Logs tab to your own messages only.

## Notes

- The console is dark-only by design (a neutral developer surface) and bundles
  the **Cairo** and **JetBrains Mono** fonts (SIL OFL 1.1 — see `LICENSE`).
- Runtime dependencies are kept minimal: `dio`, `device_info_plus`,
  `package_info_plus`.

See the [`example/`](example/) app for a runnable demo of everything above.
