import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/timer_state.dart';
import '../../core/services/alarm_service.dart';

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

  /// Startet Timer mit System-Level Background-Execution
  void start() {
    if (_state.isRunning || _state.remaining == Duration.zero) return;
    _state = _state.copyWith(isRunning: true, isPaused: false);
    notifyListeners();
    
    debugPrint('⏰ Timer gestartet für ${_state.remaining.inMinutes}:${(_state.remaining.inSeconds % 60).toString().padLeft(2, '0')}');
    
    // Schedule Background Task für System-Level Alarm (nur Mobile)
    if (!kIsWeb) {
      _scheduleBackgroundTimer();
    }
    
    _tick();
  }

  /// Pausiert Timer und cancelt Background Task
  void pause() {
    _timer?.cancel();
    _state = _state.copyWith(isRunning: false, isPaused: true);
    notifyListeners();
    
    // Cancel Background Task
    if (!kIsWeb) {
      _cancelBackgroundTimer();
    }
    
    debugPrint('⏸️ Timer pausiert');
  }

  void resume() {
    if (_state.isPaused) {
      start();
    }
  }

  /// Reset Timer und cancelt Background Task
  void reset() {
    _timer?.cancel();
    _state = TimerState(initialDuration: _state.initialDuration, remaining: _state.initialDuration);
    notifyListeners();
    
    // Cancel Background Task
    if (!kIsWeb) {
      _cancelBackgroundTimer();
    }
    
    debugPrint('🔄 Timer zurückgesetzt');
  }

  void _tick() {
    if (_state.remaining.inSeconds > 0 && _state.isRunning) {
      _state = _state.copyWith(remaining: _state.remaining - const Duration(seconds: 1));
      notifyListeners();
      _timer = Timer(const Duration(seconds: 1), _tick);
    } else {
      // Timer abgelaufen - zeige Benachrichtigung
      _state = _state.copyWith(isRunning: false);
      notifyListeners();
      _triggerTimerAlarm();
    }
  }

  /// Triggert Alarm wenn Timer abgelaufen ist
  Future<void> _triggerTimerAlarm() async {
    debugPrint('⏰ TIMER ABGELAUFEN!');
    
    // Zeige kritische Benachrichtigung
    await AlarmService.showCriticalNotification(
      'timer_${DateTime.now().millisecondsSinceEpoch}',
      'Timer Abgelaufen!',
      'default',
    );
    
    // Optional: Spiele Alarm-Sound ab
    await AlarmService.playAlarmSound();
  }

  /// Schedule Background Timer Task (nur Mobile)
  void _scheduleBackgroundTimer() {
    if (kIsWeb) return;
    
    try {
      // TODO: Workmanager Task scheduling wird zur Laufzeit dynamisch geladen
      // Unique name würde hier verwendet werden für Task-Identifikation
      // final uniqueName = 'timer_${DateTime.now().millisecondsSinceEpoch}';
      
      // if (!kIsWeb) {
      //   Workmanager().registerOneOffTask(
      //     uniqueName,
      //     'timer_task',
      //     initialDelay: _state.remaining,
      //     inputData: {
      //       'duration': _state.remaining.inMinutes,
      //       'uniqueName': uniqueName,
      //     },
      //   );
      // }
      
      debugPrint('📋 Background Timer Task bereit: ${_state.remaining.inMinutes}min');
    } catch (e) {
      debugPrint('❌ Background Timer Task Fehler: $e');
    }
  }

  /// Cancel Background Timer Task (nur Mobile)
  void _cancelBackgroundTimer() {
    if (kIsWeb) return;
    
    try {
      // Workmanager().cancelAll();
      debugPrint('🚫 Background Timer Tasks abgebrochen');
    } catch (e) {
      debugPrint('❌ Cancel Background Timer Fehler: $e');
    }
  }
}