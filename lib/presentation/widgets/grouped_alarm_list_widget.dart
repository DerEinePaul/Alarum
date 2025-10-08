import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/services/alarm_group_service.dart';
import '../../core/settings/app_settings.dart';
import '../../domain/models/alarm.dart';
import '../../domain/models/alarm_group.dart';
import '../../data/repositories/alarm_repository.dart';
import '../../data/repositories/alarm_group_repository.dart';
import '../providers/alarm_provider.dart';
import '../providers/alarm_group_provider.dart';
import 'create_alarm_dialog.dart';

class GroupedAlarmListWidget extends StatefulWidget {
  const GroupedAlarmListWidget({super.key});

  @override
  State<GroupedAlarmListWidget> createState() => _GroupedAlarmListWidgetState();
}

class _GroupedAlarmListWidgetState extends State<GroupedAlarmListWidget> {
  late AlarmGroupService _groupService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _groupService = AlarmGroupService(
        context.read<AlarmProvider>().repository as AlarmRepository,
        context.read<AlarmGroupProvider>().repository as AlarmGroupRepository,
      );
      _groupService.createDefaultGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Consumer2<AlarmProvider, AlarmGroupProvider>(
      builder: (context, alarmProvider, groupProvider, child) {
        final groups = groupProvider.items;
        
        if (groups.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Consumer<AppSettings>(
              builder: (context, settings, child) => Text(
                settings.getText('alarms'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Grouped Alarms
            ...groups.map((group) => _buildGroupExpansionTile(
              context, 
              group, 
              alarmProvider.items.where((alarm) => alarm.groupId == group.id).toList(),
            )),
            
            const SizedBox(height: 120), // Extra space for FAB and bottom navigation
          ],
        );
      },
    );
  }

  Widget _buildGroupExpansionTile(BuildContext context, AlarmGroup group, List<Alarm> groupAlarms) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = group.isActive;
    
    return Card(
      elevation: AppConstants.defaultElevation,
      shape: AppConstants.cardShape,
      margin: const EdgeInsets.only(bottom: 12),
      color: isActive 
        ? colorScheme.primaryContainer.withValues(alpha: 0.3)
        : colorScheme.surfaceContainerLow,
      child: ExpansionTile(
        leading: Switch.adaptive(
          value: isActive,
          onChanged: (value) async {
            // Capture providers before async operation
            final alarmProvider = context.read<AlarmProvider>();
            final groupProvider = context.read<AlarmGroupProvider>();
            
            await _groupService.toggleGroup(group.id);
            if (mounted) {
              alarmProvider.loadItems();
              groupProvider.loadItems();
            }
          },
          activeThumbColor: colorScheme.primary,
          activeTrackColor: colorScheme.primaryContainer,
        ),
        title: Text(
          group.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${groupAlarms.length} Wecker',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isActive ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7) : colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.expand_more,
          color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
        ),
        children: [
          if (groupAlarms.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Keine Wecker in dieser Gruppe',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...groupAlarms.map((alarm) => _buildAlarmTile(context, alarm, group)),
          
          // Add alarm button for this group
          Padding(
            padding: const EdgeInsets.all(8),
            child: Consumer<AppSettings>(
              builder: (context, settings, child) => TextButton.icon(
                onPressed: () => _showCreateAlarmDialog(context, group),
                icon: Icon(Icons.add, color: colorScheme.primary),
                label: Text(
                  settings.getText('addAlarm'),
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmTile(BuildContext context, Alarm alarm, AlarmGroup group) {
    final colorScheme = Theme.of(context).colorScheme;
    final isGroupActive = group.isActive;
    final isAlarmActive = alarm.isActive && isGroupActive;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Switch.adaptive(
        value: isAlarmActive,
        onChanged: isGroupActive ? (value) {
          context.read<AlarmProvider>().toggleItem(alarm.id);
        } : null,
        activeThumbColor: colorScheme.primary,
      ),
      title: Consumer<AppSettings>(
        builder: (context, settings, child) => Text(
          settings.formatTime(alarm.time),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: isAlarmActive ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w400,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (alarm.label.isNotEmpty)
            Text(
              alarm.label,
              style: TextStyle(
                color: isAlarmActive ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          Text(
            alarm.repeatDaysText,
            style: TextStyle(
              color: isAlarmActive ? colorScheme.onSurfaceVariant : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.delete_outline,
          color: colorScheme.error,
        ),
        onPressed: () => _showDeleteConfirmation(context, alarm),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.alarm_off,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Wecker vorhanden',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Erstelle deinen ersten Wecker',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateAlarmDialog(BuildContext context, AlarmGroup group) {
    showDialog(
      context: context,
      builder: (context) => CreateAlarmDialog(
        preselectedGroup: group,
        onAlarmCreated: (alarm) {
          context.read<AlarmProvider>().loadItems();
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Alarm alarm) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.read<AppSettings>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(settings.getText('deleteAlarm')),
        content: Text('Möchtest du den Wecker um ${settings.formatTime(alarm.time)} wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(settings.getText('cancel'), style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              context.read<AlarmProvider>().deleteItem(alarm.id);
              Navigator.of(context).pop();
            },
            child: Text(settings.getText('delete'), style: TextStyle(color: colorScheme.error)),
          ),
        ],
      ),
    );
  }
}