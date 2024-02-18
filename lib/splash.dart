// ignore_for_file: prefer_const_constructors, unused_local_variable, use_build_context_synchronously, avoid_print

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
          print('user update ok!');
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
      body: Center(child: CircularProgressIndicator()),
    );
  }
}