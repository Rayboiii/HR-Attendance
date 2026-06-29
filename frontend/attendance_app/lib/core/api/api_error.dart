import 'package:dio/dio.dart';

/// Extracts a human-readable message from an API failure. Understands the
/// ProblemDetails / validation-error shapes the backend returns.
String apiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is Map<String, dynamic>) {
        final messages = errors.values
            .expand((v) => v is List ? v : [v])
            .map((v) => v.toString())
            .where((v) => v.isNotEmpty);
        if (messages.isNotEmpty) return messages.join('\n');
      }
      if (data['detail'] is String) return data['detail'] as String;
      if (data['title'] is String) return data['title'] as String;
    }
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        'The server took too long to respond.',
      DioExceptionType.connectionError =>
        'Could not reach the server. Is the API running?',
      _ => error.message ?? 'Something went wrong.',
    };
  }
  return error.toString();
}
