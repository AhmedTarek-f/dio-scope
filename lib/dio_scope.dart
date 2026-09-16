/// dio_scope — a fully-customizable Dio HTTP client with a `safeCall` error
/// boundary, sealed `Result`/`Failure`/`BaseStatus` types, a decoupled
/// crash-reporting hook, and an optional in-app debug console
/// (Network / Logs / Errors / System).
///
/// Import this single library to access the whole public API:
///
/// ```dart
/// import 'package:dio_scope/dio_scope.dart';
/// ```
library;

// Selected Dio re-exports so consumers don't need to depend on Dio directly.
export 'package:dio/dio.dart'
    show
        Dio,
        Interceptor,
        InterceptorsWrapper,
        QueuedInterceptorsWrapper,
        RequestOptions,
        ResponseType,
        Options,
        CancelToken,
        DioException,
        DioExceptionType,
        ProgressCallback,
        MultipartFile,
        FormData;

// --- dio_scope public API (exports added per build phase) ---
// errors/
export 'src/errors/result.dart';
export 'src/errors/failure.dart';
export 'src/errors/failure_messages.dart';
export 'src/errors/safe_call.dart';
// state/
export 'src/state/base_status.dart';
// logging/
export 'src/logging/log_level.dart' show LogLevel;
export 'src/logging/dio_scope_logger.dart'
    show DioScopeLogger, DefaultDioScopeLogger, SilentDioScopeLogger;
// crash/
export 'src/crash/crash_reporter.dart';
// network/
export 'src/network/api_response.dart';
export 'src/network/api_client.dart';
export 'src/network/api_client_config.dart';
export 'src/network/dio_api_client.dart';
export 'src/network/interceptors/header_interceptor.dart';
export 'src/crash/error_guard.dart';
// console/
export 'src/console/dio_scope.dart';
export 'src/console/visibility.dart';
export 'src/console/config.dart';
export 'src/console/data/system_info_collector.dart'
    show SystemInfoCollector, SystemInfoGroup, SystemInfoRow, SystemValueStyle;
export 'src/console/models/log_entry.dart' show LogEntry;
export 'src/console/models/error_entry.dart' show ErrorSeverity, ErrorEntry;
export 'src/console/models/network_entry.dart' show NetworkEntry;
export 'src/console/ui/launcher/dio_scope_overlay.dart';
