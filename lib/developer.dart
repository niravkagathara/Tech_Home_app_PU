import 'package:aswdc_flutter_pub/aswdc_flutter_pub.dart';
import 'package:flutter/material.dart';

class DeveloperDetail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Scaffold(
        body:
        DeveloperScreen(
          developerName: 'Nirav Kagathara(22010101143)',
          mentorName: 'Prof. Bhushan Joshi',
          exploredByName: 'ASWDC',
          isAdmissionApp: true,
          isDBUpdate: true,
          shareMessage: '',
          appTitle: 'Tech Home',
          appLogo: 'images/logo1a.png',
        ),

      //    SplashScreen(
      //   appLogo: 'images/logo1.png',
      //   appName: 'Tech Home',
      //   appVersion: '1.9',
      // ),
        // DeveloperScreen(
        //             developerName: 'Mehul Bhundiya',
        //             mentorName: 'Prof. Mehul Bhundiya',
        //             exploredByName: 'ASWDC',
        //             isAdmissionApp: false,
        //             shareMessage: '',
        //             appTitle: 'Example',
        //             appLogo: 'images/logo1.png',
        //           )

      ),
    );
  }
}