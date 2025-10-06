class StopwatchState {
  final bool isRunning;
  final Duration elapsed;
  final List<Duration> laps;

  StopwatchState({
    this.isRunning = false,
    this.elapsed = Duration.zero,
    this.laps = const [],
  });

  StopwatchState copyWith({
    bool? isRunning,
    Duration? elapsed,
    List<Duration>? laps,
  }) {
    return StopwatchState(
      isRunning: isRunning ?? this.isRunning,
      elapsed: elapsed ?? this.elapsed,
      laps: laps ?? this.laps,
    );
  }
}