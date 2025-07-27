/// String extensions for common string operations in the shop
extension StringExtension on String {
  /// Capitalizes the first letter of the string
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Converts string to title case (capitalizes each word)
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// Truncates string to specified length with ellipsis
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Checks if string is a valid price format
  bool get isValidPrice {
    if (isEmpty) return false;
    final regex = RegExp(r'^\d+(\.\d{1,2})?$');
    return regex.hasMatch(this);
  }

  /// Formats string as currency display
  String formatAsCurrency({String symbol = '\$'}) {
    if (isEmpty) return this;
    return '$symbol$this';
  }
}
