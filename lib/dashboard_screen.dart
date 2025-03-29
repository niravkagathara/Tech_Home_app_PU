import 'package:tech_home/ProfilePage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'mqtt_provider.dart';
import 'developer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'LoginPage.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUser'); // Remove the current user data
    await prefs.setBool('isLoggedIn', false); // Update the login status

    // Navigate to the login page and clear the navigation stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mqttProvider = Provider.of<MQTTProvider>(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,

        backgroundColor: Colors.blue.shade800, // Dark blue app bar
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [
            Icon(

              mqttProvider.isConnected ? Icons.cloud_done : Icons.cloud_off,
              color: mqttProvider.isConnected ? Colors.green : Colors.red,
            ),

            Image.asset(
              alignment: Alignment.bottomRight,

              'images/logo3a.png', // Replace with your logo path
              height: 100,
              // width: 50,
              // const SizedBox(width: 1), // Space between logo and title text
              // Text(
              //   'Tech Home Dashboard',
              //   style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              // ),
            ),
          ],
        ),
        actions: [

          const SizedBox(width: 8),
          // Reconnect button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              mqttProvider.reconnect();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Attempting to reconnect to MQTT...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Reconnect',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'developer') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DeveloperDetail()),
                );
              } else if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'developer',
                  child: ListTile(
                    leading: Icon(
                      Icons.developer_mode_sharp,
                      color: Colors.black,
                    ),
                    title: Text('Developer'),
                  ),
                ),
                // const PopupMenuItem<String>(
                //   value: 'profile',
                //   child: ListTile(
                //     leading: Icon(Icons.person, color: Colors.black),
                //     title: Text('Profile'),
                //   ),
                // ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.black),
                    title: Text('Logout'),
                  ),
                ),
              ];
            },
          ),
        ],
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.lightBlue.shade100,
              Colors.lightBlue.shade50,
            ], // Light blue gradient
          ),
        ),
        child: Consumer<MQTTProvider>(
          builder: (context, mqttProvider, child) {
            final messages = mqttProvider.messages;
            return RefreshIndicator(
              onRefresh: () async {
                // Trigger a UI refresh (without reconnecting to MQTT)
                mqttProvider.refreshDashboard();
                await Future.delayed(Duration(milliseconds: 500)); // Simulate delay
              },
              color: Colors.blue.shade800, // Customize the loader color
              backgroundColor: Colors.white, //
              child: Stack(
                children: [
                  SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(), // Required for RefreshIndicator

                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildmsgbox(
                            'Message',
                            mqttProvider.isConnected
                                ? 'Connected to MQTT '
                                : 'Disconnected from MQTT ',
                            'Received',
                            messages['esp'] == null
                                ? 'Server/Device OFF'
                                : messages['esp'],
                          ),
                          _builddevices(
                            'Devices',
                            messages['data/value/device2'],
                            messages['data/value/device2'] == '1'
                                ? 'DEVICE2ON'
                                : 'DEVICE2OFF',
                            () {
                              mqttProvider.publish(
                                'data/onoff/device2',
                                messages['data/value/device2'] == '1'
                                    ? 'OFF'
                                    : 'ON',
                              );
                            },
                            messages['data/value/device1'],
                            messages['data/value/device1'] == '1'
                                ? 'DEVICE1ON'
                                : 'DEVICE1OFF',
                            () {
                              mqttProvider.publish(
                                'data/onoff/device1',
                                messages['data/value/device1'] == '1'
                                    ? 'OFF'
                                    : 'ON',
                              );
                            },
                            () {
                              // Toggling both devices ON/OFF based on their current status
                              bool areBothOn =
                                  messages['data/value/device1'] == '1' &&
                                  messages['data/value/device2'] == '1';
                              String newState = areBothOn ? 'OFF' : 'ON';

                              mqttProvider.publish(
                                'data/onoff/device1',
                                newState,
                              );
                              mqttProvider.publish(
                                'data/onoff/device2',
                                newState,
                              );
                            },
                          ),

                          _buildSensorCard(
                            'Moisture Sensor',
                            messages['data/moisture/onoff'],
                            messages['data/moisture/value'] == null
                                ? 'Moisture Level: 0'
                                : "Moisture Level: ${messages['data/moisture/value']}",
                            messages['data/moisture'],
                            () {
                              mqttProvider.publish(
                                'data/moisture/control',
                                messages['data/moisture/onoff'] == '1'
                                    ? 'OFF'
                                    : 'ON',
                              );
                            },
                          ),
                          _buildSensorCard(
                            'Ultrasonic Sensor',
                            messages['data/ultrasonic/onoff'],
                            messages['data/ultrasonic/value'] == null
                                ? 'Distance: 0 cm'
                                : "Distance: ${messages['data/ultrasonic/value']} cm",
                            messages['data/ultrasonic'],
                            () {
                              mqttProvider.publish(
                                'data/ultrasonic/control',
                                messages['data/ultrasonic/onoff'] == '1'
                                    ? 'OFF'
                                    : 'ON',
                              );
                            },
                          ),
                          _buildSensorCard(
                            'Gas Sensor',
                            messages['data/gas/onoff'],
                            messages['data/gas/value'] == null
                                ? 'Gas Level: 0'
                                : "Gas Level: ${messages['data/gas/value']}",
                            messages['data/gas'],
                            () {
                              mqttProvider.publish(
                                'data/gas/control',
                                messages['data/gas/onoff'] == '1'
                                    ? 'OFF'
                                    : 'ON',
                              );
                            },
                          ),
                          _buildSensorCard(
                            'Motion Sensor',
                            messages['data/motion/onoff'],
                            messages['data/motion/value'] == null
                                ? 'Motion Status: 0'
                                : "Motion Status: ${messages['data/motion/value']}",
                            messages['data/motion'],
                            () {
                              mqttProvider.publish(
                                'data/motion/control',
                                messages['data/motion/onoff'] == '1'
                                    ? 'OFF'
                                    : 'ON',
                              );
                            },
                          ),
                          _buildSensorCard(
                            'LDR Sensor',
                            messages['data/ldr/onoff'],
                            messages['data/ldr/value'] == null
                                ? 'Light Intensity: 0'
                                : 'Light Intensity: ${messages['data/ldr/value']}',
                            messages['data/ldr'],
                            () {
                              mqttProvider.publish(
                                'data/ldr/control',
                                messages['data/ldr/onoff'] == '1'
                                    ? 'OFF'
                                    : 'ON',
                              );
                            },
                          ),
                          _buildSensorCard(
                            'Fire Sensor',
                            messages['data/fire/onoff'],
                            messages['data/fire/value'] == null
                                ? 'Fire Intensity: 0'
                                : 'Fire Intensity: ${messages['data/fire/value']}',
                            messages['data/fire'],
                            () {
                              mqttProvider.publish(
                                'data/fire/control',
                                messages['data/fire/onoff'] == '1'
                                    ? 'OFF'
                                    : 'ON',
                              );
                            },
                          ),
                          _card_temp(
                            'Temperature Sensor',
                            messages['data/temp/onoff'],
                            messages['data/temp'],
                            messages['data/hume'],
                            () {
                              mqttProvider.publish(
                                'data/temp/control',
                                messages['data/temp/onoff'] == '1'
                                    ? 'OFF'
                                    : 'ON',
                              );
                            },
                          ),
                          _buildfanled(
                            'Fan Control',
                            messages['data/fan/value'],
                            messages['data/fan/value'] == '1'
                                ? 'FANON'
                                : 'FANOFF',
                            () {
                              mqttProvider.publish(
                                'data/fan',
                                messages['data/fan/value'] == '1'
                                    ? 'OFF'
                                    : 'ON',
                              );
                            },
                          ),
                          _buildfanled(
                            'LED Control',
                            messages['data/led/value'],
                            messages['data/led/value'] == '1'
                                ? 'LEDON'
                                : 'LEDOFF',
                            () {
                              mqttProvider.publish(
                                'data/led',
                                messages['data/led/value'] == '1'
                                    ? 'OFF'
                                    : 'ON',
                              );
                            },
                          ),
                          SizedBox(height: 60),
                          // _buildSensorCard(
                          //   'Device 1',
                          //   messages['data/value/device1'],
                          //   messages['data/value/device1'] == null
                          //       ? '0'
                          //       : messages['data/value/device1'],
                          //   messages['data/value/device1'] == '1' ? 'DEVICE1ON' : 'DEVICE1OFF',
                          //   () {
                          //     mqttProvider.publish(
                          //       'data/onoff/device1',
                          //       messages['data/led/value'] == '1' ? 'OFF' : 'ON',
                          //     );
                          //   },
                          // ),
                          // _buildSensorCard(
                          //   'Device 2',
                          //   messages['data/value/device2'],
                          //   messages['data/value/device2'] == null
                          //       ? '0'
                          //       : messages['data/value/device2'],
                          //   messages['data/value/device2'] == '1' ? 'DEVICE2ON' : 'DEVICE2OFF',
                          //   () {
                          //     mqttProvider.publish(
                          //       'data/onoff/device2',
                          //       messages['data/led/value'] == '1' ? 'OFF' : 'ON',
                          //     );
                          //   },
                          // ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        border: Border(
                          top: BorderSide(
                            color: Colors.black26, // Border color
                            width: 2.0, // Border thickness
                          ),
                        ),
                      ),
                      padding: EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Image.asset(
                                'images/logoduabc.png', // Your logo path
                                height: 60,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Image.asset(
                                'images/aswdc.png', // Your logo path
                                height: 60,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildmsgbox(String title, String? msg, String title2, String? msg2) {
    return Container(
      width: double.infinity, // Full width of the parent
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade800, // Light blue card background
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100, // Light blue shadow
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
        children: [
          Text(
            '${title}: ${msg}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade50,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${title2}: ${msg2}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade50,
            ),
          ),
        ],
      ),
    );
  }

  Widget boxtext(var msg) {
    return Text(
      msg,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Colors.blue.shade50,
      ),
    );
  }

  Widget _buildSensorCard(
    String title,
    String? onoff,
    String? value,
    String? status,
    VoidCallback onToggle,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade800, // Light blue card background
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100, // Light blue shadow
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade50,
                  ),
                ),
              ),
              Switch(
                value: onoff == '1',
                onChanged: (value) => onToggle(),
                activeColor: Colors.blue.shade50, // Dark blue switch
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12.0),
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade100, // Light blue container
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Customvalue(value)),
          ),
          SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(top: 8.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade100, // Light blue container
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: CustomText(status)),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
  Widget Customtexttemphume(var status) {
    if (status == '')
      return Text(
        'Sensor Off',
        textAlign: TextAlign.left,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == "215")
      return Text(
        'Humidity: 🚫Humidity Sensor Off',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status=="222")
      return Text(
        'Humidity: ❌Failed to read from DHT sensor!',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else
      return Text(
        'Humidity: 💧 ${status} %',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
  }
  Widget Customvalue(var value) {
    if (value == '')
      return Text(
        'Value: 0',
        textAlign: TextAlign.left,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else
      return Text(
        '$value',
        textAlign: TextAlign.left,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
  }
  Widget Customtexttemp(var status) {
    if (status == '')
      return Text(
        'Sensor Off',
        textAlign: TextAlign.left,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status== '223')
      return Text(
        'Temperature: ❌Failed to read from DHT sensor!',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status=='214')
      return Text(
        'Temperature: 🚫Temperature Sensor Off',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status=="222")
      return Text(
        'Temperature:❌Failed to read from DHT sensor!',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status=="215")
      return Text(
        'Temperature:🚫Humidity Sensor Off',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else
      return Text(
        'Temperature: 🌡 ${status} °C',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
  }
  Widget CustomText(var status) {
    if (status == '')
      return Text(
        'Sensor Off',
        textAlign: TextAlign.left,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == '201')
      return Text(
        '🚫Moisture Sensor Off',
        textAlign: TextAlign.left,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == '202')
      return Text(
        '⚠️High Moisture🌱',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == '203')
      return Text(
        '🫗Low Moisture🌱',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == '204')
      return Text(
        'Normal Moisture🌱',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == '205')
      return Text(
        '🚫Motion Sensor Off',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == '206')
      return Text(
        'LED ON (Motion Detected)',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == '207')
      return Text(
        'LED OFF (10 seconds elapsed)',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == '208')
      return Text(
        '🚫Parking Sensor Off',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == '209')
      return Text(
        '🛑Stop There!!🛑',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == '210')
      return Text(
        'Be Careful',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == '211')
      return Text(
        '🚫Gas Sensor Off',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == '212')
      return Text(
        '🌫Clean Air',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == '213')
      return Text(
        '☢️Gas Detected',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == '216')
      return Text(
        '🚫LDR is OFF',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == '217')
      return Text(
        '🌙Night detected: LED ON',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == '218')
      return Text(
        '🌞Day detected: LED OFF',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == '219')
      return Text(
        '🚫Fire Sensor Off',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == '220')
      return Text(
        '🔥Fire Alert!🔥',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == '221')
      return Text(
        'No Fire Detected',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == '223')
      return Text(
        'Temp:❌Failed to read from DHT sensor!',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == '214')
      return Text(
        'Temp: 🚫Temperature Sensor Off',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == '222')
      return Text(
        'Huminity: ❌Failed to read from DHT sensor!',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == '215')
      return Text(
        'Huminity: 🚫Humidity Sensor Off',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == 'LEDON')
      return Text(
        'LED Status: ON',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == 'LEDOFF')
      return Text(
        'LED Status: OFF',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == 'FANON')
      return Text(
        'Fan Status: ON',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == 'FANOFF')
      return Text(
        'Fan Status: OFF',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == 'DEVICE1ON')
      return Text(
        'Device 1 : ON',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == 'DEVICE2ON')
      return Text(
        'Device 2 : ON',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == 'DEVICE1OFF')
      return Text(
        'Device 1 : OFF',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == 'DEVICE2OFF')
      return Text(
        'Device 2 : OFF',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    else if (status == 'All') {
      return Text(
        ' All Device',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    } else
      return Text(
        'Server/Device OFF',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
  }

  Widget _card_temp(
    String title,
    String? onoff,
    String? statusa,
    String? status,
    VoidCallback onToggle,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade800, // Light blue card background
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100, // Light blue shadow
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade50,
                ),
              ),
              Switch(
                value: onoff == '1',
                onChanged: (value) => onToggle(),
                activeColor: Colors.blue.shade50, // Dark blue switch
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 8.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade100, // Light blue container
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: statusa == null
                  ? Text(
                'Server/Device OFF',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              )
                  : Customtexttemp(statusa),
            ),
          ),
          SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(top: 8.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade100, // Light blue container
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: status == null
                  ? Text(
                'Server/Device OFF',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              )
                  : Customtexttemphume(status),
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _builddevices(
    String title,
    String? onoff,
    String? status,
    VoidCallback onToggle,
    String? onoff1,
    String? status1,
    VoidCallback onToggle1,
    VoidCallback onToggleAll,
  ) {
    bool areBothOn = onoff == '1' && onoff1 == '1';
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade800,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade50,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 8.0, right: 4),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: CustomText(status1)),
                ),
              ),
              Switch(
                value: onoff1 == '1',
                onChanged: (value) => onToggle1(),
                activeColor: Colors.blue.shade50,
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 8.0, right: 4),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: CustomText(status)),
                ),
              ),
              Switch(
                value: onoff == '1',
                onChanged: (value) => onToggle(),
                activeColor: Colors.blue.shade50,
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 8.0, right: 4),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: CustomText("All")),
                ),
              ),
              Switch(
                value: areBothOn,
                onChanged: (value) => onToggleAll(),
                activeColor: Colors.blue.shade50,
              ),
            ],
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildfanled(
    String title,
    String? onoff,
    // String? value,
    String? status,
    VoidCallback onToggle,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade800, // Light blue card background
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100, // Light blue shadow
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade50,
                ),
              ),
              Switch(
                value: onoff == '1',

                onChanged: (value) => onToggle(),
                activeColor: Colors.blue.shade50, // Dark blue switch
              ),
            ],
          ),
          // Container(
          //   padding: const EdgeInsets.all(12.0),
          //   margin: EdgeInsets.only(bottom: 12),
          //   decoration: BoxDecoration(
          //     color: Colors.blue.shade100, // Light blue container
          //     borderRadius: BorderRadius.circular(10),
          //   ),
          //   child: Center(child: Customvalue(value)),
          // ),
          // SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(top: 8.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade100, // Light blue container
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: CustomText(status)),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}
