import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Cached, serialized access to one JSON file that stores a list of records
/// under [listKey] together with a format `version`.
///
/// Writes go to a temporary file that is renamed afterwards, so a crash never
/// leaves a half-written file. A file with an unknown version is refused with
/// a [StateError] and never overwritten.
class VersionedJsonList<T> {
  VersionedJsonList({
    required this.file,
    required this.listKey,
    required this.fromJson,
    required this.toJson,
    this.version = 1,
  });

  final File file;
  final String listKey;
  final int version;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, Object?> Function(T item) toJson;

  final _changes = StreamController<List<T>>.broadcast();
  Future<void> _queue = Future.value();
  List<T>? _items;

  /// Emits the full list after every write.
  Stream<List<T>> get changes => _changes.stream;

  /// Reads the stored list (empty if the file does not exist yet).
  Future<List<T>> read() => _serialized(_load);

  /// Replaces the stored list with the result of [change]; returning the
  /// same list instance skips the write.
  Future<void> update(List<T> Function(List<T> items) change) {
    return _serialized(() async {
      final items = await _load();
      final changed = change(items);
      if (identical(changed, items)) return;
      await _store(changed);
    });
  }

  /// Runs file operations one after another so concurrent writes never
  /// overwrite each other.
  Future<R> _serialized<R>(Future<R> Function() operation) {
    final result = _queue.then((_) => operation());
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<List<T>> _load() async {
    if (_items case final items?) return items;
    if (!file.existsSync()) return _items = List<T>.unmodifiable(const []);
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final storedVersion = json['version'];
    if (storedVersion != version) {
      throw StateError(
        'Unsupported version $storedVersion in ${file.path} (expected $version)',
      );
    }
    final items = (json[listKey] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(fromJson);
    return _items = List<T>.unmodifiable(items);
  }

  Future<void> _store(List<T> items) async {
    final json = {'version': version, listKey: items.map(toJson).toList()};
    final temporary = File('${file.path}.tmp');
    await temporary.parent.create(recursive: true);
    await temporary.writeAsString(jsonEncode(json), flush: true);
    await temporary.rename(file.path);
    final stored = List<T>.unmodifiable(items);
    _items = stored;
    _changes.add(stored);
  }
}
