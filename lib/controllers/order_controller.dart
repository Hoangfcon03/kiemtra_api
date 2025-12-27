import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../config/database.dart';

class OrderController {
  // 5.1. Tạo Đơn hàng (Transaction)
  Future<Response> create(Request request) async {
    final user = request.context['user'] as Map<String, dynamic>;
    final payload = jsonDecode(await request.readAsString());
    final List items = payload['items'];
    final conn = await DatabaseConfig.getConnection();

    try {
      return await conn.transaction((ctx) async {
        double subtotal = 0;
        for (var item in items) {
          var res = await ctx.query('SELECT price, stock FROM products WHERE id = ?', [item['product_id']]);
          var p = res.first;
          if (p['stock'] < item['quantity']) throw Exception('Hết hàng');
          subtotal += (p['price'] * item['quantity']);
        }

        String orderNo = "ORD-${DateTime.now().millisecondsSinceEpoch}";
        var order = await ctx.query(
            'INSERT INTO orders (customer_id, order_number, subtotal, shipping_fee, total, shipping_address) VALUES (?, ?, ?, ?, ?, ?)',
            [user['id'], orderNo, subtotal, 30000, subtotal + 30000, payload['shipping_address']]
        );

        for (var item in items) {
          await ctx.query('INSERT INTO order_items (order_id, product_id, quantity, price) VALUES (?, ?, ?, ?)',
              [order.insertId, item['product_id'], item['quantity'], 0]); // Giá lấy từ DB thực tế
          await ctx.query('UPDATE products SET stock = stock - ? WHERE id = ?', [item['quantity'], item['product_id']]);
        }
        return Response.ok(jsonEncode({'message': 'Đặt hàng thành công', 'order_number': orderNo}));
      }) as Response;
    } catch (e) {
      return Response(400, body: jsonEncode({'error': e.toString()}));
    } finally {
      await conn.close();
    }
  }

  // 5.2. Lấy Đơn hàng theo ID
  Future<Response> getById(Request request, String id) async {
    final conn = await DatabaseConfig.getConnection();
    try {
      final res = await conn.query('SELECT * FROM orders WHERE id = ?', [int.parse(id)]);
      if (res.isEmpty) return Response.notFound(jsonEncode({'message': 'Không thấy đơn hàng'}));
      return Response.ok(jsonEncode(res.first.fields));
    } finally {
      await conn.close();
    }
  }

  // 5.4. Cập nhật Trạng thái (Hủy đơn trả stock)
  Future<Response> updateStatus(Request request, String id) async {
    final payload = jsonDecode(await request.readAsString());
    final conn = await DatabaseConfig.getConnection();
    try {
      return await conn.transaction((ctx) async {
        if (payload['status'] == 'cancelled') {
          var items = await ctx.query('SELECT product_id, quantity FROM order_items WHERE order_id = ?', [int.parse(id)]);
          for (var item in items) {
            await ctx.query('UPDATE products SET stock = stock + ? WHERE id = ?', [item['quantity'], item['product_id']]);
          }
        }
        await ctx.query('UPDATE orders SET status = ? WHERE id = ?', [payload['status'], int.parse(id)]);
        return Response.ok(jsonEncode({'message': 'Cập nhật thành công'}));
      }) as Response;
    } finally {
      await conn.close();
    }
  }

  // 5.5. Thanh toán
  Future<Response> pay(Request request, String id) async {
    final conn = await DatabaseConfig.getConnection();
    try {
      await conn.query('UPDATE orders SET payment_status = "paid" WHERE id = ?', [int.parse(id)]);
      return Response.ok(jsonEncode({'message': 'Thanh toán thành công'}));
    } finally {
      await conn.close();
    }
  }

  // 5.3 & 5.6. Lấy danh sách cho Customer/Admin
  Future<Response> getOrdersAdmin(Request request) async {
    final conn = await DatabaseConfig.getConnection();
    try {
      final res = await conn.query('SELECT * FROM orders');
      return Response.ok(jsonEncode(res.map((r) => r.fields).toList()));
    } finally {
      await conn.close();
    }
  }

  Future<Response> getOrdersByCustomer(Request request, String id) async {
    final conn = await DatabaseConfig.getConnection();
    try {
      final res = await conn.query('SELECT * FROM orders WHERE customer_id = ?', [int.parse(id)]);
      return Response.ok(jsonEncode(res.map((r) => r.fields).toList()));
    } finally {
      await conn.close();
    }
  }
}