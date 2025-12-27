import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: const LoginScreen());
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();

  // Dùng localhost vì bạn đang chạy Flutter Web
  final String _baseUrl = "http://localhost:8080";

  Future<void> _login() async {
    try {
      final url = Uri.parse('$_baseUrl/api/auth/login');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _email.text,
          'password': _pass.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);

        if (!mounted) return;
        _msg("Đăng nhập thành công! MSV: ${data['student_id']}");
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProductListScreen()));
      } else {
        _msg(data['message'] ?? 'Sai email hoặc mật khẩu');
      }
    } catch (e) {
      _msg("Lỗi kết nối: $e");
    }
  }

  void _msg(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng nhập - 2151170554")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _email, decoration: const InputDecoration(labelText: "Email")),
          TextField(controller: _pass, decoration: const InputDecoration(labelText: "Mật khẩu"), obscureText: true),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _login, child: const Text("Đăng nhập")),
        ]),
      ),
    );
  }
}

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Sản phẩm")));
}