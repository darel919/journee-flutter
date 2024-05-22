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
      body: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(48.0),
                  child: 
                    Image.network(userData!['avatar_url']
                  )
                ),
              ),
              ListTile(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userData!['name'], style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(userData!['provider_id'], style: TextStyle(fontSize: 12))
                  ],
                ),
                trailing: userPostSearchMode(userData!['provider_id'], userData!['name']),
              ),
            ],
          ),
          Expanded(child: UserPageRoute(uuid: userData!['provider_id'], isself: 'true'))
          ],
        )
    );
  }
}