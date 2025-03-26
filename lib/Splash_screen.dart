import 'package:aswdc_flutter_pub/aswdc_flutter_pub.dart';
import 'package:tech_home/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'LoginPage.dart';

class Splash_Screen extends StatefulWidget {
  @override
  State<Splash_Screen> createState() => _Splash_ScreenState();
}

class _Splash_ScreenState extends State<Splash_Screen> {

  @override
  void initState(){
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool? isLoggedIn = prefs.getBool('isLoggedIn');
    final String? currentUserData = prefs.getString('currentUser');

    if (isLoggedIn == true && currentUserData != null) {
      final currentUser = json.decode(currentUserData);
      final lastLogin = DateTime.parse(currentUser['loginTime']);
      final difference = DateTime.now().difference(lastLogin).inDays;

      if (difference < 30) {
        // User is logged in and within the valid period (30 days)
        Timer(const Duration(seconds: 3), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen()),
          );
        });
        return;
      } else {
        // Session expired
        await prefs.remove('currentUser');
        await prefs.setBool('isLoggedIn', false);
      }
    }

    // Redirect to Login Page if not logged in or session expired
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SplashScreen(
          appLogo: 'images/logo3a.png',
          appName: 'Tech Home',
          appVersion: '1.0',
        ),
      ),
    );
  }
}
