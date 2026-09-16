import 'failure.dart';

/// A sealed success-or-failure type returned by `safeCall`.
///
/// Consume it with a `switch` (exhaustive over [OkResult]/[FailureResult]) or
/// the [when]/[fold]/[map] helpers:
///
/// ```dart
/// final result = await repo.getOrders();
/// switch (result) {
///   case OkResult(:final data): emit(Success(data));
///   case FailureResult(:final failure): emit(Error(failure));
/// }
/// ```
sealed class Result<T> {
  /// Const base constructor for the sealed hierarchy.
  const Result();

  /// A successful result carrying [data].
  const factory Result.ok(T data) = OkResult<T>;

  /// A failed result carrying a [Failure].
  const factory Result.error(Failure failure) = FailureResult<T>;

  /// Whether this is an [OkResult].
  bool get isOk => this is OkResult<T>;

  /// Whether this is a [FailureResult].
  bool get isError => this is FailureResult<T>;

  /// The value if successful, otherwise `null`.
  T? get dataOrNull => switch (this) {
    OkResult<T>(:final data) => data,
    FailureResult<T>() => null,
  };

  /// The failure if this failed, otherwise `null`.
  Failure? get failureOrNull => switch (this) {
    OkResult<T>() => null,
    FailureResult<T>(:final failure) => failure,
  };

  /// Folds both cases into a single value of type [R].
  R when<R>({
    required R Function(T data) onOk,
    required R Function(Failure failure) onError,
  }) => switch (this) {
    OkResult<T>(:final data) => onOk(data),
    FailureResult<T>(:final failure) => onError(failure),
  };

  /// Alias for [when] with the error case first (dartz-style ordering).
  R fold<R>(R Function(Failure failure) onError, R Function(T data) onOk) =>
      when(onOk: onOk, onError: onError);

  /// Transforms the success value, propagating any failure unchanged.
  Result<R> map<R>(R Function(T data) transform) => switch (this) {
    OkResult<T>(:final data) => OkResult<R>(transform(data)),
    FailureResult<T>(:final failure) => FailureResult<R>(failure),
  };

  /// Returns the value if successful, otherwise [fallback].
  T getOrElse(T fallback) => dataOrNull ?? fallback;
}

/// The success variant of [Result].
final class OkResult<T> extends Result<T> {
  /// The successful value.
  final T data;

  /// Creates a success result.
  const OkResult(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is OkResult<T> && other.data == data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'OkResult<$T>($data)';
}

/// The failure variant of [Result].
final class FailureResult<T> extends Result<T> {
  /// The failure describing what went wrong.
  final Failure failure;

  /// Creates a failure result.
  const FailureResult(this.failure);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FailureResult<T> && other.failure == failure;

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'FailureResult<$T>($failure)';
}
