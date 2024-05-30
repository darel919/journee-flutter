// ignore_for_file: prefer_const_constructors, unused_local_variable, unnecessary_new, unused_element, prefer_const_literals_to_create_immutables, avoid_print, unused_import, use_build_context_synchronously, no_logic_in_create_state, unnecessary_null_comparison, prefer_typing_uninitialized_variables, no_leading_underscores_for_local_identifiers, prefer_interpolation_to_compose_strings

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:journee/modify.dart';
import 'package:journee/home.dart';
import 'package:journee/user_posts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class CreateThread extends StatefulWidget {

  const CreateThread({super.key, required this.puid, required this.allowThread});
  
  @override
  State<CreateThread> createState() => _CreateThreadState(puid: puid, allowThread: allowThread);
  
  final String? puid;
  final bool allowThread;
}

class _CreateThreadState extends State<CreateThread> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  _CreateThreadState({required this.puid, required this.allowThread});
  final String? puid;
  final bool allowThread;
  final myController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool uploading = false;
  bool mediaUploadMode = false;
  var filePicked;
  late final User? user = supabase.auth.currentUser;
  late final userData = user?.userMetadata!;
  String? earlyTuid; 
  bool captureMode = false;
  late Uint8List webPreview = filePicked.files.first.bytes!;
  
  File preview() {
    if(captureMode) {
      return File(filePicked.path);
    } else {
      if(kIsWeb) {
        return File(filePicked.files.first.bytes!);
      } else {
        return File(filePicked.files.single.path!);
      }
    }
  }

  Future<void> pickPicture() async {
    await dotenv.load(fileName: 'lib/.env');
    
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    
    if (result != null) {
      setState(() {
        captureMode = false;
        mediaUploadMode = true;
        filePicked = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Media attached!'),
          elevation: 20.0,
        ),
      );
    }
  }

  Future<void> capturePicture() async {
     if(Platform.isAndroid) {
      final ImagePicker _picker = ImagePicker();
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      setState(() {
        captureMode = true;
        mediaUploadMode = true;
        filePicked = photo;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Media captured!'),
          elevation: 20.0,
        ),
      );
     }
  }

  Future<void> uploadThread() async {  
    String? uploadedPuid;
    if(!uploading) {
      try {
        if(myController.text.isNotEmpty) {
          setState(() {
            uploading = true;
          });
          if(mediaUploadMode) {
            final List<Map<String, dynamic>> earlyUploadThread = await supabase.from('threads')
            .insert({
              'uuid': userData!['provider_id'], 
              'puid': puid,
              'details': myController.text, 
            })
            .select();

            if(captureMode) {
              File postMediaAndroid = File(filePicked.path);
              String? earlyTuid = earlyUploadThread[0]['tuid'];
              final uploadPath = earlyTuid!+'/'+filePicked.name;
              final completeImgDir = '${dotenv.env['supabaseUrl']!}/storage/v1/object/public/post_media/'+uploadPath;
              if(!kIsWeb) {
                final String path = await supabase.storage.from('post_media').upload(
                  uploadPath,
                  postMediaAndroid,
                  fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
                );
                final uploadedThread = await supabase.from('threads')
                .update({
                  'mediaUrl': completeImgDir, 
                  'mediaUrlOnDb': uploadPath, 
                })
                .match({ 'tuid': earlyTuid })
                .select();
                setState(() {
                  uploadedPuid = uploadedThread[0]['puid'];
                  uploading = false;
                });
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Post with media upload success'),
                  elevation: 20.0,
                ),
              );
              context.pushReplacement('/post/$uploadedPuid');
            } else {
              PlatformFile file2 = filePicked.files.first;
              Uint8List? postMedia = filePicked.files.first.bytes;
              String fileName = file2.name;

              String? earlyTuid = earlyUploadThread[0]['tuid'];
              final uploadPath = earlyTuid!+'/'+fileName;
              final completeImgDir = '${dotenv.env['supabaseUrl']!}/storage/v1/object/public/post_media/'+uploadPath;
              if(kIsWeb) {
                final String path = await supabase.storage.from('post_media').uploadBinary(
                  uploadPath,
                  postMedia!,
                  fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
                );
                final uploadedThread = await supabase.from('threads')
                .update({
                  'mediaUrl': completeImgDir, 
                  'mediaUrlOnDb': uploadPath, 
                })
                .match({ 'tuid': earlyTuid })
                .select();

                setState(() {
                  uploadedPuid = uploadedThread[0]['puid'];
                  uploading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Post with media upload success'),
                    elevation: 20.0,
                  ),
                );
                context.pushReplacement('/post/$uploadedPuid');
              } 
              else {
                File file = File(filePicked.files.single.path!);
                File postMediaAndroid = file;
                final String path = await supabase.storage.from('post_media').upload(
                  uploadPath,
                  postMediaAndroid,
                  fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
                );
                final uploadedThread = await supabase.from('threads')
                .update({
                  'mediaUrl': completeImgDir, 
                  'mediaUrlOnDb': uploadPath, 
                })
                .match({ 'tuid': earlyTuid })
                .select();

                setState(() {
                  uploadedPuid = uploadedThread[0]['puid'];
                  uploading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Post with media upload success'),
                    elevation: 20.0,
                  ),
                );
                context.pushReplacement('/post/$uploadedPuid');
              }
            }
          } else {
            final List<Map<String, dynamic>> uploadPost = await supabase
            .from('threads')
            .insert({
              'uuid': userData!['provider_id'], 
              'puid': puid,
              'details': myController.text, 
            }).select();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Reply uploaded!'),
                elevation: 20.0,
              ),
            );
            uploadedPuid = uploadPost[0]['puid'];
              setState(() {
                uploading = false;
              });
            context.pushReplacement('/post/$uploadedPuid');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please input text before uploading!'),
                elevation: 20.0,
              ),
            );
        }
      } catch (e) {
        uploading = false;
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error while replying this post. Error: $e'),
            elevation: 20.0,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please wait! Thread is uploading'),
          elevation: 20.0,
        ),
      );
    }
  }

  Future<void> bottomSheetThread() async {
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
      isDismissible: false,
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return bottomSheetThreadMaker();
      }
    );
  }

  StatefulBuilder bottomSheetThreadMaker() {
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Scaffold(
            appBar: uploading ? AppBar(
              title: Text("Reply to this diary"),
              automaticallyImplyLeading: false
            ) : AppBar(
              title: Text("Reply to this diary"),
              actions: <Widget>[
                ElevatedButton(
                  child: const Text('Upload'),
                  onPressed: () {
                    uploadThread().then((value) {
                      setState(() {
                        uploading = true;
                      });
                    });
                  }
                ),
              ],
            ),
            body: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: <Widget>[   
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16,0,0,8),
                      child: TextField(
                        autocorrect: false,
                        readOnly: uploading,
                        autofocus: true,
                        canRequestFocus: true,
                        controller: myController,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Whats on your mind today?',
                        ),
                      ),
                    ),
                    if(!kIsWeb) if(filePicked != null && !uploading) Expanded(child: Image.file(preview())),
                    if(kIsWeb) if(filePicked != null && !uploading) Expanded(child: Image.memory(webPreview)),
                    if(!uploading) Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    pickPicture().then((value) {
                                      setState(() {
                                        mediaUploadMode = true;
                                      });
                                    });
                                  }
                                },
                                child: Icon(Icons.photo_size_select_actual_rounded),
                              ),
                              if(!kIsWeb && Platform.isAndroid) ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    capturePicture().then((value) {
                                      setState(() {
                                        mediaUploadMode = true;
                                      });
                                    });
                                  }
                                },
                                child: Icon(Icons.camera_alt_outlined),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if(uploading) Center(child: Text("Uploading...", style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            ),
          );
        }
      );
  }
  
  @override
  void dispose() {
    myController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: allowThread ? TextField(
      readOnly: true,
      decoration: const InputDecoration(
        // border: OutlineInputBorder(),
        border: InputBorder.none,
        hintText: 'Reply to this thread',
      ),
      onTap: () {
        bottomSheetThread();
      }) : TextField(
        readOnly: true,
        decoration: const InputDecoration(
          // border: OutlineInputBorder(),
          border: InputBorder.none,
          hintText: 'Threads disabled',
        )
      )
    );
  }
}

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
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    // Navigator.of(innerContext).pop();
                    // context.pop();
                    Navigator.pop(context);
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
                                    child: Image.network(thread['mediaUrl'], width: 400, loadingBuilder: (context, child, loadingProgress) => pictureLoadingScreen(context, child, loadingProgress)),
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

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: futureThread, 
            builder: (context, snapshot) {
              if(!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
          
              final threadContent = snapshot.data!;
          
              if(threadContent.isNotEmpty) {
                int counter() {
                  if (threadContent.length > 3) {
                    return 3;
                  } else if (threadContent.length == 2) {
                    return 2;
                  } else if(threadContent.length == 1) {
                    return 1;
                  } else if(threadContent.isEmpty) {
                    return 0;
                  }
                    return 0;
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: thinMode ? NeverScrollableScrollPhysics() : ScrollPhysics(),
                      itemCount: thinMode ? counter() : threadContent.length,
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
                            minTileHeight: 24,
                            minVerticalPadding: 0,
                            contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                            dense: true,
                            title: Row(
                              children: [
                                Text(threadAuthor['name'], style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(8,0,4,0),
                                  child: ConstrainedBox(constraints:BoxConstraints(maxWidth:220), child: Text(threadDetails['details'], overflow: TextOverflow.ellipsis)),
                                ),
                              ],
                            ),
                            trailing: Text(timeago.format(threadDateTime, locale: 'en_short')),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (threadDetails['mediaUrl']!= null && threadDetails['mediaUrl'].isNotEmpty) Padding(
                                  padding: const EdgeInsets.fromLTRB(0,15,0,15),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(threadDetails['mediaUrl'], 
                                    width: 128,
                                    fit: BoxFit.cover,
                                    loadingBuilder: pictureLoadingScreen,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          );
                        } return Column(
                          children: [
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
                    ),
                  ],
                );
              } 
              return Column(
                children: [
                  // Padding(
                  //   padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  //   child: Text("Threads", style: TextStyle(fontWeight: FontWeight.bold)),
                  // ),
                  // Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.fromLTRB(15, 5, 15, 5),
                    title: Text("No replies on this thread"),
                  ),
                ],
              );
            }
          ),
        ),
      ],
    );
  }

Widget pictureLoadingScreen(BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
  if (loadingProgress == null) return child; // If the image is fully loaded, return the child widget
    return Center( // Otherwise, return a loading widget
      child: CircularProgressIndicator( // You can use any widget you like, such as a Shimmer widget
        value: loadingProgress.expectedTotalBytes != null
          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
          : null,
      ),
    );
  }

Future<void> ViewPostThreadBottomSheet(puid, context) {
  
  bool uploading = false;
  final myThreadController = TextEditingController();
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
    showDragHandle: true,
    context: context,
    builder: (BuildContext context) {
      
      @override
      void dispose() {
        myThreadController.dispose();
      }

      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("Threads", style: TextStyle(fontWeight: FontWeight.bold),),
              ),
              Divider(),
              PostThreadViewerComponent(puid, false),
            ],
          ),    
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autocorrect: false,
              readOnly: uploading,
              autofocus: false,
              canRequestFocus: true,
              clipBehavior: Clip.antiAlias,
              controller: myThreadController,
              keyboardType:TextInputType.text,
              textInputAction: TextInputAction.send,
              minLines: 1,
              maxLines: 5,
              decoration: const InputDecoration(
                focusedBorder: OutlineInputBorder(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(50)), 
                ),
                
                hintText: 'Whats on your mind today?',
              ),
            ),
          ),
        ],
      );
    }
  );
}

