// ignore_for_file: prefer_const_constructors, unused_field, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  var _loading = true;
  final supabase = Supabase.instance.client;
  late final Future<List<Map<String, dynamic>>> _data;

  Future<void> _getProfile() async {
    setState(() {
      _loading = true;
    });

    try {
      final userId = supabase.auth.currentUser!.id;
      _data = supabase
        .from('users')
        .select()
        .eq('uuid', userId)
        .single() as Future<List<Map<String, dynamic>>>;
    } catch (error) {
      SnackBar(
        content: const Text('Unexpected error occurred'),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _handleLogOut() async {
    await supabase.auth.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account')
      ),
      body: Center(child: ElevatedButton(onPressed: () async => _handleLogOut(), child: Text("Log Out")),)
    );
  }
}