// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, avoid_print, unused_local_variable, prefer_interpolation_to_compose_strings, prefer_typing_uninitialized_variables, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, unnecessary_new, no_logic_in_create_state, unused_field, prefer_const_literals_to_create_immutables

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_compression_flutter/image_compression_flutter.dart';
import 'package:geolocator/geolocator.dart';


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
  ValueNotifier<String?> selectedCategory = ValueNotifier<String?>(null);
  String? selectedCatName;
  
  bool mediaUploadMode = false;
  bool uploading = false;
  ValueNotifier<bool?> allowThreadReply = ValueNotifier<bool?>(true);
  ValueNotifier<bool?> embedLocation = ValueNotifier<bool?>(false);
  String? earlyPuid; 
  String? globalLat = '';
  String? globalLong = '';
  var filePicked;
  bool captureMode = false;
  late Uint8List webPreview = filePicked.files.first.bytes!;
  
  Future<SharedPreferences> store() async {
    return await SharedPreferences.getInstance();
  }

  @override
  void initState() {
    super.initState();
    listenToSelectedCategory(context, (String input) {
      createNewCategory(input);
    });
    fetchCategory();
  }

  void showCategoryCreateDialog(BuildContext context, Function callback) {
    TextEditingController textController = TextEditingController();

    void textChecker() {
      if(textController.text.isNotEmpty) {
        Navigator.pop(context, textController.text);
        callback(textController.text);
      } else {
        Navigator.pop(context, textController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New category name cannot be EMPTY!'),
            elevation: 20.0,
          ),
        );
        setState(() {
          selectedCategory.value = categories[1]['cuid'];
          selectedCatName = categories[1]['name'];
        });
      }
    }

    showDialog(
      context: context, builder: (context) {
        return AlertDialog(
          title: Text('Create a new category'),
          content: TextField(
            autofocus: true,
            controller: textController,
            decoration: InputDecoration(hintText: 'Enter a category name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                textChecker();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    ).then((result) {
      if (result == null) {
        setState(() {
          selectedCategory.value = categories[1]['cuid'];
          selectedCatName = categories[1]['name'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New category creation cancelled'),
            elevation: 20.0,
          ),
        );
        // print('The user dismissed the dialog');
      }
    });
  }

  void listenToSelectedCategory(BuildContext context, Function callback) {
    selectedCategory.addListener(() async {
      String? currentValue = selectedCategory.value;
      if (currentValue == 'create') {
        showCategoryCreateDialog(context, callback);
      } else {
        store().then((SharedPreferences store) async{
           await store.setString('selectedCategoryMemory_value', currentValue!);
        });
      }
    });
    allowThreadReply.addListener(() async {
      bool? currentValue = allowThreadReply.value;
        store().then((SharedPreferences store) async{
           await store.setBool('allowThreadReplyPref', currentValue!);
        });
    });
    embedLocation.addListener(() async {
      bool? currentValue = embedLocation.value;
      if(embedLocation.value == true) checkDeviceLocation();
        store().then((SharedPreferences store) async{
           await store.setBool('embedLocationPref', currentValue!);
        });
    });
  }

  Future<void> fetchCategory() async {
    var _data = await supabase
    .from('categories')
    .select();
    setState(() {
        categories = _data;
        categories.add({
          'cuid': 'create',
          'name': 'Create new category',
        });

        store().then((SharedPreferences store) async{
            selectedCategory.value = store.getString('selectedCategoryMemory_value') ?? _data[1]['cuid'];
        });
    });
    threadsCheck();
    locationCheck();
  }

  Future<void> threadsCheck() async {
    setState(() {
      store().then((SharedPreferences store) async{
        allowThreadReply.value = store.getBool('allowThreadReplyPref') ?? true;
      });
    });
  }

  Future<void> locationCheck() async {
    setState(() {
      store().then((SharedPreferences store) async{
        embedLocation.value = store.getBool('embedLocationPref') ?? true;
      });
    });
  }
  
  Future<void> createNewCategory(String categoryName) async {
    var cat = await supabase.from('categories').insert({
      'name': categoryName,
      'uuid': userData!['provider_id'], 
    })
    .select();

    var _data = await supabase
    .from('categories')
    .select();

    setState(() {
        categories = _data;
        categories.add({
          'cuid': 'create',
          'name': 'Create new category',
        });
        selectedCategory.value = cat[0]['cuid'];
        selectedCatName = cat[0]['name'];
        store().then((SharedPreferences store) async{
            selectedCategory.value = store.getString('selectedCategoryMemory_value') ?? _data[1]['cuid'];
        });
       
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New category created successfully'),
        elevation: 20.0,
      ),
    );
  }

  Future<void> checkDeviceLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission;
    if (!serviceEnabled) {
      // return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print('Location permissions are denied');
        setState(() {
          embedLocation.value = false;
          store().then((SharedPreferences store) async{
            await store.setBool('embedLocationPref', false);
          });  
        });
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately. 
      print("Location denied forever.");
      setState(() {
        embedLocation.value = false;
        store().then((SharedPreferences store) async{
          await store.setBool('embedLocationPref', false);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location is set to "Denied". Please allow Journee to access Location.'),
            elevation: 20.0,
          ),
        );
        if(Platform.isAndroid) {
          Geolocator.openLocationSettings();
        }
      });
    } 
    getCurrentLocation();
  }
  
  Future<void> getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );
    globalLat = position.latitude.toString();
    globalLong = position.longitude.toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Location acquired! '+globalLat!+globalLong!),
        elevation: 20.0,
      ),
    );
  }
  
  Future<void> clearGPSLoc() async {
    globalLat = '';
    globalLong = '';
    print("gps reset");
    print('lat: '+globalLat!);
    print('long: '+globalLong!);
  }
  bool isGPSReady() {
    if(globalLat == '' && globalLong == '') {
      return false;
    } else {
      return true;
    }
  }

  @override
  void dispose() {
    myController.dispose();
    clearGPSLoc();
    super.dispose();
  }

  Future<void> upload() async {  
    try {
      if(!uploading) {
        if(myController.text.isNotEmpty) {
          setState(() {
            uploading = true;
          });
          if(embedLocation.value == true) {
            if(isGPSReady() == false) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Location not ready! Please wait before uploading!'),
                  elevation: 20.0,
                ),
              );
              setState(() {
                uploading = false;
              });
            } else {
              if(mediaUploadMode) {
            final List<Map<String, dynamic>> earlyUploadPost = await supabase.from('posts')
            .insert({
              'uuid': userData!['provider_id'], 
              'cuid': selectedCategory.value,
              'details': myController.text, 
              'allowReply': allowThreadReply.value, 
              'type': 'Diary'
            })
            .select();

            if(captureMode) {
              File postMediaAndroid = File(filePicked.path);
              String? earlyPuid = earlyUploadPost[0]['puid'];
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
               context.pushReplacement('/post/$earlyPuid');
            } else {
            PlatformFile file2 = filePicked.files.first;
            Uint8List? postMedia = filePicked.files.first.bytes;
            String fileName = file2.name;

            String? earlyPuid = earlyUploadPost[0]['puid'];
            final uploadPath = earlyPuid!+'/'+fileName;
            final completeImgDir = '${dotenv.env['supabaseUrl']!}/storage/v1/object/public/post_media/'+uploadPath;
            
            if(kIsWeb) {
              final String path = await supabase.storage.from('post_media').uploadBinary(
                uploadPath,
                postMedia!,
                fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
              );
              ImageFile input = ImageFile(
                rawBytes: postMedia, 
                filePath: fileName,
              );
              Configuration config = Configuration(
                outputType: ImageOutputType.webpThenJpg,
                useJpgPngNativeCompressor: false,
                quality: 25,
              );

              final param = ImageFileConfiguration(input: input, config: config);
              final compressedOutput = await compressor.compress(param);
              final previewUploadPath = earlyPuid!+'/preview/'+fileName;
              final previewCompleteImgDir = '${dotenv.env['supabaseUrl']!}/storage/v1/object/public/post_media/'+previewUploadPath;
              
              final String compressedPreviewPath = await supabase.storage.from('post_media').uploadBinary(
                previewUploadPath,
                compressedOutput.rawBytes,
                fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
              );
              await supabase.from('posts')
              .update({
                'mediaUrl': completeImgDir, 
                'mediaUrlOnDb': uploadPath, 
                'mediaUrl_preview': previewCompleteImgDir,
                'mediaUrl_previewOnDb': previewUploadPath,
              })
              .match({ 'puid': earlyPuid });
              setState(() {
                uploading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Post with media upload success'),
                  elevation: 20.0,
                ),
              );
               context.pushReplacement('/');
            } 
            else {
              File file = File(filePicked.files.single.path!);
              File postMediaAndroid = file;
              Future<Uint8List> bytes() async { return file.readAsBytes(); } 
              ImageFile input = ImageFile(
                rawBytes: await bytes(), 
                filePath: file.toString()
              );

              final String path = await supabase.storage.from('post_media').upload(
                uploadPath,
                postMediaAndroid,
                fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
              );

              Configuration config = Configuration(
                outputType: ImageOutputType.webpThenJpg,
                useJpgPngNativeCompressor: false,
                quality: 25,
              );

              final param = ImageFileConfiguration(input: input, config: config);
              final compressedOutput = await compressor.compress(param);
              Future<File> compressedPreview() async {
                final tempDir = Directory.systemTemp;
                final file = await File('${tempDir.path}/$fileName').create();
                file.writeAsBytesSync(compressedOutput.rawBytes);
                return file;
              }
              final previewUploadPath = earlyPuid+'/preview/'+fileName;
              final previewCompleteImgDir = '${dotenv.env['supabaseUrl']!}/storage/v1/object/public/post_media/'+previewUploadPath;
              
              final String compressedPreviewPath = await supabase.storage.from('post_media').upload(
                previewUploadPath,
                await compressedPreview(),
                fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
              );
              await supabase.from('posts')
              .update({
                'mediaUrl': completeImgDir, 
                'mediaUrlOnDb': uploadPath, 
                'mediaUrl_preview': previewCompleteImgDir,
                'mediaUrl_previewOnDb': previewUploadPath,
              })
              .match({ 'puid': earlyPuid });

              // if(isGPSReady()) {
                final List<Map<String, dynamic>> uploadLocUID = await supabase.from('locations')
                .insert({
                  'puid': earlyPuid,
                  'lat': globalLat, 
                  'long': globalLong, 
                  // 'name': 'Diary'
                })
                .select();
                await supabase.from('posts')
                .update({
                  'luid': uploadLocUID[0]['luid']
                })
                .match({ 'puid': earlyPuid });
                clearGPSLoc();
              // }

              setState(() {
                uploading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Post with media upload success'),
                  elevation: 20.0,
                ),
              );
              context.pushReplacement('/post/$earlyPuid');
            }
            }
          } else {
            var link = await supabase
            .from('posts')
            .insert({
              'uuid': userData!['provider_id'], 
              'cuid': selectedCategory.value,
              'details': myController.text, 
              'allowReply': allowThreadReply.value, 
              'type': 'Diary'
            })
            .select();
            String puid = link[0]['puid'];
            // if(isGPSReady()) {
              final List<Map<String, dynamic>> uploadLocUID = await supabase.from('locations')
              .insert({
                'puid': puid,
                'lat': globalLat, 
                'long': globalLong, 
                // 'name': 'Diary'
              })
              .select();
              await supabase.from('posts')
              .update({
                'luid': uploadLocUID[0]['luid']
              })
              .match({ 'puid': puid });
              clearGPSLoc();
            // }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Post uploaded!'),
                elevation: 20.0,
              ),
            );
            setState(() {
                uploading = false;
              });
           
            context.pushReplacement('/post/$puid');
          }
            }
          } else {
            if(mediaUploadMode) {
            final List<Map<String, dynamic>> earlyUploadPost = await supabase.from('posts')
            .insert({
              'uuid': userData!['provider_id'], 
              'cuid': selectedCategory.value,
              'details': myController.text, 
              'allowReply': allowThreadReply.value, 
              'type': 'Diary'
            })
            .select();

            if(captureMode) {
              File postMediaAndroid = File(filePicked.path);
              String? earlyPuid = earlyUploadPost[0]['puid'];
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
               context.pushReplacement('/post/$earlyPuid');
            } else {
            PlatformFile file2 = filePicked.files.first;
            Uint8List? postMedia = filePicked.files.first.bytes;
            String fileName = file2.name;

            String? earlyPuid = earlyUploadPost[0]['puid'];
            final uploadPath = earlyPuid!+'/'+fileName;
            final completeImgDir = '${dotenv.env['supabaseUrl']!}/storage/v1/object/public/post_media/'+uploadPath;
            
            if(kIsWeb) {
              final String path = await supabase.storage.from('post_media').uploadBinary(
                uploadPath,
                postMedia!,
                fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
              );
              ImageFile input = ImageFile(
                rawBytes: postMedia, 
                filePath: fileName,
              );
              Configuration config = Configuration(
                outputType: ImageOutputType.webpThenJpg,
                useJpgPngNativeCompressor: false,
                quality: 25,
              );

              final param = ImageFileConfiguration(input: input, config: config);
              final compressedOutput = await compressor.compress(param);
              final previewUploadPath = earlyPuid!+'/preview/'+fileName;
              final previewCompleteImgDir = '${dotenv.env['supabaseUrl']!}/storage/v1/object/public/post_media/'+previewUploadPath;
              
              final String compressedPreviewPath = await supabase.storage.from('post_media').uploadBinary(
                previewUploadPath,
                compressedOutput.rawBytes,
                fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
              );
              await supabase.from('posts')
              .update({
                'mediaUrl': completeImgDir, 
                'mediaUrlOnDb': uploadPath, 
                'mediaUrl_preview': previewCompleteImgDir,
                'mediaUrl_previewOnDb': previewUploadPath,
              })
              .match({ 'puid': earlyPuid });
              setState(() {
                uploading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Post with media upload success'),
                  elevation: 20.0,
                ),
              );
               context.pushReplacement('/');
            } 
            else {
              File file = File(filePicked.files.single.path!);
              File postMediaAndroid = file;
              Future<Uint8List> bytes() async { return file.readAsBytes(); } 
              ImageFile input = ImageFile(
                rawBytes: await bytes(), 
                filePath: file.toString()
              );

              final String path = await supabase.storage.from('post_media').upload(
                uploadPath,
                postMediaAndroid,
                fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
              );

              Configuration config = Configuration(
                outputType: ImageOutputType.webpThenJpg,
                useJpgPngNativeCompressor: false,
                quality: 25,
              );

              final param = ImageFileConfiguration(input: input, config: config);
              final compressedOutput = await compressor.compress(param);
              Future<File> compressedPreview() async {
                final tempDir = Directory.systemTemp;
                final file = await File('${tempDir.path}/$fileName').create();
                file.writeAsBytesSync(compressedOutput.rawBytes);
                return file;
              }
              final previewUploadPath = earlyPuid+'/preview/'+fileName;
              final previewCompleteImgDir = '${dotenv.env['supabaseUrl']!}/storage/v1/object/public/post_media/'+previewUploadPath;
              
              final String compressedPreviewPath = await supabase.storage.from('post_media').upload(
                previewUploadPath,
                await compressedPreview(),
                fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
              );
              await supabase.from('posts')
              .update({
                'mediaUrl': completeImgDir, 
                'mediaUrlOnDb': uploadPath, 
                'mediaUrl_preview': previewCompleteImgDir,
                'mediaUrl_previewOnDb': previewUploadPath,
              })
              .match({ 'puid': earlyPuid });
              setState(() {
                uploading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Post with media upload success'),
                  elevation: 20.0,
                ),
              );
              context.pushReplacement('/post/$earlyPuid');
            }
            }
          } else {
            var link = await supabase
            .from('posts')
            .insert({
              'uuid': userData!['provider_id'], 
              'cuid': selectedCategory.value,
              'details': myController.text, 
              'allowReply': allowThreadReply.value, 
              'type': 'Diary'
            })
            .select();
            String puid = link[0]['puid'];
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Post uploaded!'),
                elevation: 20.0,
              ),
            );
            setState(() {
                uploading = false;
              });
           
            context.pushReplacement('/post/$puid');
          }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please input text before uploading!'),
                elevation: 20.0,
              ),
            );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please wait! Post is uploading!'),
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
      if(kIsWeb) {
        // print(filePicked);
        // Uint8List fileBytes = filePicked.files.first.bytes;
        return File(filePicked.files.first.bytes!);
      } else {
        return File(filePicked.files.single.path!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: selectedCatName != null ? Text("Create new '$selectedCatName'") : Text("Create new post"),
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
                    disabledHint: Text('Loading'),
                    value: selectedCategory.value,
                    onChanged: (newValue) {
                      setState(() {
                        selectedCategory.value = newValue; 
                      });
                    },
                    items: categories.map((index) {
                      return DropdownMenuItem<String>(
                        onTap: () {
                          selectedCatName = index['name'];
                          print('`${index['name']}`');
                        },
                        value: index['cuid'] as String,
                        child: Text(index['name']),
                      );
                    }).toList(),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                          upload();
                      }
                    },
                    child: const Text('Upload'),
                  ),
               ],
             ),
              TextField(
                readOnly: uploading,
                autofocus: true,
                canRequestFocus: true,
                controller: myController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Whats on your mind today?',
                ),
              ),
              if(!kIsWeb) if(filePicked != null && !uploading) Expanded(child: Image.file(preview())),
              if(kIsWeb) if(filePicked != null && !uploading) Expanded(child: Image.memory(webPreview)),
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
                              pickPicture();
                            }
                          },
                          child: Icon(Icons.photo_size_select_actual_rounded),
                        ),
                         if(!kIsWeb && Platform.isAndroid) ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              capturePicture();
                            }
                          },
                          child: Icon(Icons.camera_alt_outlined),
                        ),
                      ],
                    ),
                    
                  ],
                ),
              ),
              if (!uploading) Column(
                children: [
                  Row(
                    children: [
                      Text("Threads"),
                      Switch(
                        value: allowThreadReply.value!, 
                        onChanged: (bool allowThreadReplyChange) {
                          setState(() {
                            allowThreadReply.value = allowThreadReplyChange;
                          });
                        }
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text("Location"),
                      Switch(
                        value: embedLocation.value!, 
                        onChanged: (bool embedLocationChange) {
                          setState(() {
                            embedLocation.value = embedLocationChange;
                          });
                        }
                      ),
                    ],
                  ),
                  // ElevatedButton(onPressed: getCurrentLocation, child: Text("Get loc"))
                ],
              ),
              if(uploading) Center(child: Text("Uploading...", style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold))),
            ],
          ),
        )),
    );
  }
}

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

  Future<void> bottomSheet() async {
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
                        readOnly: uploading,
                        autofocus: true,
                        canRequestFocus: true,
                        controller: myController,
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
        bottomSheet();
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

class EditDiary extends StatefulWidget {
  const EditDiary({super.key, required this.puid});

  @override
  State<EditDiary> createState() => _EditDiaryState(puid: puid);

  final String? puid;
}

class _EditDiaryState extends State<EditDiary> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  _EditDiaryState({required this.puid});
  final String? puid;
  final myController = TextEditingController();
  final supabase = Supabase.instance.client;
  // late final User? user = supabase.auth.currentUser;
  // late final userData = user?.userMetadata!;
  // late List<Map<String, dynamic>> categories = [];
  // String? selectedCategory;
  // bool mediaUploadMode = false;
  bool uploading = false;
  bool allowThreadReply = false;
  String? mediaUrl;
  bool loading = true;
  // String? earlyPuid; 

  Future<void> _fetch() async {
    var _res = await supabase.from('posts').select('''*''').eq('puid', puid!);
    var details = _res[0]['details'];
    setState(() {
      loading = false;
      mediaUrl = _res[0]['mediaUrl'];
      myController.text = details;
      allowThreadReply = _res[0]['allowReply'];
    });
  }

  Future<void> upload() async {
    setState(() {
      uploading = true;
    });
    await supabase.from('posts')
    .update({
      'details': myController.text,
      'allowReply': allowThreadReply
    })
    .match({ 'puid': puid!});
    setState(() {
      uploading = false;
    });
    context.pushReplacement('/post/$puid');
  }

  @override
  void initState() {
    _fetch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Diary")),
      body: loading ? Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("Loading...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
          CircularProgressIndicator(),
        ],
      )) : Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: <Widget>[

              TextField(
                readOnly: uploading,
                autofocus: true,
                canRequestFocus: true,
                controller: myController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Whats on your mind today?',
                ),
              ),
              if(mediaUrl != null && !uploading) Expanded(child: Image.network(mediaUrl!)),
              if (!uploading) Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Row(
                    //   children: [
                    //     ElevatedButton(
                    //       onPressed: () {
                    //         if (_formKey.currentState!.validate()) {
                    //           // Process data.
                    //           pickPicture();
                    //         }
                    //       },
                    //       child: Icon(Icons.photo_size_select_actual_rounded),
                    //     ),
                    //      if(Platform.isAndroid) ElevatedButton(
                    //       onPressed: () {
                    //         if (_formKey.currentState!.validate()) {
                    //           // Process data.
                    //           capturePicture();
                    //         }
                    //       },
                    //       child: Icon(Icons.camera_alt_outlined),
                    //     ),
                    //   ],
                    // ),
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
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                            upload();
                        }
                      },
                      child: const Text('Save and Upload'),
                    ),
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