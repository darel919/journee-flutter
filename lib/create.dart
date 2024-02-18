// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, avoid_print, unused_local_variable, prefer_interpolation_to_compose_strings, prefer_typing_uninitialized_variables, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, unnecessary_new

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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

  Future<void> upload() async {  
    try {
      if(myController.text.isNotEmpty) {
        setState(() {
          uploading = true;
        });
        if(mediaUploadMode) {
          await supabase
          .from('posts')
          .update({
            'cuid': selectedCategory,
            'details': myController.text, 
            'allowReply': 'true', 
            'type': 'Diary'
          })
          .match({ 'puid': earlyPuid });
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
        } else {
          await supabase
          .from('posts')
          .insert({
            'uuid': userData!['provider_id'], 
            'cuid': selectedCategory,
            'details': myController.text, 
            'allowReply': 'true', 
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

  Future<void> uploadPicture() async {
    setState(() {
        uploading = true;
      });
    await dotenv.load(fileName: 'lib/.env');
    
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    
    if (result != null) {
      File file = File(result.files.single.path!);
      PlatformFile file2 = result.files.first;

      // print(file2.name);
      // print(file2.bytes);
      // print(file2.size);
      // print(file2.extension);
      // print(file2.path);

      Uint8List? postMedia = result.files.first.bytes;
      File postMediaAndroid = file;

      final List<Map<String, dynamic>> earlyUploadPost = await supabase.from('posts')
        .insert({
          'uuid': userData!['provider_id'], 
          'cuid': selectedCategory,
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
      
      mediaUploadMode = true;
      setState(() {
        uploading = false;
      });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Media upload success'),
            elevation: 20.0,
          ),
        );
      }
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
             Row(
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
                  if (!uploading) ElevatedButton(
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
                autofocus: false,
                canRequestFocus: true,
                controller: myController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Whats on your mind today?',
                ),
              ),
              if (!uploading) Padding(
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
                  ],
                ),
              ),
              if(uploading) Center(child: Text("Uploading...", style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        )),
    );
  }
}