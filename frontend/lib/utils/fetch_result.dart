/// Kapselt das Ergebnis eines asynchronen Aufrufs. Ohne Fehler gilt der Abruf
/// als erfolgreich, optionale Daten und Statuscodes können mitgegeben werden.
class FetchResult<T> {
  final T? data;
  final Object? error;
  final int? statusCode;

  const FetchResult._({this.data, this.error, this.statusCode});

  bool get isSuccess => error == null;

  factory FetchResult.success(T data, {int? statusCode}) =>
      FetchResult._(data: data, statusCode: statusCode);

  factory FetchResult.failure(Object error, {int? statusCode}) =>
      FetchResult._(error: error, statusCode: statusCode);
}
