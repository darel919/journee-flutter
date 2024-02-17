// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, avoid_print, unused_local_variable, unnecessary_const, no_leading_underscores_for_local_identifiers, unused_element, unnecessary_new, unused_field

import 'package:flutter/material.dart';
import 'package:journee/account.dart';
import 'package:journee/home.dart';
import 'package:journee/login.dart';
import 'package:journee/splash.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:upgrader/upgrader.dart';

Future<void> main() async {
  await dotenv.load(fileName: 'lib/.env');
  WidgetsFlutterBinding.ensureInitialized();
  var sbaseUrl = dotenv.env['supabaseUrl']!;
  var sbaseAnonKey = dotenv.env['supabaseAnonKey']!;

  await Supabase.initialize(
    url: sbaseUrl,
    anonKey: sbaseAnonKey,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  MyApp({super.key});

  static const appcastURL = 'https://raw.githubusercontent.com/darel919/journee-flutter/main/android/app/appcast/appcast.xml';
  final upgrader = Upgrader(
      appcastConfig:
          AppcastConfiguration(url: appcastURL, supportedOS: ['android'])
  );

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Journee',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 0, 4, 255)),
        useMaterial3: true,
      ),
      // initialRoute: '/',
      home: UpgradeAlert(upgrader: upgrader, showIgnore: false, showLater: false, child: SplashPage()),
      routes: <String, WidgetBuilder> {
        // '/' : (BuildContext context) => SplashPage(),
        '/home':(BuildContext context) => MyHomePage(title: 'Home'),
        '/account':(BuildContext context) => AccountPage(),
        '/login': (BuildContext context) => const LoginPage(),
      },
    );
  }
}

