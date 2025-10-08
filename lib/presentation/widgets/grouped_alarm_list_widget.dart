import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/settings/app_settings.dart';
import '../../domain/models/alarm.dart';
import '../../domain/models/alarm_group.dart';
import '../providers/alarm_provider.dart';
import '../providers/alarm_group_provider.dart';
import 'dialogs/unified_create_alarm_dialog.dart';

class GroupedAlarmListWidget extends StatefulWidget {
  const GroupedAlarmListWidget({super.key});

  @override
  State<GroupedAlarmListWidget> createState() => _GroupedAlarmListWidgetState();
}

class _GroupedAlarmListWidgetState extends State<GroupedAlarmListWidget> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Consumer2<AlarmProvider, AlarmGroupProvider>(
      builder: (context, alarmProvider, groupProvider, child) {
        final groups = groupProvider.items;
        final allAlarms = alarmProvider.items;
        final ungroupedAlarms = allAlarms.where((alarm) => alarm.groupId == null).toList();

        if (allAlarms.isEmpty) {
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
            
            // Ungrouped Alarms Section
            if (ungroupedAlarms.isNotEmpty)
              _buildUngroupedAlarmsSection(context, ungroupedAlarms),
            
            // Grouped Alarms
            ...groups.map((group) => _buildGroupExpansionTile(
              context, 
              group, 
              allAlarms.where((alarm) => alarm.groupId == group.id).toList(),
            )),
            
            const SizedBox(height: 120), // Extra space for FAB and bottom navigation
          ],
        );
      },
    );
  }

  Widget _buildUngroupedAlarmsSection(BuildContext context, List<Alarm> alarms) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: AppConstants.defaultElevation,
      shape: AppConstants.cardShape,
      margin: const EdgeInsets.only(bottom: 12),
      color: colorScheme.surfaceContainerLow,
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(Icons.alarm, color: colorScheme.onSurfaceVariant),
        title: Text(
          'Keine Gruppe',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${alarms.length} Wecker',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        children: alarms.map((alarm) => _buildAlarmTile(context, alarm, null)).toList(),
      ),
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
            // Toggle group via provider
            final groupProvider = context.read<AlarmGroupProvider>();
            final updatedGroup = group.copyWith(isActive: value);
            await groupProvider.updateItem(updatedGroup);
            if (mounted) {
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
            ...groupAlarms.asMap().entries.map((entry) {
              final index = entry.key;
              final alarm = entry.value;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 50)),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: _buildAlarmTile(context, alarm, group),
              );
            }),
          
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

  Widget _buildAlarmTile(BuildContext context, Alarm alarm, AlarmGroup? group) {
    final colorScheme = Theme.of(context).colorScheme;
    final isGroupActive = group?.isActive ?? true;
    final isAlarmActive = alarm.isActive && isGroupActive;
    
    return Dismissible(
      key: Key(alarm.id),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe Left: Gruppe zuordnen
          _showGroupAssignmentSheet(context, alarm);
          return false; // Nicht dismissen, nur Action ausführen
        } else if (direction == DismissDirection.startToEnd) {
          // Swipe Right: Löschen mit Bestätigung
          return await _showDeleteConfirmationDialog(context, alarm);
        }
        return false;
      },
      background: _buildSwipeBackground(
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
        Icons.delete_forever,
        'Löschen',
        Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBackground(
        colorScheme.tertiaryContainer,
        colorScheme.onTertiaryContainer,
        Icons.folder_outlined,
        'Gruppe',
        Alignment.centerRight,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: isAlarmActive
              ? LinearGradient(
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.3),
                    colorScheme.primaryContainer.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isAlarmActive ? null : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAlarmActive 
                ? colorScheme.primary.withValues(alpha: 0.3)
                : colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Toggle Switch
            Switch.adaptive(
              value: isAlarmActive,
              onChanged: isGroupActive ? (value) {
                context.read<AlarmProvider>().toggleItem(alarm.id);
              } : null,
              activeColor: colorScheme.primary,
              inactiveThumbColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            
            const SizedBox(width: 12),
            
            // Zeit + Name + Wochentage
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Zeit
                  Consumer<AppSettings>(
                    builder: (context, settings, child) => Text(
                      settings.formatTime(alarm.time),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: isAlarmActive ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w300,
                        fontSize: 32,
                        height: 1.2,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Name
                  if (alarm.label.isNotEmpty)
                    Text(
                      alarm.label,
                      style: TextStyle(
                        color: isAlarmActive ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  
                  const SizedBox(height: 6),
                  
                  // Wochentags-Chips
                  _buildWeekdayChips(alarm, isAlarmActive, colorScheme),
                ],
              ),
            ),
            
            // Edit/Delete Button
            IconButton(
              icon: Icon(
                Icons.more_vert,
                color: isAlarmActive ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
              ),
              onPressed: () => _showAlarmOptions(context, alarm),
            ),
          ],
        ),
      ),
      ),
    );
  }
  
  // Swipe Background Builder
  Widget _buildSwipeBackground(
    Color backgroundColor,
    Color iconColor,
    IconData icon,
    String label,
    Alignment alignment,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 32),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Gruppen-Zuordnung per Swipe
  void _showGroupAssignmentSheet(BuildContext context, Alarm alarm) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Consumer<AlarmGroupProvider>(
        builder: (context, groupProvider, child) {
          final groups = groupProvider.items;
          
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.folder_outlined, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Gruppe zuordnen',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // "Keine Gruppe" Option
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.secondaryContainer,
                    child: Icon(Icons.block, color: colorScheme.onSecondaryContainer, size: 20),
                  ),
                  title: const Text('Keine Gruppe'),
                  subtitle: const Text('Wecker ohne Gruppenzuordnung'),
                  selected: alarm.groupId == null,
                  selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () async {
                    final updatedAlarm = alarm.copyWith(groupId: null);
                    await context.read<AlarmProvider>().updateItem(updatedAlarm);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                
                const SizedBox(height: 8),
                
                // Bestehende Gruppen
                ...groups.map((group) {
                  final isSelected = alarm.groupId == group.id;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected 
                          ? colorScheme.primaryContainer 
                          : colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.folder,
                        color: isSelected 
                            ? colorScheme.onPrimaryContainer 
                            : colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    title: Text(group.name),
                    subtitle: Text('${groups.where((g) => g.id == group.id).length} Wecker'),
                    selected: isSelected,
                    selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    trailing: isSelected ? Icon(Icons.check_circle, color: colorScheme.primary) : null,
                    onTap: () async {
                      final updatedAlarm = alarm.copyWith(groupId: group.id);
                      await context.read<AlarmProvider>().updateItem(updatedAlarm);
                      if (context.mounted) Navigator.pop(context);
                    },
                  );
                }),
                
                const SizedBox(height: 16),
                
                // Neue Gruppe erstellen
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showCreateGroupDialog(context, alarm);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Neue Gruppe erstellen'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  // Neue Gruppe erstellen und zuordnen
  void _showCreateGroupDialog(BuildContext context, Alarm alarm) {
    final controller = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Neue Gruppe erstellen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Gruppenname eingeben',
            prefixIcon: const Icon(Icons.folder),
            filled: true,
            fillColor: colorScheme.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (_) => _createAndAssignGroup(context, controller.text, alarm),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => _createAndAssignGroup(context, controller.text, alarm),
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _createAndAssignGroup(BuildContext context, String groupName, Alarm alarm) async {
    if (groupName.trim().isEmpty) return;
    
    final newGroup = AlarmGroup(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: groupName.trim(),
    );
    
    await context.read<AlarmGroupProvider>().addItem(newGroup);
    
    final updatedAlarm = alarm.copyWith(groupId: newGroup.id);
    await context.read<AlarmProvider>().updateItem(updatedAlarm);
    
    if (context.mounted) {
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wecker zu "${groupName}" hinzugefügt'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  // Delete Confirmation mit async return
  Future<bool> _showDeleteConfirmationDialog(BuildContext context, Alarm alarm) async {
    final settings = context.read<AppSettings>();
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(settings.getText('deleteAlarm')),
        content: Text('Möchtest du den Wecker um ${settings.formatTime(alarm.time)} wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(settings.getText('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(settings.getText('delete')),
          ),
        ],
      ),
    ) ?? false;
  }
  
  Widget _buildWeekdayChips(Alarm alarm, bool isActive, ColorScheme colorScheme) {
    const dayAbbreviations = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    
    if (!alarm.repeat || alarm.repeatDays.isEmpty) {
      return Text(
        'Einmalig',
        style: TextStyle(
          color: isActive ? colorScheme.onSurfaceVariant : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    
    // Alle Tage
    if (alarm.repeatDays.length == 7) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isActive 
              ? colorScheme.secondaryContainer 
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Täglich',
          style: TextStyle(
            color: isActive ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    
    // Werktags
    if (alarm.repeatDays.length == 5 && 
        !alarm.repeatDays.contains(5) && 
        !alarm.repeatDays.contains(6)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isActive 
              ? colorScheme.secondaryContainer 
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Werktags',
          style: TextStyle(
            color: isActive ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    
    // Individuelle Tage als Chips
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(7, (index) {
        final isSelectedDay = alarm.repeatDays.contains(index);
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isSelectedDay
                ? (isActive ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0.5))
                : (isActive ? colorScheme.surfaceContainerHighest : colorScheme.surfaceContainerHigh),
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelectedDay
                  ? (isActive ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0.5))
                  : colorScheme.outline.withValues(alpha: 0.2),
              width: isSelectedDay ? 0 : 1,
            ),
          ),
          child: Center(
            child: Text(
              dayAbbreviations[index],
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelectedDay
                    ? (isActive ? colorScheme.onPrimary : colorScheme.onPrimary.withValues(alpha: 0.8))
                    : (isActive ? colorScheme.onSurfaceVariant : colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
              ),
            ),
          ),
        );
      }),
    );
  }
  
  void _showAlarmOptions(BuildContext context, Alarm alarm) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Bearbeiten'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => UnifiedCreateAlarmDialog(existingAlarm: alarm),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
              title: Text('Löschen', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, alarm);
              },
            ),
          ],
        ),
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
      builder: (context) => UnifiedCreateAlarmDialog(
        preselectedGroupId: group.id,
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