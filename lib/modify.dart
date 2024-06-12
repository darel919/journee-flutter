// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, avoid_print, unused_local_variable, prefer_interpolation_to_compose_strings, prefer_typing_uninitialized_variables, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, unnecessary_new, no_logic_in_create_state, unused_field, prefer_const_literals_to_create_immutables

import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:journee/heregeolocation.dart';
import 'package:journee/search.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_compression_flutter/image_compression_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_pannable_rating_bar/flutter_pannable_rating_bar.dart';
import 'package:dio/dio.dart';

class CreateDiaryPage extends StatefulWidget {
  const CreateDiaryPage({super.key});

  @override
  State<CreateDiaryPage> createState() => _CreateDiaryPageState();
}

class _CreateDiaryPageState extends State<CreateDiaryPage> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final myController = TextEditingController();
  final AITextControls = TextEditingController();
  final supabase = Supabase.instance.client;
  late final User? user = supabase.auth.currentUser;
  late final userData = user?.userMetadata!;
  late List<Map<String, dynamic>> categories = [];
  late List<Map<String, dynamic>> foodLocations = [];
  late List<Map<String, dynamic>> foodPrices = [];
  ValueNotifier<String?> selectedCategory = ValueNotifier<String?>(null);
  String? selectedCatName;
  bool mediaUploadMode = false;
  bool uploading = false;
  ValueNotifier<bool?> allowThreadReply = ValueNotifier<bool?>(true);
  ValueNotifier<bool?> embedLocation = ValueNotifier<bool?>(false);
  ValueNotifier<bool?> nowGPSReady = ValueNotifier<bool?>(false);
  ValueNotifier<bool?> isCustomDate = ValueNotifier<bool?>(false);
  String? earlyPuid; 
  String? globalLat = '';
  String? globalLong = '';
  Map<String, dynamic>? preferredLoc = {};
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
    checkDeviceLocation();
    fetchAllLocation();
    // sendToAI();
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
      if(embedLocation.value == false) clearGPSLoc();
      
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
    nowGPSReady.value = false;
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
    setState(() {
      nowGPSReady.value = true;
    });
  }
  
  Future<void> clearGPSLoc() async {
    globalLat = '';
    globalLong = '';
    setState(() {
      nowGPSReady.value = false;
    });
  }
  
  bool isGPSReady() {
    if(globalLat == '' && globalLong == '') {
      nowGPSReady.value = false;
      print(globalLat);
      return false;
    } else {
      nowGPSReady.value = true;
      return true;
    }
  }

  bool isFoodReviewMode() {
    if(selectedCategory.value == '368d3855-965d-4f13-b741-7975bbac80bf') {
      return true;
    } 
    return false;
  }

  // UPLOADER
  Future<void> upload() async {  
    try {
      if(!uploading) {
        // CONTINUE UPLOAD IF THERES TEXT
        if(myController.text.isNotEmpty) {
          setState(() {
            uploading = true;
          });

          // CHECK IF IN FOOD REVIEW MODE
          if(isFoodReviewMode()) {
            // if(embedLocation.value == true || isGPSReady()) {
              // DISABLE UPLOAD IF GPS NOT READY IN FOOD REVIEW MODE
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
              } 
              // CONTINUE UPLOAD IF GPS ALLOWED IN FOOD REVIEW MODE
              else {
                // CONTINUE UPLOAD IF MEDIA ATTACHED IN FOOD REVIEW MODE
                if(mediaUploadMode) {
                  String? earlyUploadPost = await earlyUploader();

                  if(captureMode) {
                    File postMediaAndroid = File(filePicked.path);
                    String? earlyPuid = earlyUploadPost;
                    final uploadPath = earlyPuid!+'/'+filePicked.name;
                    final completeImgDir = '${dotenv.env['supabaseSelfHostUrl']!}/storage/v1/object/public/post_media/'+uploadPath;

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
                      
                      String? uploadLocUID = await locationsUploader();
                      String? uploadReviewUID = await reviewsUploader(earlyPuid, darelRating, inesRating);

                      // UPDATE CREATED LOCATION UNIQUE ID AND REVIEW UNIQUE ID
                      await supabase.from('posts')
                      .update({
                        'luid': uploadLocUID,
                        'ruid': uploadReviewUID,
                      })
                      .match({ 'puid': earlyPuid });
                      clearGPSLoc();

                      setState(() {
                        uploading = false;
                      });
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Food review upload success'),
                        elevation: 20.0,
                      ),
                    );
                    context.pushReplacement('/post/$earlyPuid');

                  } else {
                    PlatformFile file2 = filePicked.files.first;
                    Uint8List? postMedia = filePicked.files.first.bytes;
                    String fileName = file2.name;

                    String? earlyPuid = earlyUploadPost;
                    final uploadPath = earlyPuid!+'/'+fileName;
                    final completeImgDir = '${dotenv.env['supabaseSelfHostUrl']!}/storage/v1/object/public/post_media/'+uploadPath;
                    
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
                      final previewUploadPath = earlyPuid+'/preview/'+fileName;
                      final previewCompleteImgDir = '${dotenv.env['supabaseSelfHostUrl']!}/storage/v1/object/public/post_media/'+previewUploadPath;
                      
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
                      context.pushReplacement('/post/$earlyPuid');
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
                      final previewCompleteImgDir = '${dotenv.env['supabaseSelfHostUrl']!}/storage/v1/object/public/post_media/'+previewUploadPath;
                      
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
                    }
                    
                    String? uploadLocUID = await locationsUploader();
                    String? uploadReviewUID = await reviewsUploader(earlyPuid, darelRating, inesRating);
                    
                    await supabase.from('posts')
                    .update({
                      'luid': uploadLocUID,
                      'ruid': uploadReviewUID,
                    })
                    .match({ 'puid': earlyPuid });
                    clearGPSLoc();
                    
                    setState(() {
                      uploading = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Food review upload success'),
                        elevation: 20.0,
                      ),
                    );
                    context.pushReplacement('/post/$earlyPuid');
                  }
                } 
                // DISABLE UPLOAD IF NO MEDIA IN FOOD REVIEW MODE
                else {
                  setState(() {
                    uploading = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Food review mode requires photo before uploading!'),
                      elevation: 20.0,
                    ),
                  );
                }
              }
          } 
          
          // NOT FOOD REVIEW MODE
          else {
          // UPLOAD WITH GPS
          if(embedLocation.value == true) {
            // DISABLE UPLOAD IF GPS NOT READY
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
            } 
            // CONTINUE UPLOAD WHEN GPS READY
            else {
              // UPLOAD FOR MEDIA MODE
              if(mediaUploadMode) {
                String? earlyUploadPost = await earlyUploader();

                if(captureMode) {
                  File postMediaAndroid = File(filePicked.path);
                  String? earlyPuid = earlyUploadPost;
                  final uploadPath = earlyPuid!+'/'+filePicked.name;
                  final completeImgDir = '${dotenv.env['supabaseSelfHostUrl']!}/storage/v1/object/public/post_media/'+uploadPath;

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
                  
                    String? uploadLocUID = await locationsUploader();

                    await supabase.from('posts')
                    .update({
                      'luid': uploadLocUID
                    })
                    .match({ 'puid': earlyPuid });
                    clearGPSLoc();
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

                  String? earlyPuid = earlyUploadPost;
                  final uploadPath = earlyPuid!+'/'+fileName;
                  final completeImgDir = '${dotenv.env['supabaseSelfHostUrl']!}/storage/v1/object/public/post_media/'+uploadPath;
                  
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
                    final previewUploadPath = earlyPuid+'/preview/'+fileName;
                    final previewCompleteImgDir = '${dotenv.env['supabaseSelfHostUrl']!}/storage/v1/object/public/post_media/'+previewUploadPath;
                    
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

                    String? uploadLocUID = await locationsUploader();
                     await supabase.from('posts')
                    .update({
                      'luid': uploadLocUID
                    })
                    .match({ 'puid': earlyPuid });
                    clearGPSLoc();

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
                    final previewCompleteImgDir = '${dotenv.env['supabaseSelfHostUrl']!}/storage/v1/object/public/post_media/'+previewUploadPath;
                    
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

                    
                     String? uploadLocUID = await locationsUploader();

                    await supabase.from('posts')
                    .update({
                      'luid': uploadLocUID
                    })
                    .match({ 'puid': earlyPuid });
                    clearGPSLoc();
                    

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
              } 
              // UPLOAD FOR NON-MEDIA MODE
              else {
                String? earlyUploadPost = await earlyUploader();
                
                String? puid = earlyUploadPost;
                
                String? uploadLocUID = await locationsUploader();

                await supabase.from('posts')
                .update({
                  'luid': uploadLocUID
                })
                .match({ 'puid': puid! });
                clearGPSLoc();

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
          } 
          // UPLOAD WITHOUT GPS
          else {
            if(mediaUploadMode) {
             String? earlyUploadPost = await earlyUploader();

            if(captureMode) {
              File postMediaAndroid = File(filePicked.path);
              String? earlyPuid = earlyUploadPost;
              final uploadPath = earlyPuid!+'/'+filePicked.name;
              final completeImgDir = '${dotenv.env['supabaseSelfHostUrl']!}/storage/v1/object/public/post_media/'+uploadPath;

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

            String? earlyPuid = earlyUploadPost;
            final uploadPath = earlyPuid!+'/'+fileName;
            final completeImgDir = '${dotenv.env['supabaseSelfHostUrl']!}/storage/v1/object/public/post_media/'+uploadPath;
            
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
              final previewUploadPath = earlyPuid+'/preview/'+fileName;
              final previewCompleteImgDir = '${dotenv.env['supabaseSelfHostUrl']!}/storage/v1/object/public/post_media/'+previewUploadPath;
              
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
              final previewCompleteImgDir = '${dotenv.env['supabaseSelfHostUrl']!}/storage/v1/object/public/post_media/'+previewUploadPath;
              
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
            String? earlyUploadPost = await earlyUploader();
            String? puid = earlyUploadPost;
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
          }
        } 
        // DISABLE UPLOAD IF NO INPUT TEXT
        else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please input text before uploading!'),
                elevation: 20.0,
              ),
            );
        }
      } 
      // DISABLE UPLOAD BUTTON WHILE UPLOADING
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please wait! Post is uploading!'),
            elevation: 20.0,
          ),
        );
      }
      
    } catch (e) {
      setState(() {
        uploading = false;
      });
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading post. Error: $e'),
          elevation: 20.0,
        ),
      );
    }
  }
  Future<String?> earlyUploader() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    Future<String> runningOnPlatform() async{
      if(Platform.isAndroid) {
        return 'Android v$version';
      } else if(Platform.isWindows) {
        return 'Windows v$version';
      }
      return 'Non-web';
    }
    if(kIsWeb) {
      List<Map<String, dynamic>> earlyUploadPost = await supabase.from('posts')
      .insert({
        'uuid': userData!['provider_id'], 
        'cuid': selectedCategory.value,
        'details': myController.text, 
        'allowReply': allowThreadReply.value, 
        'type': 'Diary',
        'created_at': postDateTime!.toIso8601String(),
        'posted_on': 'Web v$version'
      })
      .select();
      return earlyUploadPost[0]['puid'];
    } else {
      List<Map<String, dynamic>> earlyUploadPost = await supabase.from('posts')
      .insert({
        'uuid': userData!['provider_id'], 
        'cuid': selectedCategory.value,
        'details': myController.text, 
        'allowReply': allowThreadReply.value, 
        'type': 'Diary',
        'created_at': postDateTime!.toIso8601String(),
        'posted_on': await runningOnPlatform() 
      })
      .select();
      return earlyUploadPost[0]['puid'];
      }
  }
  Future<String?> locationsUploader() async {
    final Map<String, dynamic>? endpointData = await fetchEndpointData(globalLat, globalLong);  
    try {
      if(preferredLoc!.isEmpty) {
        String currentUserAddress = await endpointData!['address']['label'];
        
        // CHECKS THE DB FOR LOCATION ADDRESS
        final _data = await supabase.from('locations')
        .select()
        .eq('full_address', currentUserAddress)
        .limit(1);
        
        // IF FOUND, ATTACH EXISTING LOCATION LUID INSTEAD OF INSERTING NEW LUID
        try {
          if(_data[0]['full_address'] == currentUserAddress) {
            print('found loc address on db, attaching instead');
            return _data[0]['luid'];
          } 
        } catch (e) {
          print(_data.toString());
          print(currentUserAddress);
          // IF NOT FOUND, INSERT NEW LUID TO DB
          print(e);
          print('loc not found on db, now creating new one');
          final List<Map<String, dynamic>> uploadLocUIDGen = await supabase.from('locations')
          .insert({
            'lat': globalLat, 
            'long': globalLong, 
            'name': await endpointData['title'],
            'full_address': await endpointData['address']['label']
          })
          .select();
          return uploadLocUIDGen[0]['luid'];
        }
      } else {
        print("Returned choosen LUID");
        return preferredLoc!['luid'];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading location post. Error: $e'),
          elevation: 20.0,
        ),
      );
      print(e);
      // rethrow;
    }
    return null;
  }

  // AI Rewrite
  bool isAILoading = false;
  bool isAIPreferred = false;
  bool isAIDone = false;
  String viewTextMode = 'user';
  Future<void> sendToAI() async {
    final dio = Dio();
    if (AITextControls.value.text != '') {
      setState(() {
        viewTextMode = 'ai';
        isAIDone = true;
      });
    } else {
      if (myController.value.text != '') {
        try {
          setState(() {
            isAILoading = true;
          });
          // if(kIsWeb) {

          // } else {
            var response = await dio.request(
            dotenv.env['supabaseSelfHostUrl']!+':2024/v1/chat/completions', 
            options: Options(
              method: 'POST',
              receiveTimeout: Duration(seconds: 15),
              contentType: 'application/json',
            ),
            data: {
              "model": "gpt-3.5-turbo",
              "messages": [
                {
                  "role": "system",
                  "content": 'You are an AI Assistant, your task is to organize all the text inputs to separate lists. These are about food reviews. I want you to separate the reviews and the food prices aside. The text prompt for example would be something like this: "Bakmi PG, Alkid, Yogyakarta Ini adalah salah satu Bakmi Jawa Goreng terenak, beda tipis sama yang di Rama Shinta. Kita sengaja kebawah buat cobain ini. Lokasinya ditengah kota, tepatnya deket Alkid. Parkirnya agak susah karena tempatnya kecil tapi parkir gratis. Buat Bakmi Jawa Gorengnya harganya 28k. Agak pricey sih tapi untung rasanya enak banget.Kalo buat minumnya pesen Es Teh Manis, harganya 7k. Tehnya wangi banget, enak juga rasanya. Menurutku, ini recommended kalo lagi kebawah (dan lagi banyak uang)" From this text prompt, you should return two prompts. The first one is rewrite all the text prompt you receive so it sounds like it was written by a food reviewer.The second one is like this: "Bakmi Jawa Goreng: Rp28.000 Es Teh Manis: Rp7.000" k means thousand, so 10k is 10000. But since we are talking about prices in Indonesian currency (Rupiah), so you should translate it to that. Please provide the following information as a JSON object: - food_prices: - Item: Bakmi Jawa Goreng - Price: Rp28.000 - ai_caption: "Ini adalah salah satu Bakmi Jawa Goreng terenak yang ditemukan di Yogyakarta. Lokasinya di tengah kota, dekat Alkid, dan parkiran gratis. Bakmi Jawa Gorengnya dihargai sekitar Rp28.000, sedangkan Es Teh Manis sekitar Rp7.000. Rasanya enak banget, kalo lagi kebawah." DO NOT return anymore word like Here is the response in JSON format. JUST RETURN THE JSON.'
                },
                {
                  "role": "user",
                  "content": myController.text
                }
              ]
            });
          Map<String, dynamic> aiSortedData = jsonDecode(response.data['choices'][0]['message']['content']);
          foodPrices = aiSortedData['food_prices'];

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('AI Rewrite success!'),
              elevation: 20.0,
            ),
          );
          setState(() {
            AITextControls.value = TextEditingValue(
              text: aiSortedData['ai_caption'],
              selection: TextSelection.fromPosition(TextPosition(offset: aiSortedData['ai_caption'].length)),
            );
            isAILoading = false;
            isAIDone = true;
            viewTextMode = 'ai';
          });
          // }
        } on DioException catch (e) {
          setState(() {
            isAILoading = false;
            isAIDone = false;
            viewTextMode = 'user';
          });
          if (e.response != null) {
            print(e.response!.data);
            print(e.response!.headers);
            print(e.response!.requestOptions);
            String error = e.response!.data['error']['message'];
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Unfortunately, AI is currently not available. $error'),
                elevation: 20.0,
              ),
            );
          } else {
            print(e.requestOptions);
            print(e.message);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Unfortunately, AI is currently not available. Please try again later.'),
                elevation: 20.0,
              ),
            );
          }
        }
      }
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please input some text before using AI Rewrite!'),
          elevation: 20.0,
        ),
      );
    }
    }
  }
  Future<void> undoAIText() async {
    setState(() {
      viewTextMode = 'user';
      isAIDone = false;
    });
  }
  
  // IMAGE PICKER AND PREVIEW 
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
        return File(filePicked.files.first.bytes!);
      } else {
        return File(filePicked.files.single.path!);
      }
    }
  }

  // FOOD RATING SYSTEM
  Future<void> fetchAllLocation() async {
    var loc = await supabase
    .from('locations')
    .select();

    foodLocations = loc;
  }
  double inesRating = 0.0;
  double darelRating = 0.0;
  Widget showFoodReviewUI() {
    return Column(
      children: [
        if (userData!['provider_id'] == '110611428741214053827' || userData!['provider_id'] == '112416715810346894995') Column(
          children: [
            Text(darelRating.toString()),
            PannableRatingBar(
              rate: darelRating,
              items: List.generate(5, (index) =>
                const RatingWidget(
                  selectedColor: Colors.yellow,
                  unSelectedColor: Colors.grey,
                  child: Icon(
                    Icons.star,
                    size: 48,
                  ),
                )),
              onChanged: (value) { // the rating value is updated on tap or drag.
                setState(() {
                  darelRating = value;
                });
              },
            ),
          ],
        ) else if (userData!['provider_id'] == '103226649477885875796' || userData!['provider_id'] == '109587676420726193785' || userData!['provider_id'] == '117026477282809025732') 
        Column(
          children: [
            Text(inesRating.toString()),
            PannableRatingBar(
              rate: inesRating,
              items: List.generate(5, (index) =>
                const RatingWidget(
                  selectedColor: Colors.yellow,
                  unSelectedColor: Colors.grey,
                  child: Icon(
                    Icons.star,
                    size: 48,
                  ),
                )),
              onChanged: (value) { // the rating value is updated on tap or drag.
                setState(() {
                  inesRating = value;
                });
              },
            ),
          ],
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    myController.dispose();
    super.dispose();
  }

  Future<void> bottomSheetLocationSearch() async {
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
        return bottomSheetLocationSearchUI();
      }
    );
  }
  StatefulBuilder bottomSheetLocationSearchUI() {
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Scaffold(
            appBar: AppBar(),
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: locationSearchMode()
            ),
          );
        }
      );
  }
  
  // DATE PICKER
  void _showCalendarDialog(Widget child) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: child,
        ),
      ),
    );
  }
  DateTime? postDateTime = DateTime.now();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: selectedCatName != null ? Text("Create new '$selectedCatName'") : Text("Create new post"),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if(!uploading)Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if(!kIsWeb) if(filePicked != null && !uploading) Flexible(fit: FlexFit.loose, child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(preview(), height: 200))),
                      if(kIsWeb) if(filePicked != null && !uploading) Flexible(fit: FlexFit.loose, child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(webPreview, height: 200))),

                      if(isFoodReviewMode() && !uploading) showFoodReviewUI(),
                      if(!uploading)Padding(
                        padding: const EdgeInsets.fromLTRB(0,16,0,0),
                        child: viewTextMode == 'user' ? TextField(
                          autocorrect: false,
                          readOnly: uploading,
                          minLines: 5,
                          autofocus: true,
                          canRequestFocus: true,
                          controller: myController,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Whats on your mind today?',
                          ),
                        ) : TextField(
                          autocorrect: false,
                          readOnly: uploading,
                          minLines: 5,
                          autofocus: false,
                          canRequestFocus: true,
                          controller: AITextControls,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'This should be filled by AI.',
                          ),
                        ),
                      ),
                      Divider(),
                      
                      // UPLOAD SETTINGS
                      if(!uploading) SingleChildScrollView(
                        child: Column(
                          children: [ 
                            // REWRITE WITH AI BUTTON
                            if(isFoodReviewMode() && isAIDone == false) TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                splashFactory: NoSplash.splashFactory,
                              ),
                              onPressed: () => {
                                if(isAILoading == false && myController.text.isNotEmpty) sendToAI(),
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [ 
                                  Row(
                                    children: [
                                      Icon(Icons.api_rounded),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(8,0,0,0),
                                        child: isAILoading ? Text("Now rewriting with AI...") : Text("Rewrite with AI")
                                      ),
                                    ],
                                  ), 
                                  isAILoading ? CircularProgressIndicator() : Icon(Icons.keyboard_arrow_right)
                                ],
                              ),
                            ),
                            if(isFoodReviewMode() && isAIDone == true) TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                splashFactory: NoSplash.splashFactory,
                              ),
                              onPressed: () => {
                                if(isAILoading == false) undoAIText()
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [ 
                                  Row(
                                    children: [
                                      Icon(Icons.warning),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(8,0,0,0),
                                        child: isAILoading ? Text("Now rewriting with AI...") : Text("Undo AI Text")
                                      ),
                                    ],
                                  ), 
                                  isAILoading ? CircularProgressIndicator() : Icon(Icons.undo_sharp)
                                ],
                              ),
                            ),
                            if(isFoodReviewMode()) Divider(),

                            // Category field select
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                splashFactory: NoSplash.splashFactory,
                                enableFeedback: false,
                              ),
                              onPressed: () => {},
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [ 
                                  Row(
                                    children: [
                                      Icon(Icons.category_outlined),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(8,0,0,0),
                                        child: Text("Category"),
                                      ),
                                    ],
                                  ), 
                                  // Icon(Icons.keyboard_arrow_right)
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isDense: true,
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
                                          },
                                          value: index['cuid'] as String,
                                          child: Text(index['name']),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(),
                            
                            // Attachment media controls
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                splashFactory: NoSplash.splashFactory,
                              ),
                              onPressed: () => {
                                if (_formKey.currentState!.validate()) {
                                  pickPicture()
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [ 
                                  Row(
                                    children: [
                                      Icon(Icons.photo),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(8,0,0,0),
                                        child: mediaUploadMode ? Text("Change photo") : Text("Attach photo"),
                                      ),
                                      
                                    ],
                                  ), 
                                  Icon(Icons.keyboard_arrow_right)
                                ],
                              ),
                            ),
                            Divider(),
                
                            // Take picture controls
                            if(!kIsWeb && Platform.isAndroid)TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                splashFactory: NoSplash.splashFactory,
                              ),
                              onPressed: () => {
                                if (_formKey.currentState!.validate()) {
                                  capturePicture()
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [ 
                                  Row(
                                    children: [
                                      Icon(Icons.camera_alt_outlined),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(8,0,0,0),
                                        child: mediaUploadMode ? Text("Take another photo") : Text("Take a photo"),
                                      ),
                                      
                                    ],
                                  ), 
                                  Icon(Icons.keyboard_arrow_right)
                                ],
                              ),
                            ),
                            if(!kIsWeb && Platform.isAndroid)Divider(),
                            
                             // Upload date controls
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                splashFactory: NoSplash.splashFactory,
                              ),
                              onPressed: () => {
                                _showCalendarDialog(
                                  CupertinoDatePicker(
                                    initialDateTime: DateTime.now(),
                                    minimumDate: DateTime(DateTime.now().year),
                                    maximumDate: DateTime.now(),
                                    mode: CupertinoDatePickerMode.dateAndTime,
                                    use24hFormat: true,
                                    onDateTimeChanged: (DateTime newTime) {
                                      setState(() {
                                        isCustomDate.value = true;
                                        postDateTime = newTime;
                                      });
                                    },
                                  ),
                                ),
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [ 
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_month_outlined),
                                      ValueListenableBuilder(valueListenable: isCustomDate, builder: (context, value, child) {
                                        if(isCustomDate.value == true) {
                                          return Padding(
                                            padding: const EdgeInsets.fromLTRB(8,0,0,0),
                                            child: Text('Upload set to')
                                          );
                                          
                                        } else {
                                          return Padding(
                                            padding: const EdgeInsets.fromLTRB(8,0,0,0),
                                            child: Text('Upload date')
                                          );
                                        }
                                      })
                                      // customDate() ? Text("Set date") 
                                      // mediaUploadMode ? Text("Change photo") : Text("Attach photo"),
                                    ],
                                  ), 
                                 Text(
                                    '${postDateTime!.day}/${postDateTime!.month}',
                                    style: const TextStyle(
                                      fontSize: 22.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            Divider(),

                            // Location controls
                            if(embedLocation.value == true) TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                splashFactory: NoSplash.splashFactory,
                              ),
                              onPressed: () => {
                                if(preferredLoc!.isNotEmpty) setState(() {
                                  // showLocationEditDialog(context);
                                }),
                                // if(preferredLoc!.isEmpty) bottomSheetLocationSearch()
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [ 
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.location_on_outlined),
                                      if(preferredLoc!.isEmpty) Padding(
                                        padding: const EdgeInsets.fromLTRB(8,0,0,0),
                                        child: ValueListenableBuilder(valueListenable: nowGPSReady, builder: (context, value, child) {
                                          if(isGPSReady()) {
                                            return Text("Current location ($globalLat, $globalLong)");
                                          } 
                                            return Text("Searching for location");
                                        }),
                                      ),
                                      if(preferredLoc!.isNotEmpty) Padding(
                                        padding: const EdgeInsets.fromLTRB(8,0,0,0),
                                        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 250), child: Text(preferredLoc!['name'], overflow: TextOverflow.ellipsis, softWrap: false)),
                                      )
                                    ],
                                  ), 
                                  if(preferredLoc!.isEmpty) Icon(Icons.keyboard_arrow_right),
                                  if(preferredLoc!.isNotEmpty) GestureDetector(onTap:() => {
                                    setState(() {
                                      preferredLoc = {};
                                    })
                                  },child: Icon(Icons.close))
                                ],
                              ),
                            ),
                            if(embedLocation.value == false) TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                splashFactory: NoSplash.splashFactory,
                              ),
                              onPressed: () => {
                                if(preferredLoc!.isNotEmpty) setState(() {
                                  preferredLoc = {};
                                  clearGPSLoc();
                                }),
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [ 
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.location_on_outlined),
                                      if(preferredLoc!.isEmpty) Padding(
                                        padding: const EdgeInsets.fromLTRB(8,0,0,0),
                                        child: ValueListenableBuilder(valueListenable: nowGPSReady, builder: (context, value, child) {
                                            return Text("Device location disabled");
                                        }),
                                      ),
                                      if(preferredLoc!.isNotEmpty) Padding(
                                        padding: const EdgeInsets.fromLTRB(8,0,0,0),
                                        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 250), child: Text(preferredLoc!['name'], overflow: TextOverflow.ellipsis, softWrap: false)),
                                      )
                                    ],
                                  ), 
                                  if(preferredLoc!.isNotEmpty) Icon(Icons.close)
                                ],
                              ),
                            ),
                            if(preferredLoc!.isEmpty && foodLocations.isNotEmpty) SizedBox(
                              height: 48,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: foodLocations.length, 
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.all(7),
                                    child: OutlinedButton(
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.all(7),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(7))),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: ConstrainedBox(constraints: BoxConstraints(maxWidth:100), child: Text(foodLocations[index]['name'], style: TextStyle(height: 1), maxLines:1, overflow: TextOverflow.ellipsis,)),
                                      onPressed: () => {
                                        if(foodLocations[index]['lat'].isEmpty) {
                                          clearGPSLoc(),
                                          preferredLoc = {},
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Unable to choose this place as location. Please try again!'),
                                              elevation: 20.0,
                                            ),
                                          ),
                                          if(embedLocation.value == true) checkDeviceLocation(),
                                        } else {
                                          setState(() {
                                            preferredLoc = foodLocations[index];
                                            print(preferredLoc);
                                            globalLat = foodLocations[index]['lat'];
                                            globalLong = foodLocations[index]['long'];
                                            nowGPSReady.value = true;
                                          })
                                        }
                                      },
                                    ),
                                  );
                                }
                              ),
                            ),
                            
                            Divider(),
                            
                            // Comment controls
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [ 
                                Row(
                                  children: [
                                    Text("Turn on commenting"),
                                  ],
                                ), 
                                Switch(
                                  value: allowThreadReply.value!, 
                                  onChanged: (value) => setState(() {
                                    allowThreadReply.value = value;
                                  })
                                )
                                // Icon(Icons.keyboard_arrow_right)
                              ],
                            ),

                            //  LOCATION SETTING
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [ 
                                Row(
                                  children: [
                                    Text("Enable location"),
                                  ],
                                ), 
                                Switch(
                                  value: embedLocation.value!, 
                                  onChanged: (value) => setState(() {
                                    embedLocation.value = value;
                                  })
                                )
                                // Icon(Icons.keyboard_arrow_right)
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                    ],
                  ),
                ),
              ),
            ),
            if(uploading) Expanded(child: Center(child: Text("Uploading...", style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)))),
            if(!uploading) SizedBox(
              width: 300,
              // color: Colors.black,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                      upload();
                  }
                },
                child: const Text('Upload'),
              ),
            ),
          ],
        )
      ),
    );
  }

}

Future<String?> reviewsUploader(String puid, darelRating, inesRating) async {
  final supabase = Supabase.instance.client;
  final List<Map<String, dynamic>> uploadReviewUID = await supabase.from('foodReviews')
  .insert({
    'puid': puid,
    'darelRate': darelRating,
    'inesRate': inesRating
  })
  .select();
  print(uploadReviewUID[0]);
  return uploadReviewUID[0]['ruid'];
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
      appBar: AppBar(
        centerTitle: true,
        title: Text("Edit info"), 
        actions: <Widget> [
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                  upload();
              }
            },
            child: const Text('Done'),
          ),
        ]
      ),
      body: loading ? Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("Loading...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
          CircularProgressIndicator(),
        ],
      )) : Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if(mediaUrl != null && !uploading) Flexible(fit: FlexFit.loose, child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(mediaUrl!))),
                      if (!uploading) Padding(
                        padding: const EdgeInsets.fromLTRB(0,16,0,8),
                        child: TextField(
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
                      if (!uploading) Divider(),
                      if (!uploading) Text("Post controls"),
                      if (!uploading) Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text("Turn on commenting"),
                                  ],
                                ), 
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
                          ],
                        ),
                      ),
                      if(uploading) Center(child: Text("Uploading...", style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              ),
            ),
          ],
        )),
    );
  }
}
