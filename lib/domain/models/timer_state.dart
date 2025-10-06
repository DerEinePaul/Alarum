class TimerState {
  final Duration remaining;
  final bool isRunning;
  final bool isPaused;
  final Duration initialDuration;

  TimerState({
    required this.initialDuration,
    this.remaining = Duration.zero,
    this.isRunning = false,
    this.isPaused = false,
  });

  TimerState copyWith({
    Duration? remaining,
    bool? isRunning,
    bool? isPaused,
    Duration? initialDuration,
  }) {
    return TimerState(
      remaining: remaining ?? this.remaining,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      initialDuration: initialDuration ?? this.initialDuration,
    );
  }
}