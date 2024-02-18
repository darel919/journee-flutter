// ignore_for_file: prefer_const_constructors, unnecessary_new

import 'package:flutter/material.dart';
import 'package:journee/post.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class Uuid {
  final String uuid;

  Uuid(this.uuid);
}

class UserPageRoute extends StatelessWidget {
  final Uuid uuid;
  late final Future<List<Map<String, dynamic>>> _future;

  UserPageRoute({Key? key, required this.uuid}) : super(key: key) {
    _initializeFuture();
  }

   void _initializeFuture() {
    _future = Supabase.instance.client
      .from('posts')
      .select('''*, users(*), threads ( * ), categories ( * )''')
      .eq('uuid', uuid.uuid)
      .order('created_at',  ascending: false);
   }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("User"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if(!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
            final posts = snapshot.data!;
            
            return ListView.builder(
            itemCount: posts.length,
            itemBuilder: ((context, index) {
              final post = posts[index];
              final user = post['users'];
              DateTime myDateTime = DateTime.parse(post['created_at']);
              return ListTile(
                onTap: () {
                    Navigator.push(context, new MaterialPageRoute(builder: (context) => new ViewPostRoute(puid: new Puid(post['puid']))));
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