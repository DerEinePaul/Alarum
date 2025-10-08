/// Web stub for dart:isolate functionality
/// This file provides dummy implementations for isolate features on web platform
library;

class ReceivePort {
  ReceivePort();
  
  Stream<dynamic> get stream => Stream.empty();
  
  void listen(void Function(dynamic) onData) {}
  
  void close() {}
  
  SendPort get sendPort => SendPort();
}

class SendPort {
  SendPort();
  
  void send(dynamic message) {}
}

class IsolateNameServer {
  static bool registerPortWithName(SendPort port, String name) => false;
  
  static SendPort? lookupPortByName(String name) => null;
  
  static bool removePortNameMapping(String name) => false;
}