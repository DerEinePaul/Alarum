import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/alarm_provider.dart';
import '../../providers/alarm_group_provider.dart';
import '../../../domain/models/alarm.dart';
import '../../../domain/models/alarm_group.dart';
import '../../../core/settings/app_settings.dart';

/// Unified Material 3 Expressive Create Alarm Dialog
/// 
/// Einheitliches Design für Web & Android nach Bild 3:
/// - Große Zeitanzeige (06:50)
/// - Wochentags-Chips (M D M D F S S)
/// - Minimalistischer Dark Mode
/// - Klare Hierarchie
/// - Material 3 Expressive Animationen
class UnifiedCreateAlarmDialog extends StatefulWidget {
  final String? preselectedGroupId;
  final Alarm? existingAlarm;

  const UnifiedCreateAlarmDialog({
    super.key,
    this.preselectedGroupId,
    this.existingAlarm,
  });

  @override
  State<UnifiedCreateAlarmDialog> createState() => _UnifiedCreateAlarmDialogState();
}

class _UnifiedCreateAlarmDialogState extends State<UnifiedCreateAlarmDialog>
    with SingleTickerProviderStateMixin {
  late TimeOfDay _selectedTime;
  late List<int> _selectedDays;
  late String _alarmName;
  late String? _selectedGroupId;
  late String _selectedSound;
  late bool _vibrate;
  late List<String> _tags;
  
  // Controllers for inline creation
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  bool _isCreatingNewGroup = false;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize values
    _selectedTime = widget.existingAlarm != null
        ? TimeOfDay.fromDateTime(widget.existingAlarm!.time)
        : TimeOfDay.now();
    _selectedDays = widget.existingAlarm?.repeatDays ?? [];
    _alarmName = widget.existingAlarm?.label ?? '';
    _selectedGroupId = widget.preselectedGroupId ?? widget.existingAlarm?.groupId;
    _selectedSound = widget.existingAlarm?.sound ?? 'Standard Alarm';
    _vibrate = widget.existingAlarm?.vibrate ?? true;
    _tags = [];

    // Entry Animation - Elastic & Smooth
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _groupNameController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _handleTimeEdit() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              timePickerTheme: TimePickerThemeData(
                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                dialBackgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                hourMinuteColor: Theme.of(context).colorScheme.primaryContainer,
                hourMinuteTextColor: Theme.of(context).colorScheme.onPrimaryContainer,
                dayPeriodColor: Theme.of(context).colorScheme.primaryContainer,
                dayPeriodTextColor: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
      _selectedDays.sort();
    });
  }

  Future<void> _handleSave() async {
    final provider = context.read<AlarmProvider>();

    // Keine Validierung mehr - groupId kann null sein ("Keine Gruppe")

    final now = DateTime.now();
    final alarmTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final newAlarm = Alarm(
      id: widget.existingAlarm?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      time: alarmTime,
      label: _alarmName.isEmpty ? 'Wecker' : _alarmName,
      groupId: _selectedGroupId, // Kann null sein
      isActive: true,
      sound: _selectedSound,
      repeat: _selectedDays.isNotEmpty,
      repeatDays: _selectedDays,
      vibrate: _vibrate,
    );

    if (widget.existingAlarm != null) {
      await provider.updateItem(newAlarm);
    } else {
      await provider.addItem(newAlarm);
    }

    if (mounted) {
      Navigator.of(context).pop(newAlarm);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final settings = context.watch<AppSettings>();

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) => ScaleTransition(
        scale: _scaleAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Dialog(
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 3,
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 400,
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // ═══════════════════════════════════════════════════════════
                  // HEADER - Große Zeitanzeige (REDESIGNED)
                  // ═══════════════════════════════════════════════════════════
                  InkWell(
                    onTap: _handleTimeEdit,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primaryContainer,
                            colorScheme.primaryContainer.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Große Uhrzeit
                          Text(
                            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                            style: textTheme.displayLarge?.copyWith(
                              fontSize: 56,
                              fontWeight: FontWeight.w200,
                              color: colorScheme.onPrimaryContainer,
                              letterSpacing: -2,
                              height: 1,
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Tippen zum Bearbeiten Hint
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.touch_app,
                                size: 14,
                                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                settings.getText('edit'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ═══════════════════════════════════════════════════════════
                  // WOCHENTAGS-AUSWAHL
                  // ═══════════════════════════════════════════════════════════
                  _buildWeekdaySelector(),

                  const SizedBox(height: 10),

                  // ═══════════════════════════════════════════════════════════
                  // FORM CONTENT - Kompakt ohne Scrolling
                  // ═══════════════════════════════════════════════════════════
                  // Name des Weckrufs
                  _buildTextField(
                    icon: Icons.edit_outlined,
                    label: settings.getText('alarmName'),
                    hint: settings.getText('alarmNameHint'),
                    value: _alarmName,
                    onChanged: (value) => setState(() => _alarmName = value),
                  ),

                  const SizedBox(height: 8),

                  // Gruppe auswählen
                  _buildGroupSelector(),

                  const SizedBox(height: 8),

                  // Ton
                  _buildSoundSelector(),

                  const SizedBox(height: 8),

                  // Vibrieren Toggle
                  _buildToggleTile(
                    icon: Icons.vibration,
                    label: settings.getText('vibrate'),
                    value: _vibrate,
                    onChanged: (value) => setState(() => _vibrate = value),
                  ),

                  const SizedBox(height: 8),

                  // Tags
                  _buildTagsSection(),

                  const SizedBox(height: 8),

                  // ═══════════════════════════════════════════════════════════
                  // ACTION BUTTONS
                  // ═══════════════════════════════════════════════════════════
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(settings.getText('delete')),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.error,
                        ),
                      ),
                      FilledButton(
                        onPressed: _handleSave,
                        child: Text(settings.getText('save')),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(120, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WOCHENTAGS-CHIPS
  // ═══════════════════════════════════════════════════════════
  Widget _buildWeekdaySelector() {
    final colorScheme = Theme.of(context).colorScheme;
    const days = ['M', 'D', 'M', 'D', 'F', 'S', 'S'];
    final hasNoSelection = _selectedDays.isEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final isSelected = _selectedDays.contains(index);
        
        return GestureDetector(
          onTap: () => _toggleDay(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest.withValues(alpha: hasNoSelection ? 0.3 : 1.0),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: hasNoSelection ? 0.15 : 0.3),
                width: isSelected ? 0 : 1,
              ),
            ),
            child: Center(
              child: Text(
                days[index],
                style: TextTheme(
                  displaySmall: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant.withValues(alpha: hasNoSelection ? 0.4 : 1.0),
                  ),
                ).displaySmall,
              ),
            ),
          ),
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TEXT FIELD COMPONENT
  // ═══════════════════════════════════════════════════════════
  Widget _buildTextField({
    required IconData icon,
    required String label,
    required String hint,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: value)
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: value.length),
                ),
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // GRUPPE SELECTOR MIT INLINE-ERSTELLUNG
  // ═══════════════════════════════════════════════════════════
  Widget _buildGroupSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<AppSettings>();

    return Consumer<AlarmGroupProvider>(
      builder: (context, provider, child) {
        final groups = provider.items;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              settings.getText('selectGroup'),
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            // Gruppen Dropdown oder Neue Gruppe Input
            if (_isCreatingNewGroup)
              // NEUE GRUPPE ERSTELLEN - Konsistentes Design
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.folder, color: colorScheme.onSurfaceVariant, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _groupNameController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: settings.getText('enterGroupName'),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 15,
                        ),
                        onSubmitted: (_) => _createNewGroup(provider),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _createNewGroup(provider),
                      icon: const Icon(Icons.check, size: 20),
                      tooltip: settings.getText('save'),
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      onPressed: () => setState(() {
                        _isCreatingNewGroup = false;
                        _groupNameController.clear();
                      }),
                      icon: const Icon(Icons.close, size: 20),
                      tooltip: settings.getText('cancel'),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              )
            else
              // GRUPPEN AUSWAHL
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // "Keine Gruppe" Option
                  FilterChip(
                    label: const Text('Keine Gruppe'),
                    selected: _selectedGroupId == null,
                    onSelected: (selected) {
                      setState(() => _selectedGroupId = null);
                    },
                    avatar: _selectedGroupId == null ? null : const Icon(Icons.block, size: 18),
                    selectedColor: colorScheme.secondaryContainer,
                    checkmarkColor: colorScheme.onSecondaryContainer,
                  ),
                  
                  // Bestehende Gruppen als Chips
                  ...groups.map((group) {
                    final isSelected = group.id == _selectedGroupId;
                    return FilterChip(
                      label: Text(group.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedGroupId = group.id);
                      },
                      avatar: isSelected ? null : const Icon(Icons.folder_outlined, size: 18),
                      selectedColor: colorScheme.primaryContainer,
                      checkmarkColor: colorScheme.onPrimaryContainer,
                    );
                  }),
                  
                  // Neue Gruppe Button
                  FilterChip(
                    label: Text(settings.getText('createNewGroup')),
                    avatar: const Icon(Icons.add, size: 18),
                    onSelected: (_) => setState(() => _isCreatingNewGroup = true),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    side: BorderSide(color: colorScheme.primary, width: 1.5),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
  
  void _createNewGroup(AlarmGroupProvider provider) async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) return;
    
    final newGroup = AlarmGroup(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: groupName,
    );
    
    await provider.addItem(newGroup);
    
    setState(() {
      _selectedGroupId = newGroup.id;
      _isCreatingNewGroup = false;
      _groupNameController.clear();
    });
  }

  // ═══════════════════════════════════════════════════════════
  // TON SELECTOR
  // ═══════════════════════════════════════════════════════════
  Widget _buildSoundSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<AppSettings>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_outlined, color: colorScheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.getText('alarmName'),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedSound,
                  style: TextStyle(
                    fontSize: 15,
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TOGGLE TILE
  // ═══════════════════════════════════════════════════════════
  Widget _buildToggleTile({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAGS SECTION MIT DIREKTER EINGABE
  // ═══════════════════════════════════════════════════════════
  Widget _buildTagsSection() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        // Tag Input Field - Konsistentes Design
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.label_outline, color: colorScheme.onSurfaceVariant, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _tagController,
                  decoration: const InputDecoration(
                    hintText: 'Tag eingeben und Enter drücken',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 15,
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty && !_tags.contains(value.trim())) {
                      setState(() {
                        _tags.add(value.trim());
                        _tagController.clear();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Tag Chips
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => setState(() => _tags.remove(tag)),
                backgroundColor: colorScheme.secondaryContainer,
                labelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
