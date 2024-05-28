// ignore_for_file: prefer_const_constructors, unnecessary_new, no_logic_in_create_state, prefer_is_empty, prefer_typing_uninitialized_variables


import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journee/search.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;


class UserPageRoute extends StatefulWidget {
  final String? uuid;

  const UserPageRoute({super.key, required this.uuid});

  @override
  State<UserPageRoute> createState() => _UserPageRouteState(uuid: uuid);
}

class _UserPageRouteState extends State<UserPageRoute> {
  final String? uuid;
  final supabase = Supabase.instance.client;

  _UserPageRouteState({Key? key, required this.uuid});

   late final _future = supabase
      .from('posts')
      .select('''*, users(*), threads ( * ), categories ( * )''')
      .eq('uuid', uuid!)
      .order('created_at',  ascending: false);

  String? userName = 'user';
  late Map<String, dynamic> userData = {};

  bool isself() {
    if(userData['provider_id'] == uuid!) {
      print("Viewing self");
      return true;
    } return false;
  }

 @override
  Widget build(BuildContext context) {
    if(isself()) {
      return Scaffold(
        body: userPostUI()
      );
    } return Scaffold(
        body: Padding(
          padding: const EdgeInsets.fromLTRB(0,32,0,0),
          child: userPostUI(),
        ),
    );
  }

 FutureBuilder<List<Map<String, dynamic>>> userPostUI() {
   return FutureBuilder<List<Map<String, dynamic>>>(
    future: _future,
    builder: (context, snapshot) {
      if(!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final posts = snapshot.data!;
      // userName = posts[0]['users']['name'];
      if(posts.length>0) {
        userData = posts[0]['users'];
        return Column(
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
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: posts.length,
                      itemBuilder: ((context, index) {
                        final post = posts[index];
                        final user = post['users'];
                        final puid = post['puid'];
                        final category = post['categories'];
                        final special = post['type'];
                        int threadLength = post['threads'].length;
                        int totalLength = posts.length;
                        DateTime myDateTime = DateTime.parse(post['created_at']);
                        if(totalLength > 0) {
                          return ListTile(
                          onTap: () {
                              context.push('/post/$puid');
                          },
                          contentPadding: EdgeInsets.fromLTRB(8, 5, 8, 5),
                          isThreeLine: true,
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(48.0),
                            child: Image.network(user['avatar_url'], width: 32, height: 32
                            )
                          ),
                          title: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0,0,8,0),
                                child: Text(user['name'], style: TextStyle(fontSize: 16)),
                              ),
                              Container(
                                padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
                                decoration: BoxDecoration(border: Border.all(color: MediaQuery.of(context).platformBrightness == Brightness.dark ? Colors.white : Colors.black),
                                borderRadius: BorderRadius.circular(4)),
                                child: Text(category['name'], style: TextStyle(fontSize: 9)),
                              ),
                              if(special == 'Special') Padding(
                                padding: const EdgeInsets.fromLTRB(5,0,0,0),
                                child: Icon(Icons.star_border_outlined),
                              )
                            ],
                          ),
                          // trailing: Text(timeago.format(myDateTime, locale: 'en_short')),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              
                              if(post['mediaUrl_preview'] != null) Padding(
                                padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(post['mediaUrl_preview'], width: 400)),
                              ),
                              Text(post['details'], maxLines: 2, style: TextStyle(fontSize: 17, height: 2), overflow: TextOverflow.ellipsis),
                              Text(timeago.format(myDateTime, locale: 'EN',), style: TextStyle(fontSize: 12, height: 1)),
                              // Divider(),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                                child: Row(
                                  children: [
                                    if(post['mediaUrl_preview'] == null && post['mediaUrl'] != null) Padding(
                                      padding: const EdgeInsets.fromLTRB(0, 5, 5, 0),
                                      child: Icon(Icons.image_outlined, size: 22),
                                    ),
                                    if(post['allowReply']) Padding(
                                      padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Icon(Icons.chat_bubble_outline, size: 20),
                                          if(threadLength > 0) Padding(
                                            padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                                            child: Text('$threadLength'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if(!post['allowReply']) Padding(
                                      padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          // Icon(Icons.comments_disabled_outlined, size: 20),
                                          if(threadLength > 0) Padding(
                                            padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                                            child: Text('$threadLength'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                        } else {
                          return Center(child: Text("No post found for this user."));
                        }
                      }),
                    ),
                  ],
                ),
              )
            ),
          ],
        );
      } else {
        return Center(child: Text("User has no post."));
      }
    },
  );
 }
}