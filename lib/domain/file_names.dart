/// Keeps letters, digits, `-` and `_` in a file name and its extension;
/// every other character becomes `-`, an empty name becomes `file`.
String safeFileName(String name) {
  final dot = name.lastIndexOf('.');
  final (base, extension) = dot < 0
      ? (name, '')
      : (name.substring(0, dot), name.substring(dot + 1));
  String clean(String text) => text.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '-');
  final cleanBase = clean(base);
  final safeBase = cleanBase.isEmpty ? 'file' : cleanBase;
  return extension.isEmpty ? safeBase : '$safeBase.${clean(extension)}';
}
