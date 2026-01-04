class Result<T> {
  final T? data;
  final String? error;
  const Result.ok(this.data) : error = null;
  const Result.err(this.error) : data = null;
  bool get isOk => error == null;
}
