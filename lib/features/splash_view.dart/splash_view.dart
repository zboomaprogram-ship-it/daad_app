import 'dart:async';
 import 'package:daad_app/app.dart';
import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/route_utils/route_utils.dart' ;
import 'package:flutter/material.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  _SplashViewState createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();

    Timer(Duration(seconds: 2), () {
      RouteUtils.pushReplacement(const DaadApp());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          height: 150,
          width: 150,
          child: Column(children: [Image.asset(kLogoImage)]),
        ),
      ),
    );
  }
}
