class Result<T> {
  final T? data;
  final String? error;
  const Result._({this.data, this.error});
  bool get isSuccess => error == null;
  static Result<T> success<T>(T data) => Result._(data: data);
  static Result<T> failure<T>(String message) => Result._(error: message);
}
