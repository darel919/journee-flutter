// ignore_for_file: prefer_const_constructors, unused_local_variable, use_build_context_synchronously, avoid_print, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
    getVersion();
    _redirect();
  }

  bool nowLoading = false;

  Future<void> _redirect() async {
    await Future.delayed(Duration(milliseconds: 1500));
    setState(() {
      nowLoading = true;
    });
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
        setState(() {
        nowLoading = false;
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

  Future<void> getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = packageInfo.version;
    });
  }

  String? version;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if(nowLoading) Text("Welcome to"),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                    child: Text("Journee", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),),
                  ),
                  if(!nowLoading) Padding(
                    padding: const EdgeInsets.fromLTRB(5,0,0,0),
                    child: Text("v$version"),
                  ),
                ],
              ),
              if(nowLoading) CircularProgressIndicator(),
            ],
        ),
      ));
  }
}