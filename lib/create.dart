// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, avoid_print, unused_local_variable, prefer_interpolation_to_compose_strings

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  bool mediaUploadMode = false;
  String? earlyPuid; 

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }

  Future<void> upload() async {  
    try {
      if(myController.text.isNotEmpty) {
        if(mediaUploadMode) {
          await supabase
          .from('posts')
          .update({
            'cuid': '55be6834-4ad8-4af3-a35a-b0fe3d5907a5',
            'details': myController.text, 
            'allowReply': 'true', 
            'type': 'Diary'
          })
          .match({ 'puid': earlyPuid });
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          await supabase
          .from('posts')
          .insert({
            'uuid': userData!['provider_id'], 
            'cuid': '55be6834-4ad8-4af3-a35a-b0fe3d5907a5',
            'details': myController.text, 
            'allowReply': 'true', 
            'type': 'Diary'
          });
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> uploadPicture() async {
    await dotenv.load(fileName: 'lib/.env');
    
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    
    if (result != null) {
      File file = File(result.files.single.path!);
      PlatformFile file2 = result.files.first;

      print(file2.name);
      print(file2.bytes);
      print(file2.size);
      print(file2.extension);
      print(file2.path);

      Uint8List? postMedia = result.files.first.bytes;
      File postMediaAndroid = file;

      final List<Map<String, dynamic>> earlyUploadPost = await supabase.from('posts')
        .insert({
          'uuid': userData!['provider_id'], 
          'cuid': '55be6834-4ad8-4af3-a35a-b0fe3d5907a5',
          'details': '', 
          'allowReply': 'true', 
          'type': 'Diary'
        })
        .select();

      earlyPuid = earlyUploadPost[0]['puid'];
      final fileName = file2.name;
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
      
      mediaUploadMode = true;

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
      
      mediaUploadMode = true;

      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create"),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: <Widget>[
              TextField(
                autofocus: true,
                canRequestFocus: true,
                controller: myController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Whats on your mind today?',
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Validate will return true if the form is valid, or false if
                        // the form is invalid.
                        if (_formKey.currentState!.validate()) {
                          // Process data.
                          uploadPicture();
                        }
                      },
                      child:  Icon(Icons.photo_size_select_actual_rounded),
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
              ),
            ],
          ),
        )),
    );
  }
}