import 'dart:async';

class SettingsBus {
  static final StreamController<void> _controller = StreamController<void>.broadcast();
  static Stream<void> get stream => _controller.stream;
  static void emit() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }
}
