// ignore_for_file: prefer_const_constructors, unnecessary_new, no_logic_in_create_state, prefer_is_empty, prefer_typing_uninitialized_variables


import 'package:flutter/material.dart';
import 'package:journee/home.dart';
import 'package:journee/search.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class UserPageRoute extends StatefulWidget {
  final String? uuid;

  const UserPageRoute({super.key, required this.uuid});

  @override
  State<UserPageRoute> createState() => _UserPageRouteState(uuid: uuid);
}

class _UserPageRouteState extends State<UserPageRoute> {
  final String? uuid;
  final supabase = Supabase.instance.client;

  _UserPageRouteState({required this.uuid});

   late final _future = supabase
      .from('posts')
      .select('''*, users(*), threads ( * ), categories ( * )''')
      .eq('uuid', uuid!)
      .order('created_at',  ascending: false);

  late Map<String, dynamic> userData = {};
  bool isself() {
    if(uuid == userData['provider_id']) {
      return true;
    } return false;
  }

 @override
  Widget build(BuildContext context) {
    return userPostUI();
  }

Widget userPostUI() {
  return FutureBuilder<List<Map<String, dynamic>>>(
    future: _future,
    builder: (context, snapshot) {
      if(snapshot.connectionState == ConnectionState.done) {
        final posts = snapshot.data!;
        if(snapshot.data!.isNotEmpty) {
          userData = posts[0]['users'];
          return Scaffold(
            body: Padding(
              padding: isself() ? const EdgeInsets.all(0) : const EdgeInsets.fromLTRB(0,32,0,0),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(                         
                            padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                            child: ClipRRect(                         
                              borderRadius: BorderRadius.circular(48.0),
                              child: 
                                Image.network(userData['avatar_url']
                              )
                            ),
                          ),
                          ListTile(                      
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(userData['name'], style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                Text(userData['uuid'], style: TextStyle(fontSize: 12))
                              ],
                            ),
                            trailing: posts.length >0 ? userPostSearchMode(userData['uuid'], userData['name']) : Icon(Icons.disabled_by_default)
                          ),
                          NewPostView(posts, snapshot, false, false)
                        ],
                      ),
                    )
                  ),
                ],
              ),
            )
          );

        }
        return Center(child: Text('User has no post!'));
      }
      return Center(child: CircularProgressIndicator());
    },
    
  );
 }
}