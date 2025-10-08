import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  static AppSettings? _instance;
  
  factory AppSettings() {
    _instance ??= AppSettings._internal();
    return _instance!;
  }
  
  AppSettings._internal() {
    _loadSettings();
  }
  
  bool _is24HourFormat = true;
  String _language = 'de'; // 'de' oder 'en'
  ThemeMode _themeMode = ThemeMode.system; // Dark/Light/System
  
  bool get is24HourFormat => _is24HourFormat;
  String get language => _language;
  ThemeMode get themeMode => _themeMode;
  
  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _is24HourFormat = prefs.getBool('is24HourFormat') ?? true;
      _language = prefs.getString('language') ?? 'de';
      
      final themeModeIndex = prefs.getInt('themeMode') ?? 0;
      _themeMode = ThemeMode.values[themeModeIndex];
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der Einstellungen: $e');
    }
  }
  
  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is24HourFormat', _is24HourFormat);
      await prefs.setString('language', _language);
      await prefs.setInt('themeMode', _themeMode.index);
    } catch (e) {
      debugPrint('❌ Fehler beim Speichern der Einstellungen: $e');
    }
  }
  
  void toggle24HourFormat() {
    _is24HourFormat = !_is24HourFormat;
    _saveSettings();
    notifyListeners();
  }
  
  void setLanguage(String newLanguage) {
    if (newLanguage == 'de' || newLanguage == 'en') {
      _language = newLanguage;
      _saveSettings();
      notifyListeners();
    }
  }
  
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveSettings();
    notifyListeners();
  }
  
  String formatTime(DateTime time) {
    if (_is24HourFormat) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      final hour12 = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
      final period = time.hour >= 12 ? 'PM' : 'AM';
      return '${hour12.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
    }
  }
  
  String getText(String key) {
    final texts = {
      'de': {
        // Navigation
        'clock': 'Uhr',
        'stopwatch': 'Stoppuhr',
        'timer': 'Timer',
        'alarms': 'Wecker',
        'settings': 'Einstellungen',
        'privacy': 'Datenschutzerklärung',
        'feedback': 'Feedback senden',
        'help': 'Hilfe',
        
        // Settings
        'language': 'Sprache',
        'timeFormat': 'Uhrzeitformat',
        '24hour': '24-Stunden',
        '12hour': '12-Stunden',
        'german': 'Deutsch',
        'english': 'English',
        'currentFormat': 'Aktuelles Format',
        
        // Alarms
        'newAlarm': 'Neuer Wecker',
        'addAlarm': 'Wecker hinzufügen',
        'deleteAlarm': 'Wecker löschen?',
        'editAlarm': 'Wecker bearbeiten',
        'alarmTime': 'Weckzeit',
        'alarmName': 'Wecker Name',
        'alarmGroup': 'Wecker Gruppe',
        'noAlarms': 'Keine Wecker vorhanden',
        'activeAlarms': 'Aktive Wecker',
        'inactiveAlarms': 'Inaktive Wecker',
  'label': 'Label',
  'addLabel': 'Label hinzufügen',
  'selectLabel': 'Label auswählen',
  'createLabel': 'Neues Label erstellen',
        
        // General
        'cancel': 'Abbrechen',
        'delete': 'Löschen',
        'save': 'Speichern',
        'edit': 'Bearbeiten',
        'add': 'Hinzufügen',
        'ok': 'OK',
        'yes': 'Ja',
        'no': 'Nein',
        
        // Form fields
        'description': 'Beschreibung (optional)',
        'selectGroup': 'Gruppe auswählen',
        'createNewGroup': 'Neue Gruppe erstellen',
        'groupName': 'Gruppenname',
        'enterGroupName': 'Gruppenname eingeben',
  'enterLabelName': 'Labelname eingeben',
        'repeat': 'Wiederholen',
        'enabled': 'Aktiviert',
        'disabled': 'Deaktiviert',
  'repeatSelectedDays': 'An ausgewählten Tagen wiederholen',
  'repeatDays': 'Wiederholungstage:',
        
        // Time & Date
        'time': 'Zeit',
        'date': 'Datum',
        'today': 'Heute',
        'tomorrow': 'Morgen',
        'yesterday': 'Gestern',
        'weekdays': 'Wochentage',
        'weekend': 'Wochenende',
        'daily': 'Täglich',
        'never': 'Niemals',
        
        // Other
        'screenSaver': 'Bildschirmschoner',
  'deleteConfirm': 'Bist du sicher?',
        'worldClock': 'Weltzeituhr',
        'addLocation': 'Ort hinzufügen',
        'localTime': 'Ortszeit',
        'selectLocation': 'Ort auswählen',
        'enterCityName': 'Stadtname eingeben',
        'removeLocation': 'Ort entfernen',
        
        // Days of week
        'monday': 'Montag',
        'tuesday': 'Dienstag',
        'wednesday': 'Mittwoch',
        'thursday': 'Donnerstag',
        'friday': 'Freitag',
        'saturday': 'Samstag',
        'sunday': 'Sonntag',
        
        // Short days
        'mon': 'Mo',
        'tue': 'Di',
        'wed': 'Mi',
        'thu': 'Do',
        'fri': 'Fr',
        'sat': 'Sa',
        'sun': 'So',
      },
      'en': {
        // Navigation
        'clock': 'Clock',
        'stopwatch': 'Stopwatch',
        'timer': 'Timer',
        'alarms': 'Alarms',
        'settings': 'Settings',
        'privacy': 'Privacy Policy',
        'feedback': 'Send Feedback',
        'help': 'Help',
        
        // Settings
        'language': 'Language',
        'timeFormat': 'Time Format',
        '24hour': '24-hour',
        '12hour': '12-hour',
        'german': 'Deutsch',
        'english': 'English',
        'currentFormat': 'Current Format',
        
        // Alarms
        'newAlarm': 'New Alarm',
        'addAlarm': 'Add Alarm',
        'deleteAlarm': 'Delete Alarm?',
        'editAlarm': 'Edit Alarm',
        'alarmTime': 'Alarm Time',
        'alarmName': 'Alarm Name',
        'alarmGroup': 'Alarm Group',
        'noAlarms': 'No alarms available',
        'activeAlarms': 'Active Alarms',
        'inactiveAlarms': 'Inactive Alarms',
  'label': 'Label',
  'addLabel': 'Add Label',
  'selectLabel': 'Select Label',
  'createLabel': 'Create Label',
        
        // General
        'cancel': 'Cancel',
        'delete': 'Delete',
        'save': 'Save',
        'edit': 'Edit',
        'add': 'Add',
        'ok': 'OK',
        'yes': 'Yes',
        'no': 'No',
        
        // Form fields
        'description': 'Description (optional)',
        'selectGroup': 'Select Group',
        'createNewGroup': 'Create New Group',
        'groupName': 'Group Name',
        'enterGroupName': 'Enter group name',
  'enterLabelName': 'Enter label name',
        'repeat': 'Repeat',
        'enabled': 'Enabled',
        'disabled': 'Disabled',
  'repeatSelectedDays': 'Repeat on selected days',
  'repeatDays': 'Repeat days:',
        
        // Time & Date
        'time': 'Time',
        'date': 'Date',
        'today': 'Today',
        'tomorrow': 'Tomorrow',
        'yesterday': 'Yesterday',
        'weekdays': 'Weekdays',
        'weekend': 'Weekend',
        'daily': 'Daily',
        'never': 'Never',
        
        // Other
        'screenSaver': 'Screen Saver',
  'deleteConfirm': 'Are you sure?',
        'worldClock': 'World Clock',
        'addLocation': 'Add Location',
        'localTime': 'Local Time',
        'selectLocation': 'Select Location',
        'enterCityName': 'Enter city name',
        'removeLocation': 'Remove Location',
        
        // Days of week
        'monday': 'Monday',
        'tuesday': 'Tuesday',
        'wednesday': 'Wednesday',
        'thursday': 'Thursday',
        'friday': 'Friday',
        'saturday': 'Saturday',
        'sunday': 'Sunday',
        
        // Short days
        'mon': 'Mon',
        'tue': 'Tue',
        'wed': 'Wed',
        'thu': 'Thu',
        'fri': 'Fri',
        'sat': 'Sat',
        'sun': 'Sun',
      },
    };
    
    return texts[_language]?[key] ?? key;
  }
}