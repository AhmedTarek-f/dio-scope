import '../errors/failure.dart';

/// A sealed, four-state cell for representing an async operation inside a
/// BLoC/Cubit state (or any `ValueNotifier`): [StatusInit], [StatusLoading],
/// [StatusSuccess], [StatusError].
///
/// It carries a `late` [data] payload so a loading state can retain the
/// previously-loaded data (read it safely via [dataOrNull]). This is
/// dependency-free — it does not import `flutter_bloc`.
///
/// ```dart
/// emit(state.copyWith(orders: BaseStatus.loading(data: state.orders.dataOrNull)));
/// final result = await repo.getOrders();
/// emit(state.copyWith(orders: result.when(
///   onOk: BaseStatus.success,
///   onError: BaseStatus.error,
/// )));
/// ```
sealed class BaseStatus<T> {
  /// The payload. May be unset for [StatusInit]/[StatusLoading]; always read
  /// through [dataOrNull] unless you know the state is [StatusSuccess].
  late T data;

  /// Base constructor.
  BaseStatus();

  /// Whether this is [StatusLoading].
  bool get isLoading => this is StatusLoading<T>;

  /// Whether this is [StatusInit].
  bool get isInit => this is StatusInit<T>;

  /// Whether this is [StatusSuccess].
  bool get isSuccess => this is StatusSuccess<T>;

  /// Whether this is [StatusError].
  bool get isError => this is StatusError<T>;

  /// The failure if this is [StatusError], otherwise `null`.
  Failure? get error =>
      this is StatusError<T> ? (this as StatusError<T>).failure : null;

  /// The payload if set, otherwise `null` (never throws on unset `late`).
  T? get dataOrNull {
    try {
      return data;
    } catch (_) {
      return null;
    }
  }

  /// Creates an initial status, optionally seeded with [data].
  factory BaseStatus.init({T? data}) => StatusInit<T>(data: data);

  /// Creates a loading status, optionally retaining previous [data].
  factory BaseStatus.loading({T? data}) => StatusLoading<T>(data: data);

  /// Creates a success status with [data].
  factory BaseStatus.success(T data) => StatusSuccess<T>(data: data);

  /// Creates an error status from a [Failure].
  factory BaseStatus.error(Failure failure) => StatusError<T>(failure: failure);

  /// Exhaustively folds all four states into a value of type [R].
  R when<R>({
    required R Function(T? data) onInit,
    required R Function(T? data) onLoading,
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onError,
  }) => switch (this) {
    StatusInit<T>() => onInit(dataOrNull),
    StatusLoading<T>() => onLoading(dataOrNull),
    StatusSuccess<T>(:final data) => onSuccess(data),
    StatusError<T>(:final failure) => onError(failure),
  };
}

/// The initial, not-yet-started status.
final class StatusInit<T> extends BaseStatus<T> {
  /// Creates an init status, optionally seeded with [data].
  StatusInit({T? data}) {
    if (data != null) this.data = data;
  }
}

/// The in-progress status. May retain previously-loaded [data].
final class StatusLoading<T> extends BaseStatus<T> {
  /// Creates a loading status, optionally retaining previous [data].
  StatusLoading({T? data}) {
    if (data != null) this.data = data;
  }
}

/// The successful status, always carrying [data].
final class StatusSuccess<T> extends BaseStatus<T> {
  /// Creates a success status with [data].
  StatusSuccess({required T data}) {
    this.data = data;
  }
}

/// The failed status, carrying a [failure].
final class StatusError<T> extends BaseStatus<T> {
  /// The failure describing what went wrong.
  final Failure failure;

  /// Creates an error status from [failure].
  StatusError({required this.failure});
}
