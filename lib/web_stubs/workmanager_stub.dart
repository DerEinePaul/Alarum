/// Web stub for Workmanager functionality
/// This file provides dummy implementations for background task features on web platform
library;

class Workmanager {
  static Workmanager? _instance;
  
  static Workmanager instance() {
    _instance ??= Workmanager();
    return _instance!;
  }
  
  Workmanager();
  
  Future<void> initialize(Function callbackDispatcher, {bool isInDebugMode = false}) async {
    // No-op on web
  }
  
  Future<void> registerOneOffTask(String uniqueName, String taskName, {Map<String, dynamic>? inputData, Duration? initialDelay}) async {
    // No-op on web
  }
  
  Future<void> cancelByUniqueName(String uniqueName) async {
    // No-op on web
  }
  
  Future<bool> executeTask(Future<bool> Function(String, Map<String, dynamic>?) task) async {
    return true;
  }
}