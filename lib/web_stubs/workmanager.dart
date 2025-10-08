/// Workmanager stub für Web-Plattform
/// Diese Datei stellt Dummy-Implementierungen für Workmanager Features auf Web bereit
library;

class Workmanager {
  static Workmanager? _instance;
  
  factory Workmanager() {
    _instance ??= Workmanager._internal();
    return _instance!;
  }
  
  Workmanager._internal();
  
  Future<void> initialize(
    Function callbackDispatcher, {
    bool isInDebugMode = false,
  }) async {
    // Web: Keine Background-Tasks, sofort zurückkehren
  }
  
  Future<void> registerOneOffTask(
    String uniqueName,
    String taskName, {
    String? tag,
    Map<String, dynamic>? inputData,
    Duration? initialDelay,
    Map<String, dynamic>? constraints,
  }) async {
    // Web: Keine Background-Tasks möglich
  }
  
  Future<void> cancelAll() async {
    // Web: Keine Aktion erforderlich
  }
  
  Future<void> cancelByUniqueName(String uniqueName) async {
    // Web: Keine Aktion erforderlich
  }
  
  Future<bool> executeTask(
    Future<bool> Function(String, Map<String, dynamic>?) task
  ) async {
    // Web: Keine Background-Execution
    return false;
  }
}