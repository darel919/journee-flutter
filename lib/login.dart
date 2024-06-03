// ignore_for_file: avoid_print, unused_local_variable, prefer_const_constructors, unused_element, prefer_typing_uninitialized_variables, use_build_context_synchronously, camel_case_types, no_leading_underscores_for_local_identifiers, unused_import

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

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
  String? accessToken;
  String? idToken;
  
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
      
      if(kIsWeb) {
        var link = await supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kReleaseMode ? 'https://newjournee.vercel.app/#/init' : 'http://localhost:3000/init'
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Web Login success!'),
            elevation: 20.0,
          ),
        );
      } else {
          if (Platform.isWindows) {  
            var client = http.Client();
            try {
                print("Desktop mode OAuth2 login");
                Future<void> _launchAuthInBrowser(String url) async {
                  final Uri parsedUrl = Uri.parse(url);
                  await canLaunchUrl(parsedUrl) ? await launchUrl(parsedUrl) : print('Could not launch $url');
                }
                var id = ClientId(
                  desktopClientId, // Your client ID for desktop
                  desktopClientSecret, // Your client secret for desktop
                );
                var scopes = ['email', 'profile', 'openid'];
                var credentials = await obtainAccessCredentialsViaUserConsent(
                    id, scopes, client, (url) => _launchAuthInBrowser(url));
                
                idToken = credentials.idToken;
                // print(idToken);
                  if (idToken!.isNotEmpty) {
                  await supabase.auth.signInWithIdToken(
                    provider: OAuthProvider.google,
                    idToken: idToken!,
                    nonce: 'NONCE',
                  );
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Login success!'),
                    elevation: 20.0,
                  ),
                );
              } catch(e) {
                print('$e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error logging in: $e'),
                    elevation: 20.0,
                  ),
                );
              } finally {
                client.close();
              }
          }
          else if(Platform.isAndroid) {
            GoogleSignIn _googleSignIn = GoogleSignIn(
              serverClientId: webClientId
            );
            final GoogleSignInAccount? googleSignInAccount = await _googleSignIn.signIn();

            if (googleSignInAccount != null) {
              final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;
              accessToken = googleSignInAuthentication.accessToken;
              idToken = googleSignInAuthentication.idToken;
              print('Android GSI Login');
              if (accessToken!.isNotEmpty && idToken!.isNotEmpty) {
                await supabase.auth.signInWithOAuth(
                  OAuthProvider.google, 
                  redirectTo: 'https://newjournee.vercel.app/#/init');

                // await supabase.auth.signInWithIdToken(
                //   provider: OAuthProvider.google,
                //   idToken: idToken!,
                //   accessToken: accessToken,
                //   nonce: 'NONCE',
                // );
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Login success!'),
                  elevation: 20.0,
                ),
              );
            }
          } 
        }
    } 
    catch (e) {
      displaySnackBar(e);
      print('Error during login: $e');
    } 
    finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void displaySnackBar(e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please restart application! Error while signing in: $e'),
        elevation: 20.0,
      ),
    );
  }

  void _restart() {
    context.pushReplacement('/');
  }

  @override
  void initState() {
    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) {
      if (_redirecting) return;
      final session = data.session;

      if (session != null) {
        _redirecting = true;
        context.pushReplacement('/init');
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
        automaticallyImplyLeading: false,
      ),
      body: _isLoading ? Center(child: CircularProgressIndicator()) : Center(child: ElevatedButton(onPressed: _restart, child: Text("Login with Google"))),
    );
  }
}