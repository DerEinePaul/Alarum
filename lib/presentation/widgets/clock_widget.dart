import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/settings/app_settings.dart';
import 'add_location_dialog.dart';

class TimeZoneLocation {
  final String name;
  final String timezone;
  final String country;
  
  TimeZoneLocation({required this.name, required this.timezone, required this.country});
}

class ClockWidget extends StatefulWidget {
  const ClockWidget({super.key});

  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  late Timer _timer;
  late DateTime _now;
  final List<TimeZoneLocation> _worldClocks = [];

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _showAddLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AddLocationDialog(
        onLocationAdded: (location) {
          setState(() {
            _worldClocks.add(location);
          });
        },
      ),
    );
  }

  void _removeLocation(int index) {
    setState(() {
      _worldClocks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hauptuhr
              Consumer<AppSettings>(
                builder: (context, settings, child) => Text(
                  settings.formatTime(_now),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w200,
                    fontFeatures: [const FontFeature.tabularFigures()],
                    shadows: [
                      Shadow(
                        color: colorScheme.shadow.withValues(alpha: 0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                DateFormat('EEEE, MMMM d, y').format(_now),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w300,
                ),
              ),
              
              // Weltzeitzonen (minimal unter der Hauptuhr)
              if (_worldClocks.isNotEmpty) ...[
                const SizedBox(height: 48),
                Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: _worldClocks.asMap().entries.map((entry) {
                      final index = entry.key;
                      final location = entry.value;
                      final offset = _getTimezoneOffset(location.timezone);
                      final localTime = _now.add(offset);
                      
                      return InkWell(
                        onLongPress: () => _removeLocation(index),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colorScheme.outline.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                location.name,
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('HH:mm').format(localTime),
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontFeatures: [const FontFeature.tabularFigures()],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddLocationDialog,
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Duration _getTimezoneOffset(String timezone) {
    // Vereinfachte Zeitzone-Offsets (für Demonstration)
    switch (timezone) {
      case 'America/New_York': return const Duration(hours: -6); // EST
      case 'Europe/London': return const Duration(hours: 0); // GMT
      case 'Europe/Berlin': return const Duration(hours: 1); // CET
      case 'Asia/Tokyo': return const Duration(hours: 9); // JST
      case 'Asia/Shanghai': return const Duration(hours: 8); // CST
      case 'Australia/Sydney': return const Duration(hours: 11); // AEDT
      case 'America/Los_Angeles': return const Duration(hours: -8); // PST
      default: return Duration.zero;
    }
  }
}