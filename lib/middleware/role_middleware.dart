import 'package:shelf/shelf.dart';
import 'dart:convert';

//kiểm tra quyền admin
Middleware adminMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final user = request.context['user'] as Map<String, dynamic>?;

      if (user == null || user['role'] != 'admin') {
        return Response(403,
            body: jsonEncode({'message': 'Quyền truy cập bị từ chối. Chỉ dành cho Admin.'}),
            headers: {'content-type': 'application/json'}
        );
      }

      return await innerHandler(request);
    };
  };
}