sealed class DataResult<T> {
  const DataResult();
}

final class Success<T> extends DataResult<T> {
  final T data;
  const Success(this.data);
}

final class Failure<T> extends DataResult<T> {
  final String message;
  final Object? error;
  const Failure(this.message, [this.error]);
}
