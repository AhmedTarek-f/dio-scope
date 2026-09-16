## 0.1.0

Initial release.

- **Networking** — `ApiClient` abstraction with a fully-configurable `DioApiClient`
  (`ApiClientConfig`: base URL, timeouts, default headers, interceptors, raw
  `Dio` override) and all verbs (`get`/`post`/`put`/`patch`/`delete`) returning a
  transport-agnostic `ApiResponse`. `HeaderInterceptor` for static/dynamic/auth
  headers.
- **Error boundary** — `safeCall` (mixin `SafeApiCall` + standalone
  `safeApiCall`) returning a sealed `Result` (`OkResult`/`FailureResult`), a
  single `Failure`/`FailureType` model with overridable `FailureMessages`, and a
  `BaseStatus<T>` BLoC state cell.
- **Crash reporting** — pluggable `CrashReporter` (no-op by default; ships a
  copy-paste Firebase Crashlytics adapter) with an "expected vs bug" filter, plus
  a global error guard (`installDioScopeErrorHandling`, `runDioScopeGuarded`).
- **Logging** — a pluggable `DioScopeLogger` (default `DefaultDioScopeLogger`
  via `dart:developer`) that logs every captured error (safeCall failures,
  uncaught framework/async errors, `recordError`) and all `DioScope.log` calls;
  errors also mirror into the console Logs tab.
- **Debug console** — a draggable launcher and a dark, DevTools-style console
  with Network, Logs, Errors and System tabs, request/error detail sheets, and
  environment-based visibility (`debug` / `nonRelease` / `always` / `disabled`).
