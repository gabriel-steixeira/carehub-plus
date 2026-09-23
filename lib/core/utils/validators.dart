/// Form field validators used across the app.
class Validators {
  Validators._();

  /// Validates an email address.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe seu e-mail';
    }
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) {
      return 'E-mail inválido';
    }
    return null;
  }

  /// Validates a password (minimum 6 characters).
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe sua senha';
    }
    if (value.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres';
    }
    return null;
  }

  /// Validates an optional Brazilian phone number.
  ///
  /// Empty is valid on purpose: the phone is optional in the caregiver profile.
  /// When filled, accepts 10 digits (landline) or 11 (mobile), ignoring the
  /// punctuation the user may type — `(11) 98765-4321` and `11987654321` are
  /// both valid.
  static String? optionalPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 11) {
      return 'Telefone inválido';
    }
    return null;
  }

  /// Validates that a field is not empty.
  static String? required(String? value, [String fieldName = 'campo']) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o $fieldName';
    }
    return null;
  }
}
