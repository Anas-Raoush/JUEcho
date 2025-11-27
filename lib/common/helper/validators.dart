/// Validates a Jordan University (JU) email address.
///
/// This validator is used throughout all authentication forms
/// (login, signup, forgot password) to ensure that users only register
/// or sign in using their official university email.
///
/// Validation rules:
/// -----------------
/// 1. The value must not be null or empty.
/// 2. The email must match the domain: `@ju.edu.jo`.
/// 3. Only **lowercase** letters, digits, dots, and underscores are allowed
///    before the domain (aligned with common JU email formatting).
///
/// Error messages:
/// --------------
/// - If empty → `"Please enter your email"`
/// - If uppercase letters are detected → `"Email must be lowercase"`
/// - If domain or pattern doesn't match →
///   `"Please use your university email (must end with @ju.edu.jo)"`
///
/// Returns:
/// --------
/// - `null` → email is valid
/// - `String` → contains the appropriate validation error message
///
/// Example valid emails:
///   - `ahmad.saleh@ju.edu.jo`
///   - `cs20210045@ju.edu.jo`
///
/// Example invalid emails:
///   - `Ahmad@ju.edu.jo` (uppercase not allowed)
///   - `test@gmail.com`
///   - `student@ju.com`
///   - `abc@ju.edu`
///
/// This function is intended for use in:
///   - `TextFormField.validator`
///   - manual validation prior to API calls
String? validateJUEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your email';
  }

  // JU email regex: only lowercase letters, digits, dots, underscores
  final juEmailRegex = RegExp(r'^[a-z0-9._]+@ju\.edu\.jo$');

  if (!juEmailRegex.hasMatch(value)) {
    // Check if user typed uppercase
    if (value.contains(RegExp(r'[A-Z]'))) {
      return 'Email must be lowercase';
    }
    return 'Please use your university email (must end with @ju.edu.jo)';
  }

  return null; // valid
}