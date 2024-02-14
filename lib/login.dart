// ignore_for_file: avoid_print, unused_local_variable, prefer_const_constructors, unused_element, prefer_typing_uninitialized_variables

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class LoginPage extends StatefulWidget {
  
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final supabase = Supabase.instance.client;
  late final StreamSubscription<AuthState> _authStateSubscription;
  bool _redirecting = false;
  bool _isLoading = false;
  
  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await dotenv.load(fileName: 'lib/.env');

      var clientId =  dotenv.env['androidClientId']!;
      var webClientId =  dotenv.env['webClientId']!;
      var desktopClientId =  dotenv.env['windowsClientId']!;
      var desktopClientSecret =  dotenv.env['windowsSecretId']!;
      
      String? accessToken;
      String? idToken;
      
      if (isDesktop) {  
        final GoogleSignIn googleSignInDesktop = GoogleSignIn(
          params: GoogleSignInParams(
            clientId: desktopClientId,
            clientSecret: desktopClientSecret,
          )
        );
        final googleUser = await googleSignInDesktop.signInOnline();
        if(googleUser != null) {
          accessToken = googleUser.accessToken;
          idToken = googleUser.idToken;
          print("Desktop mode GSI login");
        }
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          params: GoogleSignInParams(
            clientId: webClientId,
          )
        );
        final googleUser = await googleSignIn.signInOnline();
        if(googleUser != null) {
          accessToken = googleUser.accessToken;
          idToken = googleUser.idToken;
          print("Non-Desktop mode GSI login");
        }
      }

      if (accessToken!.isNotEmpty&& idToken!.isNotEmpty) {
        await supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
          nonce: 'NONCE',
        );
      }
    } catch (e) {
      print('Error during GSI Login: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
   }
  }

  @override
  void initState() {
    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) {
      if (_redirecting) return;
      final session = data.session;

      if (session != null) {
        _redirecting = true;
        Navigator.of(context).pushReplacementNamed('/');
      } else {
        _handleGoogleSignIn();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login to Journee'),
      ),
      body: _isLoading ? Center(child: CircularProgressIndicator()) : Center(child: ElevatedButton(onPressed: _handleGoogleSignIn, child: Text("Login with Google"))),
    );
  }
}