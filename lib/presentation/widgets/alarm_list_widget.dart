import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/alarm.dart';
import '../providers/alarm_provider.dart';
import '../providers/alarm_group_provider.dart';

class AlarmListWidget extends StatelessWidget {
  const AlarmListWidget({super.key});

  void _showAddAlarmDialog(BuildContext context) {
    final timeController = TextEditingController();
    final labelController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Alarm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: timeController,
              decoration: const InputDecoration(labelText: 'Time (HH:MM)'),
            ),
            TextField(
              controller: labelController,
              decoration: const InputDecoration(labelText: 'Label'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final timeParts = timeController.text.split(':');
              if (timeParts.length == 2) {
                final hour = int.tryParse(timeParts[0]);
                final minute = int.tryParse(timeParts[1]);
                if (hour != null && minute != null) {
                  final now = DateTime.now();
                  final alarmTime = DateTime(now.year, now.month, now.day, hour, minute);
                  final alarm = Alarm(
                    id: DateTime.now().toString(),
                    time: alarmTime,
                    label: labelController.text.isEmpty ? 'Alarm' : labelController.text,
                  );
                  context.read<AlarmProvider>().addAlarm(alarm);
                  Navigator.of(context).pop();
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer2<AlarmProvider, AlarmGroupProvider>(
      builder: (context, alarmProvider, groupProvider, child) {
        final alarms = alarmProvider.alarms;
        final groups = groupProvider.groups;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Groups section
            if (groups.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Groups',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ...groups.map((group) => Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        group.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        '${group.alarmIds.length} alarms',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Switch(
                        value: group.isActive,
                        onChanged: (value) {
                          groupProvider.toggleGroup(group.id);
                        },
                        activeThumbColor: colorScheme.primary,
                      ),
                    ),
                  )),
            ],
            // Alarms section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Alarms',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ...alarms.map((alarm) => Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      alarm.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      '${alarm.time.hour}:${alarm.time.minute.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontFeatures: [const FontFeature.tabularFigures()],
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Switch(
                      value: alarm.isActive,
                      onChanged: (value) {
                        alarmProvider.toggleAlarm(alarm.id);
                      },
                      activeThumbColor: colorScheme.primary,
                    ),
                  ),
                )),
            // Add alarm button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: FilledButton.icon(
                onPressed: () => _showAddAlarmDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Alarm'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}