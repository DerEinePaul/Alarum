import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/alarm_group_service.dart';
import '../../core/settings/app_settings.dart';
import '../../domain/models/label.dart';
import '../../data/repositories/label_repository.dart';
import '../providers/label_provider.dart';
import '../../domain/models/alarm_group.dart';
import '../../data/repositories/alarm_repository.dart';
import '../../data/repositories/alarm_group_repository.dart';
import '../providers/alarm_provider.dart';
import '../providers/alarm_group_provider.dart';

class CreateAlarmDialog extends StatefulWidget {
  final AlarmGroup? preselectedGroup;
  final Function(dynamic) onAlarmCreated;

  const CreateAlarmDialog({
    super.key,
    this.preselectedGroup,
    required this.onAlarmCreated,
  });

  @override
  State<CreateAlarmDialog> createState() => _CreateAlarmDialogState();
}

class _CreateAlarmDialogState extends State<CreateAlarmDialog> {
  late TimeOfDay _selectedTime;
  late AlarmGroup? _selectedGroup;
  final _labelController = TextEditingController();
  final _newGroupController = TextEditingController();
  bool _repeat = false;
  final Set<int> _repeatDays = {};
  bool _isCreatingNewGroup = false;

  @override
  void initState() {
    super.initState();
    _selectedTime = TimeOfDay.now();
    _selectedGroup = widget.preselectedGroup;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _newGroupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), // Material 3 rounded corners
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 700),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Consumer<AppSettings>(
                builder: (context, settings, child) => Text(
                  settings.getText('newAlarm'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Time Picker
              _buildTimePicker(context),
              const SizedBox(height: 24),
              
              // Label Input
              _buildLabelInput(context),
              const SizedBox(height: 24),
              
              // Group Selection (MANDATORY)
              _buildGroupSelection(context),
              const SizedBox(height: 24),
              
              // Repeat Settings
              _buildRepeatSettings(context),
              
              const SizedBox(height: 32),
              
              // Action Buttons
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: () => _selectTime(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.primary, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, color: colorScheme.primary, size: 32),
            const SizedBox(width: 16),
            Text(
              _selectedTime.format(context),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w300,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelInput(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Consumer2<LabelProvider, AppSettings>(
      builder: (context, labelProvider, settings, child) {
        final labels = labelProvider.items;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              settings.getText('label'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Label?>(
                        value: null,
                        isExpanded: true,
                        hint: Text(settings.getText('selectLabel'), style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        items: labels.map((l) => DropdownMenuItem<Label?>(
                          value: l,
                          child: Row(
                            children: [
                              Container(width: 12, height: 12, decoration: BoxDecoration(color: Color(l.color), shape: BoxShape.circle)),
                              const SizedBox(width: 12),
                              Text(l.name, style: TextStyle(color: colorScheme.onSurface)),
                            ],
                          ),
                        )).toList(),
                        onChanged: (label) {
                          if (label != null) {
                            _labelController.text = label.name;
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    // Inline add label dialog
                    showDialog(context: context, builder: (ctx) {
                      final _tmpController = TextEditingController();
                      return AlertDialog(
                        title: Text(settings.getText('createLabel')),
                        content: TextField(
                          controller: _tmpController,
                          decoration: InputDecoration(hintText: settings.getText('enterLabelName')),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(settings.getText('cancel'))),
                          FilledButton(onPressed: () async {
                            final name = _tmpController.text.trim();
                            if (name.isNotEmpty) {
                              final newLabel = Label(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, color: Theme.of(context).colorScheme.primary.value);
                              await labelProvider.add(newLabel);
                              _labelController.text = name;
                              Navigator.of(ctx).pop();
                            }
                          }, child: Text(settings.getText('add'))),
                        ],
                      );
                    });
                  },
                  child: Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: settings.getText('description'),
                hintText: settings.language == 'de' ? 'z.B. Aufstehen, Meeting...' : 'e.g. Wake up, Meeting...',
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
                prefixIcon: Icon(Icons.label_outline, color: colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGroupSelection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Consumer2<AlarmGroupProvider, AppSettings>(
      builder: (context, groupProvider, settings, child) {
        final groups = groupProvider.items;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  settings.getText('selectGroup'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  ' *',
                  style: TextStyle(color: colorScheme.error, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Toggles zwischen Dropdown und neuer Gruppe
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text(settings.getText('selectGroup')),
                        icon: Icon(Icons.list, size: 18),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text(settings.getText('createNewGroup')),
                        icon: Icon(Icons.add_circle_outline, size: 18),
                      ),
                    ],
                    selected: {_isCreatingNewGroup},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _isCreatingNewGroup = newSelection.first;
                        if (_isCreatingNewGroup) {
                          _selectedGroup = null;
                        }
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return colorScheme.primaryContainer;
                        }
                        return colorScheme.surfaceContainerHighest;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return colorScheme.onPrimaryContainer;
                        }
                        return colorScheme.onSurface;
                      }),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (_isCreatingNewGroup) 
              _buildNewGroupInput(context)
            else 
              _buildGroupDropdown(context, groups),
              
            if ((_selectedGroup == null && !_isCreatingNewGroup) || 
                (_isCreatingNewGroup && _newGroupController.text.trim().isEmpty))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _isCreatingNewGroup 
                    ? settings.getText('enterGroupName')
                    : settings.getText('selectGroup'),
                  style: TextStyle(
                    color: colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildGroupDropdown(BuildContext context, List<AlarmGroup> groups) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16), // Material 3 border radius
        border: _selectedGroup == null 
          ? Border.all(color: colorScheme.error, width: 1)
          : Border.all(color: colorScheme.outline.withValues(alpha: 0.5), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: Consumer<AppSettings>(
          builder: (context, settings, child) => DropdownButton<AlarmGroup>(
            value: _selectedGroup,
            isExpanded: true,
            hint: Text(
              settings.getText('selectGroup'),
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            icon: Icon(Icons.expand_more, color: colorScheme.onSurfaceVariant),
            items: groups.map((group) => DropdownMenuItem(
              value: group,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(group.color),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      group.name,
                      style: TextStyle(color: colorScheme.onSurface),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )).toList(),
            onChanged: (group) {
              setState(() {
                _selectedGroup = group;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNewGroupInput(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer<AppSettings>(
      builder: (context, settings, child) => TextField(
        controller: _newGroupController,
        decoration: InputDecoration(
          labelText: settings.getText('groupName'),
          hintText: settings.language == 'de' ? 'z.B. Morgenroutine, Arbeit...' : 'e.g. Morning routine, Work...',
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.error, width: 1),
          ),
          prefixIcon: Icon(Icons.folder_outlined, color: colorScheme.onSurfaceVariant),
        ),
        onChanged: (value) {
          setState(() {}); // Trigger rebuild for validation
        },
      ),
    );
  }

  Widget _buildRepeatSettings(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Consumer<AppSettings>(
      builder: (context, settings, child) => Card(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile.adaptive(
                title: Text(
                  settings.getText('repeat'),
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  _repeat ? settings.getText('repeatSelectedDays') : settings.getText('never'),
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                value: _repeat,
                onChanged: (value) {
                  setState(() {
                    _repeat = value;
                    if (!value) _repeatDays.clear();
                  });
                },
                activeThumbColor: colorScheme.primary,
                activeTrackColor: colorScheme.primaryContainer,
                contentPadding: EdgeInsets.zero,
              ),
              if (_repeat) ...[
                const SizedBox(height: 16),
                Text(
                  settings.getText('repeatDays'),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(7, (index) {
                    final weekdays = [
                      settings.getText('mon'),
                      settings.getText('tue'),
                      settings.getText('wed'),
                      settings.getText('thu'),
                      settings.getText('fri'),
                      settings.getText('sat'),
                      settings.getText('sun'),
                    ];
                    final isSelected = _repeatDays.contains(index);
                    return FilterChip(
                      label: Text(
                        weekdays[index],
                        style: TextStyle(
                          color: isSelected 
                            ? colorScheme.onSecondaryContainer 
                            : colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _repeatDays.add(index);
                          } else {
                            _repeatDays.remove(index);
                          }
                        });
                      },
                      selectedColor: colorScheme.secondaryContainer,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      checkmarkColor: colorScheme.onSecondaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected 
                            ? colorScheme.secondary 
                            : colorScheme.outline.withValues(alpha: 0.5),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canCreate = _isCreatingNewGroup 
      ? _newGroupController.text.trim().isNotEmpty
      : _selectedGroup != null;
    
    return Consumer<AppSettings>(
      builder: (context, settings, child) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(
              settings.getText('cancel'),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: canCreate ? () => _createAlarm(context) : null,
            style: FilledButton.styleFrom(
              backgroundColor: canCreate ? colorScheme.primary : colorScheme.surfaceContainerHighest,
              foregroundColor: canCreate ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: canCreate ? 2 : 0,
            ),
            child: Text(
              settings.getText('add'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  Future<void> _createAlarm(BuildContext context) async {
    final canCreate = _isCreatingNewGroup 
      ? _newGroupController.text.trim().isNotEmpty
      : _selectedGroup != null;
    
    if (!canCreate) return;
    
    // Capture context and theme before async operations
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final successColor = Theme.of(context).colorScheme.primary;
    
    try {
      final now = DateTime.now();
      final alarmTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      
      // If time is in the past, set for tomorrow
      final finalTime = alarmTime.isBefore(now) 
        ? alarmTime.add(const Duration(days: 1))
        : alarmTime;
      
      final groupService = AlarmGroupService(
        context.read<AlarmProvider>().repository as AlarmRepository,
        context.read<AlarmGroupProvider>().repository as AlarmGroupRepository,
      );
      
      String groupId;
      
      // Create new group if needed
      if (_isCreatingNewGroup) {
        final groupName = _newGroupController.text.trim();
        final newGroup = AlarmGroup(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: groupName,
          description: 'Erstellt bei Alarm-Erstellung',
          color: Theme.of(context).colorScheme.primaryContainer.value,
        );
        
        await context.read<AlarmGroupProvider>().addItem(newGroup);
        groupId = newGroup.id;
        
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Neue Gruppe "$groupName" erstellt'),
              backgroundColor: successColor,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        groupId = _selectedGroup!.id;
      }
      
      await groupService.createAlarm(
        groupId: groupId,
        time: finalTime,
        label: _labelController.text.trim(),
        repeat: _repeat,
        repeatDays: _repeatDays.toList(),
      );
      
      widget.onAlarmCreated(null);
      if (mounted) navigator.pop();
      
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Fehler beim Erstellen: $e'),
            backgroundColor: errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}