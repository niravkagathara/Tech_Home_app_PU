import 'package:tech_home/Splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'mqtt_provider.dart';
import 'dashboard_screen.dart';
import 'package:aswdc_flutter_pub/aswdc_flutter_pub.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => MQTTProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Smart Home Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        // primarySwatch:
      ),
      debugShowCheckedModeBanner: false,
      home: Splash_Screen(),
    );
  }
}