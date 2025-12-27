import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'dart:convert';

Middleware authMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['Authorization'];

      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(401, body: jsonEncode({'message': 'Yêu cầu token đăng nhập'}));
      }

      final token = authHeader.substring(7);

      try {
        final payload = JWT.verify(token, SecretKey('2151170554_SECRET_KEY'));
        // Gắn thông tin user vào context để controller sử dụng
        final updatedRequest = request.change(context: {'user': payload.payload});
        return await innerHandler(updatedRequest);
      } catch (e) {
        return Response(401, body: jsonEncode({'message': 'Token không hợp lệ hoặc đã hết hạn'}));
      }
    };
  };
}