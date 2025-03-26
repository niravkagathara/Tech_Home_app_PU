import 'package:flutter/material.dart';
import 'mqtt_service.dart';

class MQTTProvider with ChangeNotifier {
  final MQTTService _mqttService = MQTTService();
  Map<String, String> _messages = {};
  bool _isConnected = false;

  Map<String, String> get messages => _messages;
  bool get isConnected => _isConnected;
  Future<void> reconnect() async {
    await _mqttService.connect();
    notifyListeners();
  }
  MQTTProvider() {
    _mqttService.onMessageReceived = (topic, message) {
      _messages[topic] = message;
      notifyListeners();
    };


    _mqttService.onConnectionStatusChanged = (isConnected) {
      _isConnected = isConnected;
      notifyListeners();
    };

    _mqttService.connect();
  }
  void refreshDashboard() {
    notifyListeners(); // This will rebuild widgets listening to the provider
  }
  void publish(String topic, String message) {
    _mqttService.publish(topic, message);
  }
}