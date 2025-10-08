import 'package:flutter/material.dart';

/// Business Logic Controller für Alarm Dialog
/// 
/// Trennt UI von Logik nach Clean Architecture Prinzipien
class AlarmDialogController extends ChangeNotifier {
  // State
  TimeOfDay _selectedTime;
  String _label;
  String? _selectedGroupId;
  String _selectedSound;
  bool _vibrate;
  final Set<int> _selectedDays;
  final List<String> _tags;
  bool _isCreatingNewGroup;
  String _newGroupName;

  // Constructor
  AlarmDialogController({
    TimeOfDay? initialTime,
    String? initialLabel,
    String? preselectedGroupId,
    String initialSound = 'grains',
    bool initialVibrate = true,
    Set<int>? initialDays,
    List<String>? initialTags,
  })  : _selectedTime = initialTime ?? TimeOfDay.now(),
        _label = initialLabel ?? '',
        _selectedGroupId = preselectedGroupId,
        _selectedSound = initialSound,
        _vibrate = initialVibrate,
        _selectedDays = initialDays ?? {},
        _tags = initialTags ?? [],
        _isCreatingNewGroup = false,
        _newGroupName = '';

  // Getters
  TimeOfDay get selectedTime => _selectedTime;
  String get label => _label;
  String? get selectedGroupId => _selectedGroupId;
  String get selectedSound => _selectedSound;
  bool get vibrate => _vibrate;
  Set<int> get selectedDays => _selectedDays;
  List<String> get tags => _tags;
  bool get isCreatingNewGroup => _isCreatingNewGroup;
  String get newGroupName => _newGroupName;

  /// Validierung: Dialog kann nur gespeichert werden wenn Gruppe vorhanden
  bool get isValid {
    if (_isCreatingNewGroup) {
      return _newGroupName.trim().isNotEmpty;
    }
    return _selectedGroupId != null;
  }

  /// Hat der Benutzer Wiederholungen aktiviert?
  bool get hasRepeat => _selectedDays.isNotEmpty;

  // Setters with notifications
  
  void updateTime(TimeOfDay time) {
    _selectedTime = time;
    notifyListeners();
  }

  void updateLabel(String label) {
    _label = label;
    notifyListeners();
  }

  void selectGroup(String? groupId) {
    _selectedGroupId = groupId;
    _isCreatingNewGroup = false;
    notifyListeners();
  }

  void updateSound(String sound) {
    _selectedSound = sound;
    notifyListeners();
  }

  void toggleVibrate() {
    _vibrate = !_vibrate;
    notifyListeners();
  }

  void setVibrate(bool value) {
    _vibrate = value;
    notifyListeners();
  }

  void toggleDay(int day) {
    if (_selectedDays.contains(day)) {
      _selectedDays.remove(day);
    } else {
      _selectedDays.add(day);
    }
    notifyListeners();
  }

  void addTag(String tag) {
    if (!_tags.contains(tag) && tag.trim().isNotEmpty) {
      _tags.add(tag.trim());
      notifyListeners();
    }
  }

  void removeTag(String tag) {
    _tags.remove(tag);
    notifyListeners();
  }

  void setCreatingNewGroup(bool value) {
    _isCreatingNewGroup = value;
    if (value) {
      _selectedGroupId = null;
    }
    notifyListeners();
  }

  void updateNewGroupName(String name) {
    _newGroupName = name;
    notifyListeners();
  }

  /// Verfügbare Sounds (kann später aus Repository kommen)
  static const List<String> availableSounds = [
    'grains',
    'oxygen',
    'helium',
    'carbon',
    'argon',
    'neon',
    'pluto',
  ];

  /// Sound anzeige-Namen
  static String getSoundDisplayName(String sound) {
    final names = {
      'grains': 'Grains',
      'oxygen': 'Oxygen',
      'helium': 'Helium',
      'carbon': 'Carbon',
      'argon': 'Argon',
      'neon': 'Neon',
      'pluto': 'Pluto',
    };
    return names[sound] ?? sound;
  }

  /// Reset zu Standardwerten
  void reset() {
    _selectedTime = TimeOfDay.now();
    _label = '';
    _selectedGroupId = null;
    _selectedSound = 'grains';
    _vibrate = true;
    _selectedDays.clear();
    _tags.clear();
    _isCreatingNewGroup = false;
    _newGroupName = '';
    notifyListeners();
  }
}
