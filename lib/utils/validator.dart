class Validator {
  /// Kiểm tra các trường bắt buộc phải có giá trị
  static String? validateRequired(Map<String, dynamic> data, List<String> fields) {
    for (var field in fields) {
      if (data[field] == null || data[field].toString().trim().isEmpty) {
        return 'Trường [$field] là bắt buộc và không được để trống.';
      }
    }
    return null;
  }

  /// Kiểm tra định dạng Email
  static bool isValidEmail(String email) {
    final emailRegExp = RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    return emailRegExp.hasMatch(email);
  }

  /// Kiểm tra số lượng (phải là số dương)
  static String? validateNumeric(Map<String, dynamic> data, List<String> fields) {
    for (var field in fields) {
      if (data[field] != null) {
        final value = num.tryParse(data[field].toString());
        if (value == null || value < 0) {
          return 'Trường [$field] phải là một số lớn hơn hoặc bằng 0.';
        }
      }
    }
    return null;
  }
}