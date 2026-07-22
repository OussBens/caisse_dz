// lib/data/models/api_response.dart
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({
    required this.success,
    required this.message,  // ✅ message est requis
    this.data,
  });
}