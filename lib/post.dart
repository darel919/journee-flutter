// ignore_for_file: prefer_const_constructors, unused_local_variable, unnecessary_new

import 'package:flutter/material.dart';
import 'package:journee/home.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class Puid {
  final String puid;

  Puid(this.puid);
}

class ViewPostRoute extends StatelessWidget {
  final Puid puid;
  late final Future<List<Map<String, dynamic>>> _future;

  ViewPostRoute({Key? key, required this.puid}) : super(key: key) {
    _initializeFuture();
    
  }
   void _initializeFuture() {
    _future = Supabase.instance.client
      .from('posts')
      .select('''*, users(*), threads ( * ), categories ( * )''')
      .eq('puid', puid.puid)
      .order('created_at',  ascending: false);
   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Post"),
      ),
      body: RefreshIndicator(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if(!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
        
            final post = snapshot.data![0];
            final user = post['users'];
            final threads = post['threads'];
            DateTime myDateTime = DateTime.parse(post['created_at']);
            
            return ListView(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              children: <Widget>[
                ListTile(
                  onTap:() {
                    Navigator.push(context, new MaterialPageRoute(builder: (context) => new UserPageRoute(uuid: new Uuid(post['uuid']))));
                  },
                  contentPadding: EdgeInsets.fromLTRB(15, 15, 15, 5),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(48.0),
                    child: Image.network(user['avatar_url']
                    )
                  ),
                  title: Text(user['name']),
                  trailing: Text(timeago.format(myDateTime, locale: 'en'))
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                        child: Text(post['details']),
                      ),
                      if (post['mediaUrl']!= null && post['mediaUrl'].isNotEmpty) Padding(
                        padding: const EdgeInsets.fromLTRB(0,0,0,20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(post['mediaUrl'], width: 400),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        onRefresh: () {
          return Future.delayed(
            Duration(seconds: 1),
            () => _future,
          );
        },
      )
    );
  }
}