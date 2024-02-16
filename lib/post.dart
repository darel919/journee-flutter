// ignore_for_file: prefer_const_constructors, unused_local_variable, unnecessary_new, unused_element, prefer_const_literals_to_create_immutables, avoid_print, unused_import, use_build_context_synchronously, no_logic_in_create_state, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:journee/home.dart';
import 'package:journee/user_posts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class Puid {
  final String puid;
  Puid(this.puid);
}

class ViewPostRoute extends StatefulWidget {
  final Puid puid;
  const ViewPostRoute({super.key, required this.puid});

  @override
  State<ViewPostRoute> createState() => _ViewPostRouteState(puid: puid);
}

class _ViewPostRouteState extends State<ViewPostRoute> {
  final Puid puid;
  final supabase = Supabase.instance.client;

  _ViewPostRouteState({Key? key, required this.puid});

  late final _future = supabase
    .from('posts')
    .select('''*, users(*), threads ( * ), categories ( * )''')
    .eq('puid', puid.puid)
    .order('created_at',  ascending: false);

  late final _futureThread = supabase
    .from('threads')
    .select('''*, users(*), threads ( * )''')
    .eq('puid', puid.puid);

  void handleClick(int item) {
    switch (item) {
      case 0:
        break;
      case 1:
        break;
    }
  }
  
  Future<void> _deletePost() async {
    try {
      await supabase
      .from('posts')
      .delete()
      .match({'puid': puid.puid});
      await Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (_) => false
      );
    } catch (e) {
      print('$e');
    }
  }

  late final User? user = supabase.auth.currentUser;
  late final userData = user?.userMetadata!;
  String? postuuid;
  
  bool isAdmin(){
    if(postuuid == userData!['provider_id']) {
      return true;
    } else {
      false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Post"),
        actions: <Widget> [
          PopupMenuButton<int>(
              onSelected: (item) => handleClick(item),
              itemBuilder: (context) => [
                if(isAdmin()) PopupMenuItem<int>(onTap: () => _showMyDialog(context), value: 0, child: Text('Delete')),
                // PopupMenuItem<int>(value: 1, child: Text('Settings')),
              ],
            )
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if(!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
      
          final post = snapshot.data![0];
          final user = post['users'];

          final threads = post['threads'];
          postuuid = post['uuid'];
          DateTime myDateTime = DateTime.parse(post['created_at']);
          
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListView(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
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
                            title: Row(
                              children: [
                                Text(user['name']),
                              ],
                            ),
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
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (threads.length > 0) Text("Threads"),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _futureThread, 
                        builder: (context, snapshot) {
                          if(!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                      
                          final threadContent = snapshot.data!;

                          return ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: threads.length,
                            itemBuilder: ((context, index) {
                              final threadDetails = threadContent[index];
                              final threadAuthor = threadDetails['users'];
                              DateTime threadDateTime = DateTime.parse(threadDetails['created_at']);
                              
                              return ListTile(
                                onTap: () {
                                  Navigator.push(context, new MaterialPageRoute(builder: (context) => new UserPageRoute(uuid: new Uuid(threadAuthor['uuid']))));
                                },
                                contentPadding: EdgeInsets.fromLTRB(15, 5, 15, 5),
                                isThreeLine: true,
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(48.0),
                                  child: Image.network(threadAuthor['avatar_url']
                                  )
                                ),
                                title: Text(threadAuthor['name'], style: TextStyle(fontSize: 16)),
                                trailing: Text(timeago.format(threadDateTime, locale: 'en_short')),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(threadDetails['details']),
                                    if (threadDetails['mediaUrl']!= null && threadDetails['mediaUrl'].isNotEmpty) Padding(
                                      padding: const EdgeInsets.fromLTRB(0,15,0,15),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(threadDetails['mediaUrl'], width: 400),
                                      ),
                                    ),
                                  ],
                                )
                              );
                            }),
                          );
                        }
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      )
    );
  }

  Future<void> _showMyDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return Builder(
          builder: (BuildContext innerContext) {
            return AlertDialog(
              title: Text('Are you sure?'),
              content: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Text('You are about to delete this post'),
                    Text("This action can't be undone and deleted post can't be recovered later."),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.red)),
                  child: Text('Delete', style: TextStyle(color: Colors.white),),
                  onPressed: () {
                    print('Confirmed');
                    _deletePost();
                    Navigator.of(innerContext).pop();
                  },
                ),
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(innerContext).pop();
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }
}

