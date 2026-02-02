/// Form validation helpers used across authentication flows.
///
/// Current validators
/// - [validateJUEmail] -> validates a Jordan University email address.
///
/// Notes
/// - Keep these validators pure and UI-agnostic.
/// - Intended for use in TextFormField.validator and pre-flight request checks.
/// Validates a Jordan University (JU) email address.
///
/// Validation rules
/// - Value must not be null or empty.
/// - Value must end with @ju.edu.jo.
/// - Local part must contain only lowercase letters, digits, dots, and underscores.
///
/// Error messages
/// - Empty -> "Please enter your email"
/// - Uppercase letters found -> "Email must be lowercase"
/// - Pattern mismatch -> "Please use your university email (must end with @ju.edu.jo)"
///
/// Returns
/// - null when the email is valid
/// - a string error message when invalid
String? validateJUEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your email';
  }

  // Only lowercase letters, digits, dot, underscore are allowed before the domain.
  final juEmailRegex = RegExp(r'^[a-z0-9._]+@ju\.edu\.jo$');

  if (!juEmailRegex.hasMatch(value)) {
    // Special-case uppercase letters to provide a clearer message.
    if (value.contains(RegExp(r'[A-Z]'))) {
      return 'Email must be lowercase';
    }
    return 'Please use your university email (must end with @ju.edu.jo)';
  }

  return null;
}