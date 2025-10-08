import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../providers/timer_provider.dart';

class TimerWidget extends StatelessWidget {
  const TimerWidget({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer<TimerProvider>(
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
                  _formatDuration(state.remaining),
                  key: ValueKey<String>(_formatDuration(state.remaining)),
                  style: AppConstants.displayTextStyle(context).copyWith(
                    color: state.isRunning ? colorScheme.primary : colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.tonal(
                    onPressed: state.isRunning ? provider.pause : provider.start,
                    style: AppConstants.filledTonalButtonStyle(context),
                    child: Text(
                      state.isRunning ? 'Pause' : 'Start',
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
                  if (state.isPaused) ...[
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: provider.resume,
                      style: AppConstants.filledButtonStyle(context),
                      child: const Text(
                        'Resume',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 32),
              Card(
                elevation: AppConstants.defaultElevation,
                shape: AppConstants.cardShape,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DropdownButton<int>(
                        value: state.initialDuration.inMinutes,
                        items: List.generate(60, (index) => index + 1)
                            .map((value) => DropdownMenuItem(
                                  value: value,
                                  child: Text('$value min'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            provider.setDuration(Duration(minutes: value));
                          }
                        },
                      ),
                    ],
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