import 'dart:async';

/// Builds a stream that first emits the current value and then every change,
/// so listeners never miss a change that happens while the current value is
/// still loading.
///
/// If a change arrives before [current] completes, the (older) current value
/// is dropped because the change already contains the newer state.
Stream<T> currentThenChanges<T>(
  Future<T> Function() current,
  Stream<T> changes,
) {
  late final StreamController<T> controller;
  StreamSubscription<T>? subscription;
  controller = StreamController<T>(
    onListen: () {
      var changed = false;
      subscription = changes.listen((value) {
        changed = true;
        controller.add(value);
      }, onError: controller.addError);
      current().then((value) {
        if (!changed) controller.add(value);
      }, onError: controller.addError);
    },
    onCancel: () => subscription?.cancel(),
  );
  return controller.stream;
}
