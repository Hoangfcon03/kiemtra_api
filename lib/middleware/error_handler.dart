import 'package:shelf/shelf.dart';
import 'dart:convert';

Middleware globalErrorHandler() {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Lỗi hệ thống', 'student_id': '2151170554'}),
          headers: {'content-type': 'application/json'},
        );
      }
    };
  };
}