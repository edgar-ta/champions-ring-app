sealed class Result<TSuccess, TFailure> {
  const Result();
}

class Success<TSuccess, TFailure> extends Result<TSuccess, TFailure> {
  final TSuccess data;

  const Success(this.data);
}

class Failure<TSuccess, TFailure> extends Result<TSuccess, TFailure> {
  final TFailure reason;
  final Exception? exception;

  const Failure(this.reason, {this.exception});
}
