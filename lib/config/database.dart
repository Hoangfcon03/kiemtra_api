import 'package:mysql1/mysql1.dart';

class DatabaseConfig {
  // Thay đổi các thông số này phù hợp với máy
  static const String host = 'localhost';
  static const int port = 3306;
  static const String user = 'root';
  static const String password = '123456'; // Mật khẩu MySQL
  static const String db = 'db_exam_2151170554'; // Tên DB theo yêu cầu đề bài

  static Future<MySqlConnection> getConnection() async {
    final settings = ConnectionSettings(
      host: host,
      port: port,
      user: user,
      password: password,
      db: db,
    );

    return await MySqlConnection.connect(settings);
  }
}