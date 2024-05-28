// ignore_for_file: prefer_const_constructors, unused_field, use_build_context_synchronously, must_be_immutable, use_function_type_syntax_for_parameters, non_constant_identifier_names, prefer_typing_uninitialized_variables, unused_local_variable, avoid_print, unused_import

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journee/search.dart';
import 'package:journee/user_posts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _loading = true;
  final supabase = Supabase.instance.client;
  late final Future<List<Map<String, dynamic>>> _data;
  late final User? user = supabase.auth.currentUser;
  late final userData = user?.userMetadata!;

  Future<void> _handleLogOut() async {
    await supabase.auth.signOut();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully logged out!'),
        elevation: 20.0,
      ),
    );
    context.go('/login');
  }

  void handleClick(int item) {
    switch (item) {
      case 0:
        break;
      case 1:
        break;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // title: Text('Profile'),
        actions: [
          PopupMenuButton<int>(
            onSelected: (item) => handleClick(item),
            itemBuilder: (context) => [
              PopupMenuItem<int>(onTap: () async => _handleLogOut(), value: 0, child: Text("Sign out")),
              PopupMenuItem<int>(onTap: () async => context.push('/update'), value: 1, child: Text("Check for updates")),
            ],
          )
        ],
      ),
      body: UserPageRoute(uuid: userData!['provider_id'])
    );
  }
}