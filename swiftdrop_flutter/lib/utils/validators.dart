class Validators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final pattern = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!pattern.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 7 || digits.length > 15) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? weight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Weight is required';
    }
    final num = double.tryParse(value.trim());
    if (num == null || num <= 0 || num > 50) {
      return 'Enter a valid weight (0.1-50 kg)';
    }
    return null;
  }

  static String? promoCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a promo code';
    }
    return null;
  }

  static String? numeric(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final num = double.tryParse(value.trim());
    if (num == null || num <= 0) {
      return 'Enter a valid number';
    }
    return null;
  }
}
