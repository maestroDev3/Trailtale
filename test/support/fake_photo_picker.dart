import 'package:trailtale/domain/photo_picker.dart';

/// [PhotoPicker] for widget tests that returns [nextPick] once.
class FakePhotoPicker implements PhotoPicker {
  FakePhotoPicker([this.nextPick = const []]);

  /// Paths the next call to [pickImages] returns; empty means "cancelled".
  List<String> nextPick;

  /// How often the picker was opened.
  var openCount = 0;

  @override
  Future<List<String>> pickImages() async {
    openCount++;
    final picked = nextPick;
    nextPick = const [];
    return picked;
  }
}
