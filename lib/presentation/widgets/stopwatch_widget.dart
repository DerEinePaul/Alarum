import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../providers/stopwatch_provider.dart';

class StopwatchWidget extends StatelessWidget {
  const StopwatchWidget({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final milliseconds = (duration.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$milliseconds';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer<StopwatchProvider>(
      builder: (context, provider, child) {
        final state = provider.state;
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _formatDuration(state.elapsed),
                  key: ValueKey<String>(_formatDuration(state.elapsed)),
                  style: AppConstants.displayTextStyle(context).copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.tonal(
                    onPressed: state.isRunning ? provider.stop : provider.start,
                    style: AppConstants.filledTonalButtonStyle(context),
                    child: Text(
                      state.isRunning ? 'Stop' : 'Start',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: provider.reset,
                    style: AppConstants.outlinedButtonStyle(context),
                    child: const Text(
                      'Reset',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: state.isRunning ? provider.lap : null,
                    style: AppConstants.filledButtonStyle(context),
                    child: const Text(
                      'Lap',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Card(
                  elevation: AppConstants.defaultElevation,
                  shape: AppConstants.cardShape,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.laps.length,
                    itemBuilder: (context, index) {
                      final lap = state.laps[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Lap ${index + 1}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              _formatDuration(lap),
                              style: AppConstants.bodyTextStyle(context),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}