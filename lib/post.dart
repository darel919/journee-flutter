// ignore_for_file: prefer_const_constructors, unused_local_variable, unnecessary_new, unused_element, prefer_const_literals_to_create_immutables, avoid_print, unused_import, use_build_context_synchronously, no_logic_in_create_state, unnecessary_null_comparison, prefer_typing_uninitialized_variables, prefer_interpolation_to_compose_strings

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journee/modify.dart';
import 'package:journee/home.dart';
import 'package:journee/threads.dart';
import 'package:journee/user_posts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';


class ViewPostRoute extends StatefulWidget {
  final String? puid;
  const ViewPostRoute({super.key, required this.puid});

  @override
  State<ViewPostRoute> createState() => _ViewPostRouteState(puid: puid);
}

class _ViewPostRouteState extends State<ViewPostRoute> {
  final String? puid;
  final supabase = Supabase.instance.client;

  _ViewPostRouteState({Key? key, required this.puid});

  late final _future = supabase
    .from('posts')
    .select('''*, users(*), threads ( * ), categories ( * ), locations (*)''')
    .eq('puid', puid!)
    .order('created_at',  ascending: false);

  late final _futureThread = supabase
    .from('threads')
    .select('''*, users(*), threads ( * )''')
    .eq('puid', puid!)
    .order('created_at',  ascending: true);

  void handleClick(int item) {
    switch (item) {
      case 0:
        break;
      case 1:
        break;
    }
  }
  late Map<String, dynamic> fetchedData = {};
  late Map<String, dynamic> reviewData = {};
 
  Future<void> _deletePost() async {
    try {
      await supabase
      .from('posts')
      .delete()
      .match({'puid': puid!});

      if(fetchedData['mediaUrl'] != null) {
        final List<FileObject> objects = await supabase
          .storage
          .from('post_media')
          .remove([fetchedData['mediaUrlOnDb']]);

        if(fetchedData['mediaUrl_preview'] != null) {
          final List<FileObject> objects = await supabase
          .storage
          .from('post_media')
          .remove([fetchedData['mediaUrl_previewOnDb']]);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post and media successfully deleted!'),
            elevation: 20.0,
          ),
        );
        context.pushReplacement('/');
      } else {
        context.pushReplacement('/');
      }
    } catch (e) {
      print('$e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post and media delete failed! $e'),
          elevation: 20.0,
        )
      );
    }
  }

  late final User? user = supabase.auth.currentUser;
  late final userData = user?.userMetadata!;
  String? postuuid;
  String? postpuid;
  String? postluid;
  String? postcatid;
  bool allowThread = true;
  bool isLocationAttached() {
    if(postluid == '' || postluid == null) {
      return false;
    } 
    return true;
  }
  bool isAdmin(){
    if(postuuid == userData!['provider_id']) {
      return true;
    } else {
      false;
    }
    return false;
  }
  bool isFoodReview() {
    if(postcatid == '368d3855-965d-4f13-b741-7975bbac80bf') {
      fetchRating();
      return true;
    } 
    return false;
  }
  void goLocation(Lat, Long) async {
    Uri uri = Uri.parse('geo:$Lat,$Long?q=$Lat,$Long');
    
    final fallbackUri = Uri(
      scheme: "https",
      host: "maps.google.com",
      queryParameters: {'q': '$Lat, $Long'},
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(fallbackUri);
      }
    } catch(e) {
        await launchUrl(fallbackUri);
        print("Can't launch maps. $e");
    }
  }
  
  Future<void> fetchRating() async {
    var res = await supabase
    .from('foodReviews')
    .select('*')
    .eq('ruid', fetchedData['ruid']!);
    reviewData = res[0];
    var darelRate = reviewData['darelRate'];
    var inesRate = reviewData['inesRate'];
    var ratingCalculation = darelRate + inesRate;
    print(ratingCalculation);
    var clampedRating = ratingCalculation.clamp(0.0, 5.0);
    // setState(() {
      calcRating.value = clampedRating.toString();
    // });
  }
  ValueNotifier<String?> calcRating = ValueNotifier<String?>('0');

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) {
        // context.pushReplacement('/');
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: Text("Post"),
          actions: <Widget> [
            PopupMenuButton<int>(
                onSelected: (item) => handleClick(item),
                itemBuilder: (context) => [
                  if(isAdmin()) PopupMenuItem<int>(onTap: () => _showMyDialog(context), value: 0, child: Text('Delete')),
                  if(isAdmin()) PopupMenuItem<int>(onTap: () => {
                     context.push('/post/$postpuid/edit')
                    // Navigator.push(context, new MaterialPageRoute(builder: (context) => new EditDiary(puid: postpuid)))
                    }, value: 1, child: Text('Edit')
                  ),
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
        
            final post = snapshot.data![0];
            fetchedData = post;
            print(post);
            final user = post['users'];
            final threads = post['threads'];
            postuuid = post['uuid'];
            postpuid = post['puid'];
            postluid = post['luid'];
            postcatid = post['cuid'];
            allowThread = post['allowReply'];
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
                              contentPadding: EdgeInsets.fromLTRB(15, 15, 15, 5),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(48.0),
                                child: Image.network(user!['avatar_url']
                                )
                              ),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      overlayColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      // tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      splashFactory: NoSplash.splashFactory,
                                      alignment: isLocationAttached() ? Alignment.bottomLeft : Alignment.centerLeft
                                    ),
                                    child: Text(user['name']), 
                                    onPressed: () {
                                      if(isAdmin()) {
                                        context.go('/account');
                                      } else {
                                        context.push('/user/$postuuid/false');
                                      }
                                    }
                                  ),
                                  if(isLocationAttached()) TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      overlayColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      splashFactory: NoSplash.splashFactory,
                                      alignment: Alignment.topLeft
                                    ),
                                    onPressed: () => goLocation(post['locations']['lat'], post['locations']['long']), 
                                    label: post['locations']['name'] != null ? Text(post['locations']['name'], overflow: TextOverflow.ellipsis) : Text('Location name unavailable', overflow: TextOverflow.ellipsis), 
                                    icon: Icon(Icons.location_pin),
                                  ),
                                  if(isFoodReview()) TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      overlayColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      splashFactory: NoSplash.splashFactory,
                                      alignment: Alignment.topLeft
                                    ),
                                    onPressed: () => context.push('/category/368d3855-965d-4f13-b741-7975bbac80bf'), 
                                    label: ValueListenableBuilder(valueListenable: calcRating, builder: (context, value, child) {
                                      if(calcRating.value! == '0') {
                                        Text('Loading...');
                                      } return Text(calcRating.value!);
                                    }),
                                    icon: Icon(Icons.star),
                                  )
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
                                    child: Text(post['details'], style: TextStyle(height: 2.2)),
                                  ),
                                  if (post['mediaUrl']!= null && post['mediaUrl'].isNotEmpty) Padding(
                                    padding: const EdgeInsets.fromLTRB(0,0,0,20),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(post['mediaUrl'], 
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
                                  if(post['mediaUrl'] == null && post['mediaUrlOnDb'] != null) Row(
                                    children: [
                                      Icon(Icons.image_not_supported),
                                      Text("This image can only be viewed on Journee Web.", style: TextStyle(fontWeight: FontWeight.bold),),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (threads.length > 0) Divider(),
                        // if (threads.length > 0) Center(child: Text("Threads")),
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
                                final tuid = threadDetails['tuid'];
                                DateTime threadDateTime = DateTime.parse(threadDetails['created_at']);
                                
                                return ListTile(
                                  onTap: () {
                                    context.push('/thread/$tuid');
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
                              }),
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                ),
                CreateThread(puid: postpuid, allowThread: allowThread),
              ],
            );
          },
        )
      ),
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
                    _deletePost();
                  },
                ),
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
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
  }
