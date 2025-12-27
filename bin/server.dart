import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import '../lib/routes/api_router.dart';
import '../lib/middleware/error_handler.dart';

void main() async {
  final apiRouter = ApiRouter();

  final handler = Pipeline()
      .addMiddleware(globalErrorHandler())
      .addMiddleware(logRequests())
      .addMiddleware((innerHandler) {
    return (request) async {
      // Xử lý Pre-flight request cho Trình duyệt (CORS)
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
        });
      }
      final response = await innerHandler(request);
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
        'content-type': 'application/json',
      });
    };
  })
      .addHandler(apiRouter.router.call);

  // Lắng nghe trên anyIPv4 để chấp nhận kết nối từ mọi nguồn
  final server = await serve(handler, InternetAddress.anyIPv4, 8080);

  print('====================================================');
  print('🚀 SERVER ĐANG CHẠY TẠI: http://localhost:${server.port}');
  print('🆔 MSV: 2151170554');
  print('====================================================');
}