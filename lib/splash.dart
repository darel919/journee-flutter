// ignore_for_file: prefer_const_constructors, unused_local_variable, use_build_context_synchronously, avoid_print, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
final supabase = Supabase.instance.client;

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(Duration.zero);
    if (!mounted) {
      return;
    }

    final session = supabase.auth.currentSession;
    final userMetadata = session?.user.userMetadata;
    if (session != null) {
        await supabase
          .from('users')
          .upsert({
            'uuid': userMetadata!['provider_id'],
            'name': userMetadata['name'],
            'email': userMetadata['email'], 
            'avatar_url': userMetadata['avatar_url'],
          });
      await Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (_) => false
      );
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                child: Text("Journee", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),),
              ),
              CircularProgressIndicator(),
            ],
        ),
      ));
  }
}