import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../config/database.dart';
import '../utils/validator.dart'; // Đảm bảo bạn đã tạo file validator.dart

class AuthController {
  // 2.1. Đăng ký Customer (5 điểm)
  Future<Response> register(Request request) async {
    try {
      final payload = jsonDecode(await request.readAsString());

      // --- BƯỚC 1: INPUT VALIDATION (Phần 6.2) ---
      final requiredError = Validator.validateRequired(
          payload, ['email', 'password', 'full_name']
      );
      if (requiredError != null) {
        return Response(400, body: jsonEncode({'message': requiredError}));
      }

      if (!Validator.isValidEmail(payload['email'])) {
        return Response(400, body: jsonEncode({'message': 'Định dạng email không hợp lệ'}));
      }

      final conn = await DatabaseConfig.getConnection();

      // --- BƯỚC 2: KIỂM TRA EMAIL TỒN TẠI ---
      final existingUser = await conn.query(
          'SELECT id FROM customers WHERE email = ?', [payload['email']]
      );
      if (existingUser.isNotEmpty) {
        await conn.close();
        return Response(400, body: jsonEncode({'message': 'Email đã tồn tại trong hệ thống'}));
      }

      // --- BƯỚC 3: HASH PASSWORD & LƯU DB ---
      final hashedPassword = BCrypt.hashpw(payload['password'], BCrypt.gensalt());

      final result = await conn.query(
          'INSERT INTO customers (email, password, full_name, phone_number, address, city, postal_code) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [
            payload['email'],
            hashedPassword,
            payload['full_name'],
            payload['phone_number'],
            payload['address'],
            payload['city'],
            payload['postal_code']
          ]
      );

      final newId = result.insertId;
      await conn.close();

      // Trả về 201 và customer data (không có password)
      return Response(201, body: jsonEncode({
        'id': newId,
        'email': payload['email'],
        'full_name': payload['full_name'],
        'phone_number': payload['phone_number'],
        'address': payload['address'],
        'city': payload['city'],
        'postal_code': payload['postal_code']
      }), headers: {'content-type': 'application/json'});

    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Lỗi đăng ký: ${e.toString()}'})
      );
    }
  }

  // 2.2. Đăng nhập & 2.4 Phân quyền (10 điểm)
  Future<Response> login(Request request) async {
    try {
      final payload = jsonDecode(await request.readAsString());

      // Validate input
      final loginError = Validator.validateRequired(payload, ['email', 'password']);
      if (loginError != null) {
        return Response(400, body: jsonEncode({'message': loginError}));
      }

      final String email = payload['email'];
      final String password = payload['password'];

      final conn = await DatabaseConfig.getConnection();
      final results = await conn.query('SELECT * FROM customers WHERE email = ?', [email]);

      if (results.isEmpty) {
        await conn.close();
        return Response(401, body: jsonEncode({'message': 'Email không tồn tại'}));
      }

      final user = results.first;

      // Verify password
      final bool isPasswordValid = BCrypt.checkpw(password, user['password']);
      if (!isPasswordValid) {
        await conn.close();
        return Response(401, body: jsonEncode({'message': 'Mật khẩu không chính xác'}));
      }

      // --- LOGIC PHÂN QUYỀN (2.4) ---
      // Nếu email là admin@test.com thì gán role admin, còn lại là customer
      final String role = (email == 'admin@test.com') ? 'admin' : 'customer';

      // --- TẠO JWT TOKEN ---
      final jwt = JWT({
        'id': user['id'],
        'email': user['email'],
        'role': role
      });

      // Dùng Secret Key là Mã Sinh Viên để bảo mật
      final token = jwt.sign(SecretKey('2151170554_SECRET_KEY'));

      await conn.close();

      // --- RESPONSE BẮT BUỘC (Yêu cầu đặc thù 2.2) ---
      return Response.ok(jsonEncode({
        'token': token,
        'student_id': '2151170554', // BẮT BUỘC HARDCODE THEO ĐỀ
        'role': role,
        'user': {
          'id': user['id'],
          'email': user['email'],
          'full_name': user['full_name']
        }
      }), headers: {'content-type': 'application/json'});

    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Lỗi đăng nhập: ${e.toString()}'})
      );
    }
  }

  // 3.4. Lấy thông tin Customer hiện tại (2 điểm)
  Future<Response> me(Request request) async {
    try {
      // Thông tin user được trích xuất từ JWT qua authMiddleware
      final user = request.context['user'] as Map<String, dynamic>;

      return Response.ok(
          jsonEncode({
            'student_id': '2151170554',
            'profile': user
          }),
          headers: {'content-type': 'application/json'}
      );
    } catch (e) {
      return Response(401, body: jsonEncode({'message': 'Không thể xác thực người dùng'}));
    }
  }
}