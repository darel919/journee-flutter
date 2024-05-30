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
                  style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.red)),
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

Widget PostThreadViewerComponent(puid, thinMode) {
  final supabase = Supabase.instance.client;

    late final futureThread = supabase
    .from('threads')
    .select('''*, users(*), threads ( * )''')
    .eq('puid', puid)
    .order('created_at',  ascending: true);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: futureThread, 
      builder: (context, snapshot) {
        if(!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
    
        final threadContent = snapshot.data!;

        if(threadContent.isNotEmpty) {
          return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: threadContent.length,
          itemBuilder: ((context, index) {
            final threadDetails = threadContent[index];
            final threadAuthor = threadDetails['users'];
            final tuid = threadDetails['tuid'];
            DateTime threadDateTime = DateTime.parse(threadDetails['created_at']);
            
            if(thinMode) {
              return ListTile(
                onTap: () {
                  context.push('/thread/$tuid');
                },
                contentPadding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                dense: true,
                title: Row(
                  children: [
                    Text(threadAuthor['name'], style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8,0,4,0),
                      child: Text(threadDetails['details'], overflow: TextOverflow.ellipsis,),
                    ),
                  ],
                ),
                trailing: Text(timeago.format(threadDateTime, locale: 'en_short')),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text(threadDetails['details']),
                    if (threadDetails['mediaUrl']!= null && threadDetails['mediaUrl'].isNotEmpty) Padding(
                      padding: const EdgeInsets.fromLTRB(0,15,0,15),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(threadDetails['mediaUrl'], 
                        // width: 400,
                        fit: BoxFit.cover,
                        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) return child; // If the image is fully loaded, return the child widget
                            return Center( // Otherwise, return a loading widget
                              child: CircularProgressIndicator( // You can use any widget you like, such as a Shimmer widget
                                value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                )
              );
            } return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("Threads", style: TextStyle(fontWeight: FontWeight.bold),),
                ),
                Divider(),
                ListTile(
                  onTap: () {
                    context.push('/thread/$tuid');
                  },
                  contentPadding: EdgeInsets.fromLTRB(15, 5, 15, 5),
                  isThreeLine: true,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(48.0),
                    child: Image.network(threadAuthor['avatar_url'], width: 32, height: 32
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
                          child: Image.network(threadDetails['mediaUrl'], 
                          // width: 400,
                          fit: BoxFit.cover,
                          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) return child; // If the image is fully loaded, return the child widget
                              return Center( // Otherwise, return a loading widget
                                child: CircularProgressIndicator( // You can use any widget you like, such as a Shimmer widget
                                  value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  )
                ),
              ],
            );
          }),
        );
        } return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("Threads", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Divider(),
            ListTile(
              contentPadding: EdgeInsets.fromLTRB(15, 5, 15, 5),
              title: Text("No replies on this thread"),
            ),
          ],
        );
      }
    );
  }

Future<void> ViewPostThreadBottomSheet(puid, context) {
  bool uploading = false;
  return showModalBottomSheet<dynamic>(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    clipBehavior: Clip.antiAliasWithSaveLayer,
    // useRootNavigator: true,
    useSafeArea: true,
    enableDrag: !uploading,
    isDismissible: true,
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) {
      return PostThreadViewerComponent(puid, false);
    }
  );
}

