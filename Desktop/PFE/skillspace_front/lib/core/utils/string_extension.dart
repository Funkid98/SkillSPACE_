extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  String capitalizeAll() {
    if (isEmpty) return this;
    return split(' ').map((str) => str.capitalize()).join(' ');
  }
}
