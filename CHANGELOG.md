## 0.2.0

Pluggable, per-project error model — `Failure` is no longer a fixed shape.

- **`Failure.code`** — an optional free-form domain sub-category (e.g.
  `'STORE_CLOSED'`) the coarse `FailureType` enum can't express. Set it from a
  `dioFailureMapper`, switch on it in your UI. Included in `Failure` equality.
- **`Failure.endpoint`** — `<METHOD> <path>`, now auto-filled by
  `Failure.fromDioException` and forwarded to the crash reporter as an
  `endpoint` key (previously derived only inside `safeCall`).
- **`Failure.extra`** — a `Map<String, Object?>` bag for presentation data the
  package stays decoupled from (e.g. an illustration/animation asset).
- **Configurable expected-failure filter** — `DioScope.init(isExpectedFailure:)`
  overrides the default `kExpectedFailureTypes` membership, so a domain
  `Failure.code` (not just a `FailureType`) can be treated as an expected state
  and kept out of crash reports.
- Console error rows now surface `code` (subtitle) and `endpoint` (source).

All additions are optional and backward-compatible; `kExpectedFailureTypes`
moved from `safe_call.dart` to `failure.dart` (same export, same value).

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
