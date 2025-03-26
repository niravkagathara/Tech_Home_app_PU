import 'package:tech_home/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
// dashboard_screen.dart;

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _addDemoUsers();
    _checkLoginStatus();
  }

  Future<void> _addDemoUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersData = prefs.getString('users') ?? '[]';
    final List<dynamic> users = json.decode(usersData);

    final List<Map<String, dynamic>> demoUsers = [
      {'username': 'iot', 'password': 'iot@2025', 'name': 'Iotdemo', 'email': 'iotdemo@example.com'},
      {'username': 'nirav', 'password': 'nirav1', 'name': 'nirav', 'email': 'nirav@example.com'},
      {'username': 'user', 'password': 'pass', 'name': 'User Three', 'email': 'user3@example.com'},
      {'username': 'demo', 'password': 'demo1', 'name': 'User fourth', 'email': 'user3@example.com'},
      {'username': 'iot', 'password': 'iot', 'name': 'iot', 'email': 'iot@example.com'},
    ];

    bool alreadyAdded = users.any((user) => demoUsers.any((demoUser) => user['username'] == demoUser['username']));

    if (!alreadyAdded) {
      users.addAll(demoUsers);
      await prefs.setString('users', json.encode(users));
    }
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool? isLoggedIn = prefs.getBool('isLoggedIn');

    if (isLoggedIn == true) {
      final currentUserData = prefs.getString('currentUser');
      if (currentUserData != null) {
        final currentUser = json.decode(currentUserData);
        final lastLogin = DateTime.parse(currentUser['loginTime']);
        final difference = DateTime.now().difference(lastLogin).inDays;

        if (difference < 30) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen()),
          );
          return;
        } else {
          await prefs.remove('currentUser');
          await prefs.setBool('isLoggedIn', false);
        }
      }
    }
  }

  Future<void> _login() async {
    final prefs = await SharedPreferences.getInstance();
    final usersData = prefs.getString('users') ?? '[]';
    final List<dynamic> users = json.decode(usersData);

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    final existingUser = users.firstWhere(
          (user) =>
      user['username'] == username &&
          user['password'] == password,
      orElse: () => null,
    );

    if (existingUser != null) {
      existingUser['loginTime'] = DateTime.now().toIso8601String();

      await prefs.setString('currentUser', json.encode(existingUser));
      await prefs.setString('users', json.encode(users));
      await prefs.setBool('isLoggedIn', true);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid username or password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue.shade800,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'images/logo3a.png',
                    height: 120,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                      backgroundColor: Colors.blue.shade800,
                    ),
                    child: const Text('Login',style: TextStyle(color: Colors.white),),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
