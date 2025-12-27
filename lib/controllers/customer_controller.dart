import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../config/database.dart';

class CustomerController {
  // 3.1. Lấy danh sách Customers (Chỉ Admin)
  Future<Response> getAll(Request request) async {
    final conn = await DatabaseConfig.getConnection();
    try {
      final results = await conn.query(
          'SELECT id, email, full_name, phone_number, address, city, is_active, created_at FROM customers'
      );

      final customers = results.map((row) => {
        'id': row['id'],
        'email': row['email'],
        'full_name': row['full_name'],
        'phone_number': row['phone_number'],
        'address': row['address'],
        'city': row['city'],
        'is_active': row['is_active'] == 1,
        'created_at': row['created_at'].toString(),
      }).toList();

      return Response.ok(jsonEncode(customers), headers: {'content-type': 'application/json'});
    } finally {
      await conn.close();
    }
  }

  // 3.2. Lấy Customer theo ID (Admin hoặc chính chủ)
  Future<Response> getById(Request request, String id) async {
    final user = request.context['user'] as Map<String, dynamic>;
    final int targetId = int.parse(id);

    // Kiểm tra quyền: Nếu không phải Admin VÀ không phải chính mình thì từ chối
    if (user['role'] != 'admin' && user['id'] != targetId) {
      return Response(403, body: jsonEncode({'message': 'Bạn không có quyền xem thông tin này'}));
    }

    final conn = await DatabaseConfig.getConnection();
    try {
      final results = await conn.query('SELECT id, email, full_name, phone_number, address, city FROM customers WHERE id = ?', [targetId]);

      if (results.isEmpty) {
        return Response.notFound(jsonEncode({'message': 'Không tìm thấy khách hàng'}));
      }

      return Response.ok(jsonEncode(results.first.fields), headers: {'content-type': 'application/json'});
    } finally {
      await conn.close();
    }
  }

  // 3.3. Cập nhật Customer
  Future<Response> update(Request request, String id) async {
    final user = request.context['user'] as Map<String, dynamic>;
    final int targetId = int.parse(id);

    if (user['role'] != 'admin' && user['id'] != targetId) {
      return Response(403, body: jsonEncode({'message': 'Bạn không có quyền cập nhật thông tin này'}));
    }

    final payload = jsonDecode(await request.readAsString());
    final conn = await DatabaseConfig.getConnection();

    try {
      await conn.query(
          'UPDATE customers SET full_name = ?, phone_number = ?, address = ?, city = ? WHERE id = ?',
          [payload['full_name'], payload['phone_number'], payload['address'], payload['city'], targetId]
      );

      return Response.ok(jsonEncode({'message': 'Cập nhật thành công'}));
    } finally {
      await conn.close();
    }
  }
}