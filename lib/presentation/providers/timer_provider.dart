import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/timer_state.dart';

class TimerProvider with ChangeNotifier {
  TimerState _state;
  Timer? _timer;

  TimerProvider(Duration initialDuration)
      : _state = TimerState(initialDuration: initialDuration, remaining: initialDuration);

  TimerState get state => _state;

  void setDuration(Duration duration) {
    _state = TimerState(initialDuration: duration, remaining: duration);
    notifyListeners();
  }

  void start() {
    if (_state.isRunning || _state.remaining == Duration.zero) return;
    _state = _state.copyWith(isRunning: true, isPaused: false);
    notifyListeners();
    _tick();
  }

  void pause() {
    _timer?.cancel();
    _state = _state.copyWith(isRunning: false, isPaused: true);
    notifyListeners();
  }

  void resume() {
    if (_state.isPaused) {
      start();
    }
  }

  void reset() {
    _timer?.cancel();
    _state = TimerState(initialDuration: _state.initialDuration, remaining: _state.initialDuration);
    notifyListeners();
  }

  void _tick() {
    if (_state.remaining.inSeconds > 0 && _state.isRunning) {
      _state = _state.copyWith(remaining: _state.remaining - const Duration(seconds: 1));
      notifyListeners();
      _timer = Timer(const Duration(seconds: 1), _tick);
    } else {
      _state = _state.copyWith(isRunning: false);
      notifyListeners();
      // Trigger alarm notification here
    }
  }
}