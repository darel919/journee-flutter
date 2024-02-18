// ignore_for_file: prefer_const_constructors, unused_field, avoid_print, unused_local_variable

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdatePage extends StatefulWidget {
  const UpdatePage({super.key});

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}


class _UpdatePageState extends State<UpdatePage> {
  static const appcastURL = 'https://raw.githubusercontent.com/darel919/journee-flutter/main/android/app/appcast/appcast.xml';
  static const _urlAndroid = 'https://github.com/darel919/journee-flutter/releases/download/app/app-release.apk';
  static const _url = 'https://github.com/darel919/journee-flutter/releases/';

  final upgrader = Upgrader(
    durationUntilAlertAgain: Duration(days: 1),
    debugDisplayAlways: false,
    debugLogging: true,
      appcastConfig:
          AppcastConfiguration(url: appcastURL, supportedOS: ['android'])
  );

   bool launchUpdateURL() {
    print('update launch url');
    if(Platform.isAndroid) {
      launchUrl(Uri.parse(_urlAndroid));
        Navigator.of(context).pushReplacementNamed('/');
    } if(Platform.isWindows) {
      launchUrl(Uri.parse(_url));
    }
    return true;
  }

  bool updateLater() {
    print('run later');
    goHome();
    return false;
  }

  Future<void> goHome() async {
    await Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (_) => false
      );
  }

  String? version;

  Future<void> getVersion() async {
    print('run');
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    version = packageInfo.version;
  }

  @override 
  void initState() {
    getVersion();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Journee Updater')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              UpgradeCard(
                upgrader: upgrader,
                showIgnore: false,
                showLater: true,
                onUpdate: () => launchUpdateURL(), 
                onLater: () => updateLater(),
              ),
            ],
          ),
        )
    );
  }
}