import 'package:flutter/foundation.dart';
import '../../domain/models/stopwatch_state.dart';

class StopwatchProvider with ChangeNotifier {
  StopwatchState _state = StopwatchState();
  Stopwatch? _stopwatch;

  StopwatchState get state => _state;

  void start() {
    if (_state.isRunning) return;
    _stopwatch = Stopwatch()..start();
    _state = _state.copyWith(isRunning: true);
    notifyListeners();
    _tick();
  }

  void stop() {
    _stopwatch?.stop();
    _state = _state.copyWith(isRunning: false);
    notifyListeners();
  }

  void reset() {
    _stopwatch?.reset();
    _state = StopwatchState();
    notifyListeners();
  }

  void lap() {
    if (_state.isRunning) {
      final laps = List<Duration>.from(_state.laps)..add(_state.elapsed);
      _state = _state.copyWith(laps: laps);
      notifyListeners();
    }
  }

  void _tick() {
    if (_state.isRunning) {
      _state = _state.copyWith(elapsed: _stopwatch!.elapsed);
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 100), _tick);
    }
  }
}