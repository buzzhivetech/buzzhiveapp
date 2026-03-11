/// Shared extensions (String, etc.).
extension StringExtension on String {
  bool get isBlank => trim().isEmpty;
}
