import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../config/database.dart';
import '../utils/validator.dart';

class ProductController {
  // 4.1 & 4.6. Lấy danh sách & Tìm kiếm
  Future<Response> getAll(Request request) async {
    final params = request.url.queryParameters;
    final conn = await DatabaseConfig.getConnection();
    try {
      int limit = int.tryParse(params['limit'] ?? '10') ?? 10;
      int page = int.tryParse(params['page'] ?? '1') ?? 1;
      int offset = (page - 1) * limit;

      String query = 'SELECT * FROM products WHERE is_available = true';
      List<dynamic> args = [];

      if (params['search'] != null) {
        query += ' AND (name LIKE ? OR description LIKE ? OR brand LIKE ?)';
        String s = '%${params['search']}%';
        args.addAll([s, s, s]);
      }
      if (params['category'] != null) {
        query += ' AND category = ?';
        args.add(params['category']);
      }

      query += ' LIMIT ? OFFSET ?';
      args.addAll([limit, offset]);

      final results = await conn.query(query, args);
      return Response.ok(jsonEncode(results.map((row) => row.fields).toList()));
    } finally {
      await conn.close();
    }
  }

  // 4.2. Lấy theo ID (Giải quyết lỗi 'getById isn't defined')
  Future<Response> getById(Request request, String id) async {
    final conn = await DatabaseConfig.getConnection();
    try {
      final results = await conn.query('SELECT * FROM products WHERE id = ?', [int.parse(id)]);
      if (results.isEmpty) return Response.notFound(jsonEncode({'message': 'Không tìm thấy SP'}));
      return Response.ok(jsonEncode(results.first.fields));
    } finally {
      await conn.close();
    }
  }

  // 4.3. Thêm mới
  Future<Response> create(Request request) async {
    final payload = jsonDecode(await request.readAsString());
    final conn = await DatabaseConfig.getConnection();
    try {
      await conn.query(
          'INSERT INTO products (name, description, price, category, brand, stock, image_url) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [payload['name'], payload['description'], payload['price'], payload['category'], payload['brand'], payload['stock'], payload['image_url']]
      );
      return Response(201, body: jsonEncode({'message': 'Thành công'}));
    } finally {
      await conn.close();
    }
  }

  // 4.4. Cập nhật
  Future<Response> update(Request request, String id) async {
    final payload = jsonDecode(await request.readAsString());
    final conn = await DatabaseConfig.getConnection();
    try {
      await conn.query(
          'UPDATE products SET name=?, price=?, category=?, brand=?, stock=? WHERE id=?',
          [payload['name'], payload['price'], payload['category'], payload['brand'], payload['stock'], int.parse(id)]
      );
      return Response.ok(jsonEncode({'message': 'Cập nhật thành công'}));
    } finally {
      await conn.close();
    }
  }

  // 4.5. Xóa (Có kiểm tra ràng buộc)
  Future<Response> delete(Request request, String id) async {
    final conn = await DatabaseConfig.getConnection();
    try {
      final check = await conn.query(
          'SELECT oi.id FROM order_items oi JOIN orders o ON oi.order_id = o.id WHERE oi.product_id = ? AND o.status != "delivered"',
          [int.parse(id)]
      );
      if (check.isNotEmpty) return Response(400, body: jsonEncode({'message': 'Sản phẩm đang trong đơn hàng'}));

      await conn.query('DELETE FROM products WHERE id = ?', [int.parse(id)]);
      return Response.ok(jsonEncode({'message': 'Xóa thành công'}));
    } finally {
      await conn.close();
    }
  }
}