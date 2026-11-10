// Result<Failure, Achievement>
// Error<Failure, Exception>
// Success<Achievement>

sealed class Result<ErrorType, SuccessResult> {
  bool get isError;
  bool get isSuccess;
}

class Error<ErrorType, SuccessResult> extends Result<ErrorType, SuccessResult> {
  final ErrorType errorType;
  final Exception? exception;

  Error({required this.errorType, this.exception});

  @override
  bool get isError => true;

  @override
  bool get isSuccess => false;
}

class Success<ErrorReason, SuccessOutput>
    extends Result<ErrorReason, SuccessOutput> {
  final SuccessOutput result;
  Success({required this.result});

  @override
  bool get isError => false;

  @override
  bool get isSuccess => true;
}
