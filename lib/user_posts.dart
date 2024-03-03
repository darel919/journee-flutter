// ignore_for_file: prefer_const_constructors, unnecessary_new, no_logic_in_create_state

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class Uuid {
  final String uuid;
  Uuid(this.uuid);
}

class UserPageRoute extends StatefulWidget {
  final Uuid uuid;
  final bool isSelf;

  const UserPageRoute({super.key, required this.uuid, required this.isSelf});

  @override
  State<UserPageRoute> createState() => _UserPageRouteState(uuid: uuid, isSelf: isSelf);
}

class _UserPageRouteState extends State<UserPageRoute> {
  final Uuid uuid;
  final bool isSelf;
  final supabase = Supabase.instance.client;

  _UserPageRouteState({Key? key, required this.uuid, required this.isSelf});

   late final _future = supabase
      .from('posts')
      .select('''*, users(*), threads ( * ), categories ( * )''')
      .eq('uuid', uuid.uuid)
      .order('created_at',  ascending: false);

  String? username;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isSelf ? AppBar(
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
      ) : AppBar(
        title: Text("Post by user"),
        automaticallyImplyLeading: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if(!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
            final posts = snapshot.data!;
            if(snapshot.hasData) {
              // username = posts[0]['users']['name'];
            }
            
            return ListView.builder(
            itemCount: posts.length,
            itemBuilder: ((context, index) {
              final post = posts[index];
              final user = post['users'];
              final puid = post['puid'];
              // username = user['name'];
              DateTime myDateTime = DateTime.parse(post['created_at']);
              return ListTile(
                onTap: () {
                    context.go('/post/$puid');
                },
                contentPadding: EdgeInsets.fromLTRB(15, 5, 15, 5),
                isThreeLine: true,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(48.0),
                  child: Image.network(user['avatar_url']
                  )
                ),
                title: Text(user['name'], style: TextStyle(fontSize: 16)),
                trailing: Text(timeago.format(myDateTime, locale: 'en_short')),
                subtitle: Text(post['details'], maxLines: 1, style: TextStyle(fontSize: 12.5)),
              );
            }),
            );
        },
      )
    );
  }
}