// ignore_for_file: prefer_const_constructors, unused_local_variable, unnecessary_new, unused_element, prefer_const_literals_to_create_immutables, avoid_print, unused_import, use_build_context_synchronously, no_logic_in_create_state, unnecessary_null_comparison, prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journee/modify.dart';
import 'package:journee/home.dart';
import 'package:journee/user_posts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;


class ViewThreadsRoute extends StatefulWidget {
  final String? tuid;
  const ViewThreadsRoute({super.key, required this.tuid});

  @override
  State<ViewThreadsRoute> createState() => _ViewThreadRouteState(tuid: tuid);
}

class _ViewThreadRouteState extends State<ViewThreadsRoute> {
  final String? tuid;
  final supabase = Supabase.instance.client;

  _ViewThreadRouteState({Key? key, required this.tuid});

  late final _future = supabase
    .from('threads')
    .select('''*, posts(*), users(*) ''')
    .eq('tuid', tuid!)
    .order('created_at',  ascending: false);
    // _scrollDown();

  // late final _futureThread = supabase
  //   .from('threads')
  //   .select()
  //   .eq('replyingTo', tuid!);

  late final fetchedData;
  late final User? user = supabase.auth.currentUser;
  late final userData = user?.userMetadata!;
  String? threadstuid;
  String? postpuid;
  bool isAdmin() {
    if(threadstuid == userData!['provider_id']) {
      return true;
    } else {
      false;
    }
    return false;
  }
  final ScrollController _controller = ScrollController();
  
  void handleClick(int item) {
    switch (item) {
      case 0:
        break;
      case 1:
        break;
    }
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
                    Text('You are about to delete this thread'),
                    Text("This action can't be undone and deleted post can't be recovered later."),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.red)),
                  child: Text('Delete', style: TextStyle(color: Colors.white),),
                  onPressed: () async {
                    // context.pop();
                    _deleteThread();
                  },
                ),
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    // Navigator.of(innerContext).pop();
                    context.pop();
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }
  
  Future<void> _deleteThread() async {
    try {
      await supabase
      .from('threads')
      .delete()
      .match({'tuid': tuid!});

      if(fetchedData['mediaUrl'] != null) {
        final List<FileObject> objects = await supabase
          .storage
          .from('post_media')
          .remove([fetchedData['mediaUrlOnDb']]);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reply successfully deleted!'),
            elevation: 20.0,
          ),
        );
        // context.pop();
        context.pushReplacement('/');
      } else {
        // context.pop();
        context.pushReplacement('/');
      }
    } catch (e) {
      print('$e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reply delete failed! $e'),
          elevation: 20.0,
        )
      );
    }
  }

  @override 
  void initState() {
    super.initState();
  }

  void _scrollDown() {
    _controller.animateTo(
      _controller.position.maxScrollExtent,
      duration: Duration(seconds: 2),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Thread"),
        actions: <Widget> [
          PopupMenuButton<int>(
              onSelected: (item) => handleClick(item),
              itemBuilder: (context) => [
                if(isAdmin()) PopupMenuItem<int>(onTap: () => _showMyDialog(context), value: 0, child: Text('Delete')),
                // if(isAdmin()) PopupMenuItem<int>(value: 1, child: Text('Edit')),
                // PopupMenuItem<int>(value: 2, child: Text('Share')),
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
          final threads = snapshot.data!;
          final post = threads[0]['posts'];
          threadstuid = threads[0]['users']['uuid'];
          final postAuthor = threads[0]['users'];
          DateTime myDateTime = DateTime.parse(post['created_at']);
          
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _controller,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ListView(
                      //   physics: const NeverScrollableScrollPhysics(),
                      //   shrinkWrap: true,
                      //   children: <Widget>[
                      //     ListTile(
                      //       onTap:() {
                      //         Navigator.push(context, new MaterialPageRoute(builder: (context) => new UserPageRoute(uuid: new Uuid(post['uuid']), isSelf: false)));
                      //       },
                      //       contentPadding: EdgeInsets.fromLTRB(15, 15, 15, 5),
                      //       leading: ClipRRect(
                      //         borderRadius: BorderRadius.circular(48.0),
                      //         child: Image.network(postAuthor!['avatar_url']
                      //         )
                      //       ),
                      //       title: Row(
                      //         children: [
                      //           Text(postAuthor['name']),
                      //         ],
                      //       ),
                      //       trailing: Text(timeago.format(myDateTime, locale: 'en'))
                      //     ),
                      //     Padding(
                      //       padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                      //       child: Column(
                      //         crossAxisAlignment: CrossAxisAlignment.start,
                      //         children: [
                      //           Padding(
                      //             padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                      //             child: Text(post['details']),
                      //           ),
                      //           if (post['mediaUrl']!= null && post['mediaUrl'].isNotEmpty) Padding(
                      //             padding: const EdgeInsets.fromLTRB(0,0,0,20),
                      //             child: ClipRRect(
                      //               borderRadius: BorderRadius.circular(8),
                      //               child: Image.network(post['mediaUrl'], width: 400),
                      //             ),
                      //           ),
                      //           if(post['mediaUrl'] == null && post['mediaUrlOnDb'] != null) Row(
                      //             children: [
                      //               Icon(Icons.image_not_supported),
                      //               Text("This image can only be viewed on Journee Web.", style: TextStyle(fontWeight: FontWeight.bold),),
                      //             ],
                      //           )
                      //         ],
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      ListView.builder(

                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: threads.length,
                        itemBuilder: ((context, index) {
                          final thread = threads[index];
                          fetchedData = thread;
                          final user = thread['users'];
                          final userid = user['uuid'];
                          // final threadAuthor = threadDetails['users'];
                          DateTime threadDateTime = DateTime.parse(thread['created_at']);
                          
                          return ListTile(
                            onTap: () {
                              context.go('/user/$userid');
                              // Navigator.push(context, new MaterialPageRoute(builder: (context) => new UserPageRoute(uuid: new Uuid(threadAuthor['uuid']))));
                            },
                            contentPadding: EdgeInsets.fromLTRB(15, 5, 15, 5),
                            isThreeLine: true,
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(48.0),
                              child: Image.network(user['avatar_url']
                              )
                            ),
                            title: Text(user['name'], style: TextStyle(fontSize: 16)),
                            trailing: Text(timeago.format(threadDateTime, locale: 'en_short')),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(thread['details']),
                                if (thread['mediaUrl']!= null && thread['mediaUrl'].isNotEmpty) Padding(
                                  padding: const EdgeInsets.fromLTRB(0,15,0,15),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(thread['mediaUrl'], width: 400),
                                  ),
                                ),
                              ],
                            )
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            //  CreateThread(puid: postpuid),
            ],
          );
        },
      )
    );
  }
  }
