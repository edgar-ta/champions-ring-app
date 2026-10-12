// Result<Failure, Achievement>
// Error<Failure, Exception>
// Success<Achievement>

sealed class Result<ErrorType, SuccessResult> {}

class Error<ErrorType, SuccessResult> extends Result<ErrorType, SuccessResult> {
  final ErrorType errorType;
  final Exception? exception;

  Error({required this.errorType, this.exception});
}

class Success<ErrorReason, SuccessOutput>
    extends Result<ErrorReason, SuccessOutput> {
  final SuccessOutput result;
  Success({required this.result});
}
