class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isUnprocessable => statusCode == 422;
  bool get isServerError => statusCode >= 500;
  bool get isNetworkError => statusCode == 0;

  @override
  String toString() {
    return 'ApiException($statusCode): $message';
  }
}
