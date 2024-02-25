// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, avoid_print, unused_local_variable, unnecessary_const, no_leading_underscores_for_local_identifiers, unused_element, unnecessary_new, unused_field, unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:journee/account.dart';
import 'package:journee/home.dart';
import 'package:journee/login.dart';
import 'package:journee/splash.dart';
import 'package:journee/updater.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  await dotenv.load(fileName: 'lib/.env');
  WidgetsFlutterBinding.ensureInitialized();
  var sbaseUrl = dotenv.env['supabaseUrl']!;
  var sbaseAnonKey = dotenv.env['supabaseAnonKey']!;
  await Supabase.initialize(
    url: sbaseUrl,
    anonKey: sbaseAnonKey,
    debug: false
  );
  // GoogleFonts.config.allowRuntimeFetching = false;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _theme(brightness1) {
    var baseTheme = ThemeData(brightness: brightness1);
    
    return ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0x00001238), 
          brightness: brightness1
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.ralewayTextTheme(baseTheme.textTheme)
      );
  }
  
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async{
        await Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (_) => false
        );
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Journee',
        theme: _theme(Brightness.light),
        themeMode: ThemeMode.system, 
        darkTheme: _theme(Brightness.dark),
        home: SplashPage(),
        routes: <String, WidgetBuilder> {
          '/home':(BuildContext context) => MyHomePage(title: 'Home'),
          '/account':(BuildContext context) => AccountPage(),
          '/login': (BuildContext context) => const LoginPage(),
          '/update': (BuildContext context) => UpdatePage(),
        },
      ),
    );
  }
}

