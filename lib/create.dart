// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, avoid_print, unused_local_variable, prefer_interpolation_to_compose_strings, prefer_typing_uninitialized_variables, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, unnecessary_new, no_logic_in_create_state

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:journee/post.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CreateDiaryPage extends StatefulWidget {
  const CreateDiaryPage({super.key});

  @override
  State<CreateDiaryPage> createState() => _CreateDiaryPageState();
}

class _CreateDiaryPageState extends State<CreateDiaryPage> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final myController = TextEditingController();
  final supabase = Supabase.instance.client;
  late final User? user = supabase.auth.currentUser;
  late final userData = user?.userMetadata!;
  late List<Map<String, dynamic>> categories = [];
  String? selectedCategory;
  bool mediaUploadMode = false;
  bool uploading = false;
  bool allowThreadReply = true;
  String? earlyPuid; 

  @override
  void initState() {
    super.initState();
    fetchCategory();
  }

  Future<void> fetchCategory() async {
    var _data = await supabase
    .from('categories')
    .select();
    setState(() {
        categories = _data;
        selectedCategory = _data[1]['cuid'];
    });
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }

  var filePicked;
  bool captureMode = false;

  Future<void> upload() async {  
    try {
      if(myController.text.isNotEmpty) {
        setState(() {
          uploading = true;
        });
        if(mediaUploadMode) {
          final List<Map<String, dynamic>> earlyUploadPost = await supabase.from('posts')
          .insert({
            'uuid': userData!['provider_id'], 
            'cuid': selectedCategory,
            'details': myController.text, 
            'allowReply': allowThreadReply, 
            'type': 'Diary'
          })
          .select();

          if(captureMode) {
            File postMediaAndroid = File(filePicked.path);
            earlyPuid = earlyUploadPost[0]['puid'];
            final uploadPath = earlyPuid!+'/'+filePicked.name;
            final completeImgDir = '${dotenv.env['supabaseUrl']!}/storage/v1/object/public/post_media/'+uploadPath;
            if(!kIsWeb) {
              final String path = await supabase.storage.from('post_media').upload(
                uploadPath,
                postMediaAndroid,
                fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
              );
              await supabase.from('posts')
              .update({
                'mediaUrl': completeImgDir, 
                'mediaUrlOnDb': uploadPath, 
              })
              .match({ 'puid': earlyPuid });
              setState(() {
                uploading = false;
              });
            }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Post with media upload success'),
              elevation: 20.0,
            ),
          );
          Navigator.of(context).pushReplacementNamed('/home');
          } else {
            File file = File(filePicked.files.single.path!);
            PlatformFile file2 = filePicked.files.first;
            Uint8List? postMedia = filePicked.files.first.bytes;
            File postMediaAndroid = file;
            String fileName = file2.name;

            earlyPuid = earlyUploadPost[0]['puid'];
            final uploadPath = earlyPuid!+'/'+fileName;
            final completeImgDir = '${dotenv.env['supabaseUrl']!}/storage/v1/object/public/post_media/'+uploadPath;
            if(kIsWeb) {
              final String path = await supabase.storage.from('post_media').uploadBinary(
                uploadPath,
                postMedia!,
                fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
              );
              await supabase.from('posts')
              .update({
                'mediaUrl': completeImgDir, 
                'mediaUrlOnDb': uploadPath, 
              })
              .match({ 'puid': earlyPuid });
              setState(() {
                uploading = false;
              });
            } else {
              final String path = await supabase.storage.from('post_media').upload(
                uploadPath,
                postMediaAndroid,
                fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
              );
              await supabase.from('posts')
              .update({
                'mediaUrl': completeImgDir, 
                'mediaUrlOnDb': uploadPath, 
              })
              .match({ 'puid': earlyPuid });
              setState(() {
                uploading = false;
              });
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Post with media upload success'),
                elevation: 20.0,
              ),
            );
            Navigator.of(context).pushReplacementNamed('/home');
          }
        } else {
          await supabase
          .from('posts')
          .insert({
            'uuid': userData!['provider_id'], 
            'cuid': selectedCategory,
            'details': myController.text, 
            'allowReply': allowThreadReply, 
            'type': 'Diary'
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Post uploaded!'),
              elevation: 20.0,
            ),
          );
           setState(() {
              uploading = false;
            });
          Navigator.of(context).pushReplacementNamed('/home');
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
          content: Text('Error uploading post. Error: $e'),
          elevation: 20.0,
        ),
      );
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
  
  File preview() {
    if(captureMode) {
      return File(filePicked.path);
    } else {
      return File(filePicked.files.single.path!);
    }
  }

  @override
  Widget build(BuildContext context) {
    // print(categories);
    return Scaffold(
      appBar: AppBar(
        // centerTitle: true,
        title: Text("Create New"),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: <Widget>[
             if(!uploading) Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 DropdownButton<String>(
                    hint: Text('Select your category'),
                    value: selectedCategory,
                    onChanged: (newValue) {
                      setState(() {
                        selectedCategory = newValue; 
                      });
                    },
                    items: categories.map((index) {
                      // print(index['cuid']);
                      return DropdownMenuItem<String>(
                        value: index['cuid'] as String,
                        child: Text(index['name']),
                      );
                    }).toList(),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Validate will return true if the form is valid, or false if
                      // the form is invalid.
                      if (_formKey.currentState!.validate()) {
                        // Process data.
                          upload();
                      }
                    },
                    child: const Text('Upload'),
                  ),
               ],
             ),
              TextField(
                readOnly: uploading,
                autofocus: false,
                canRequestFocus: true,
                controller: myController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Whats on your mind today?',
                ),
              ),
              if(filePicked != null && !uploading) Expanded(child: Image.file(preview())),
              if (!uploading) Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              // Process data.
                              pickPicture();
                            }
                          },
                          child: Icon(Icons.photo_size_select_actual_rounded),
                        ),
                         if(Platform.isAndroid) ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              // Process data.
                              capturePicture();
                            }
                          },
                          child: Icon(Icons.camera_alt_outlined),
                        ),
                      ],
                    ),
                   
                    Row(
                      children: [
                        Text("Threads"),
                        Switch(
                          value: allowThreadReply, 
                          onChanged: (bool allowThreadReplyChange) {
                            setState(() {
                              allowThreadReply = allowThreadReplyChange;
                            });
                          }
                        ),
                      ],
                    )
                  ],
                ),
              ),
              if(uploading) Center(child: Text("Uploading...", style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold))),
            ],
          ),
        )),
    );
  }
}

class CreateThread extends StatefulWidget {

  const CreateThread({super.key, required this.puid});
  
  @override
  State<CreateThread> createState() => _CreateThreadState(puid: puid);
  
  final String? puid;
}

class _CreateThreadState extends State<CreateThread> {
  _CreateThreadState({required this.puid});
  final String? puid;
  final myController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool uploading = false;
  bool mediaUploadMode = false;
  var filePicked;
  late final User? user = supabase.auth.currentUser;
  late final userData = user?.userMetadata!;
  String? earlyTuid; 

    Future<void> uploadThread() async {  
    try {
      if(myController.text.isNotEmpty) {
        setState(() {
          uploading = true;
        });
        if(mediaUploadMode) {
          final List<Map<String, dynamic>> earlyUploadPost = await supabase.from('threads')
          .insert({
            'uuid': userData!['provider_id'], 
            'puid': puid,
            'details': myController.text, 
          })
          .select();

          File file = File(filePicked.files.single.path!);
          PlatformFile file2 = filePicked.files.first;
          Uint8List? postMedia = filePicked.files.first.bytes;
          File postMediaAndroid = file;

          earlyTuid = earlyUploadPost[0]['puid'];
          final fileName = file2.name;
          final uploadPath = earlyTuid!+'/'+fileName;
          final completeImgDir = '${dotenv.env['supabaseUrl']!}/storage/v1/object/public/post_media/'+uploadPath;

          if(kIsWeb) {
            final String path = await supabase.storage.from('post_media').uploadBinary(
              uploadPath,
              postMedia!,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
            );
            await supabase.from('threads')
            .update({
              'mediaUrl': completeImgDir, 
              'mediaUrlOnDb': uploadPath, 
            })
            .match({ 'tuid': earlyTuid });
            setState(() {
              uploading = false;
            });
          } else {
            final String path = await supabase.storage.from('post_media').upload(
              uploadPath,
              postMediaAndroid,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
            );
            await supabase.from('threads')
            .update({
              'mediaUrl': completeImgDir, 
              'mediaUrlOnDb': uploadPath, 
            })
            .match({ 'tuid': earlyTuid });
            setState(() {
              uploading = false;
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Replied with media success!'),
              elevation: 20.0,
            ),
          );
          await Navigator.push(context, MaterialPageRoute<void>(builder: (context) => ViewPostRoute(puid: new Puid(earlyTuid!))));

          // Navigator.push(context, MaterialPageRoute<void>(
          //   maintainState: false,
          //   builder: (context) => ViewPostRoute(puid: new Puid(earlyPuid!))));
        } else {
          String? uploadedPuid;
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
          // Navigator.of(context).pop();
          await Navigator.push(context, MaterialPageRoute<void>(builder: (context) => ViewPostRoute(puid: new Puid(uploadedPuid!))));
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
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
          readOnly: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Reply to this thread',
          ),
          onTap: () {
              showModalBottomSheet<void>(
                context: context,
                builder: (BuildContext context) {
                  return Scaffold(
                    appBar: AppBar(title: Text("Reply to this diary")),
                    body: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          TextField(
                            readOnly: uploading,
                            autofocus: false,
                            canRequestFocus: true,
                            controller: myController,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Whats on your mind today?',
                            ),
                          ),
                          if(filePicked != null && !uploading) Expanded(child: Image.file(File(filePicked.files.single.path!))),
                          ElevatedButton(
                            child: const Text('Upload'),
                            onPressed: () => uploadThread(),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              );
          },
        );
  }
}

