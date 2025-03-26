import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:uuid/uuid.dart';

String generateClientId() {
  var uuid = Uuid();
  return 'flutter_client_${uuid.v4()}';
}
class MQTTService {
  late MqttServerClient _client;
  final String broker = 'url';
  final int port = 8883;
  final String clientId = generateClientId();
  final String username = '';
  final String password = 'bk';

  final Map<String, String> _messages = {};

  // Callback to notify UI when a new message is received
  Function(String topic, String message)? onMessageReceived;

  // Callback to notify UI when the connection status changes
  Function(bool isConnected)? onConnectionStatusChanged;

  // Track connection status
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    _client = MqttServerClient(broker, clientId);
    _client.port = port;
    _client.secure = true;
    _client.keepAlivePeriod = 60;
    _client.onDisconnected = onDisconnected;
    _client.logging(on: true);

    _client.onConnected = onConnected;
    _client.onSubscribed = onSubscribed;

    final connMessage = MqttConnectMessage()
        .authenticateAs(username, password)
        .withClientIdentifier(clientId)
        .startClean();
    _client.connectionMessage = connMessage;

    try {
      await _client.connect();
    } catch (e) {
      print('Exception: $e');
      _client.disconnect();
    }

    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      print('Connected to MQTT broker');
      _isConnected = true;
      onConnectionStatusChanged?.call(_isConnected); // Notify connection status
      subscribeToTopics();
    } else {
      print('Failed to connect');
      _isConnected = false;
      onConnectionStatusChanged?.call(_isConnected); // Notify connection status
    }
  }

  void subscribeToTopics() {
    final topics = [
      'esp',
      'smarthome/ldr',
      'smarthome/ldr/value',
      'smarthome/ldr/onoff',
      'smarthome/fire',
      'smarthome/fire/value',
      'smarthome/fire/onoff',
      'smarthome/fan/value',
      'smarthome/led/value',
      'smarthome/temp',
      'smarthome/hume',
      'smarthome/temp/onoff',
      'smarthome/moisture',
      'smarthome/moisture/value',
      'smarthome/moisture/onoff',
      'smarthome/ultrasonic',
      'smarthome/ultrasonic/value',
      'smarthome/ultrasonic/onoff',
      'smarthome/gas',
      'smarthome/gas/value',
      'smarthome/gas/onoff',
      'smarthome/motion',
      'smarthome/motion/value',
      'smarthome/motion/onoff',
      'smarthome/value/device1',
      'smarthome/value/device2',
    ];

    for (var topic in topics) {
      _client.subscribe(topic, MqttQos.atMostOnce);
    }

    _client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final String topic = c[0].topic;
      final String payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);

      _messages[topic] = payload;
      print('Message received on topic $topic: $payload');

      // Notify UI about the new message
      if (onMessageReceived != null) {
        onMessageReceived!(topic, payload);
      }
    });
  }

  void publish(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void onConnected() {
    print('Client connected');
    _isConnected = true;
    onConnectionStatusChanged?.call(_isConnected); // Notify connection status
  }

  void onSubscribed(String topic) {
    print('Subscribed to $topic');
  }

  void onDisconnected() {
    print('Client disconnected');
    _isConnected = false;
    onConnectionStatusChanged?.call(_isConnected); // Notify connection status
  }

  Map<String, String> get messages => _messages;
}