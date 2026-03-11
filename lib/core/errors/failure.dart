/// UI-facing failure; built from [AppException] in providers.
class Failure {
  const Failure(this.message, {this.code, this.recoverable = true});

  final String message;
  final String? code;
  final bool recoverable;
}
