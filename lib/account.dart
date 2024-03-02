// ignore_for_file: prefer_const_constructors, unused_field, use_build_context_synchronously, must_be_immutable, use_function_type_syntax_for_parameters, non_constant_identifier_names, prefer_typing_uninitialized_variables, unused_local_variable, avoid_print

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile')
      ),
      body: Column(
      children: [
        ListTile(
          // contentPadding: EdgeInsets.fromLTRB(15, 15, 15, 5),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(48.0),
            child: 
             Image.network(userData!['avatar_url']
            )
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(userData!['name'], style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              Text(userData!['provider_id'], style: TextStyle(fontSize: 12))
            ],
          ),
          trailing: ElevatedButton(onPressed: () async => _handleLogOut(), child: Text("Log Out")),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if(!kIsWeb) ElevatedButton(
              onPressed: () => context.go('/update'),
              child: Text('Check for updates'))
          ],
        ),
        // Expanded(child: UserPageRoute(uuid: Uuid(userData!['provider_id']), isSelf: true))
      ],
            )
    );
  }
}