import 'dart:async';

import 'package:dio/dio.dart';

import '../dio_scope_registry.dart';
import '../crash/crash_reporter.dart';
import '../logging/log_level.dart';
import 'failure.dart';
import 'failure_messages.dart';
import 'result.dart';

/// Failure types that are normal, expected app states rather than bugs. These
/// are surfaced to the user and the debug console but are **not** forwarded to
/// the [CrashReporter], keeping crash reports signal-rich.
const Set<FailureType> kExpectedFailureTypes = {
  FailureType.network,
  FailureType.timeout,
  FailureType.cancellation,
  FailureType.unauthorized,
  FailureType.forbidden,
  FailureType.notFound,
  FailureType.badRequest,
};

/// Mix into a repository implementation to get [safeCall].
///
/// ```dart
/// class OrdersRepoImpl with SafeApiCall implements OrdersRepo {
///   OrdersRepoImpl(this._ds);
///   final OrdersRemoteDataSource _ds;
///
///   @override
///   Future<Result<List<OrderEntity>>> getOrders() =>
///       safeCall(() async => _mapper.map(await _ds.getOrders()));
/// }
/// ```
///
/// The [crashReporter] and [failureMessages] default to whatever was registered
/// via `DioScope.init`; override the getters if a repo needs something specific.
mixin SafeApiCall {
  /// The crash reporter used for genuine-bug failures.
  CrashReporter get crashReporter => DioScopeRegistry.crashReporter;

  /// The messages used to build default [Failure] copy.
  FailureMessages get failureMessages => DioScopeRegistry.messages;

  /// Runs [action], converting any throw into a [FailureResult].
  Future<Result<T>> safeCall<T>(Future<T> Function() action) =>
      _guard(action, crashReporter, failureMessages);
}

/// Standalone equivalent of [SafeApiCall.safeCall] for code that cannot mix in.
///
/// ```dart
/// final result = await safeApiCall(() => api.get('/me'));
/// ```
Future<Result<T>> safeApiCall<T>(
  Future<T> Function() action, {
  CrashReporter? crashReporter,
  FailureMessages? messages,
}) => _guard(
  action,
  crashReporter ?? DioScopeRegistry.crashReporter,
  messages ?? DioScopeRegistry.messages,
);

Future<Result<T>> _guard<T>(
  Future<T> Function() action,
  CrashReporter reporter,
  FailureMessages messages,
) async {
  try {
    return Result.ok(await action());
  } on DioException catch (e) {
    final failure =
        DioScopeRegistry.dioFailureMapper?.call(e, messages) ??
        Failure.fromDioException(e, messages: messages);
    _report(failure, e, e.stackTrace, reporter);
    return Result.error(failure);
  } on FormatException catch (e, s) {
    final failure = Failure.parsing(e, stackTrace: s, messages: messages);
    _report(failure, e, s, reporter);
    return Result.error(failure);
  } on TypeError catch (e, s) {
    // Almost always a bad `fromJson` cast — treat as a parsing failure.
    final failure = Failure.parsing(e, stackTrace: s, messages: messages);
    _report(failure, e, s, reporter);
    return Result.error(failure);
  } catch (e, s) {
    final failure = Failure.unknown(e, stackTrace: s, messages: messages);
    _report(failure, e, s, reporter);
    return Result.error(failure);
  }
}

void _report(
  Failure failure,
  Object error,
  StackTrace? stack,
  CrashReporter reporter,
) {
  // Log every failure (expected states included) to the dev output.
  DioScopeRegistry.logger.log(
    LogLevel.error,
    failure.message,
    error: error,
    stackTrace: stack,
    tag: 'safeCall',
  );

  // Always surface to the in-app console (no-op when the console is disabled).
  DioScopeRegistry.errorSink?.call(error, stack, failure: failure);

  // Forward only genuine bugs to the crash reporter, as non-fatals.
  if (kExpectedFailureTypes.contains(failure.type)) return;

  String? endpoint;
  final details = failure.details;
  if (details is DioException) {
    final options = details.requestOptions;
    endpoint = '${options.method} ${options.path}'.trim();
  }

  unawaited(
    reporter.recordError(
      error,
      stack ?? failure.stackTrace,
      reason: failure.message,
      information: {
        'failureType': failure.type.name,
        if (failure.statusCode != null) 'statusCode': failure.statusCode,
        if (endpoint != null) 'endpoint': endpoint,
      },
    ),
  );
}
