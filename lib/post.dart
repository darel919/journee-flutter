// ignore_for_file: prefer_const_constructors, unused_local_variable, unnecessary_new, unused_element, prefer_const_literals_to_create_immutables, avoid_print, unused_import, use_build_context_synchronously, no_logic_in_create_state, unnecessary_null_comparison, prefer_typing_uninitialized_variables, prefer_interpolation_to_compose_strings

import 'dart:async';
import 'dart:io';
// import 'dart:nativewrappers/_internal/vm/lib/core_patch.dart';

import 'package:flutter/material.dart';
import 'package:flutter_pannable_rating_bar/flutter_pannable_rating_bar.dart';
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
  
  // RATING SYSTEM
  double darelRating = 0.0;
  double inesRating = 0.0;
  double newinesRating = 0.0;
  double newdarelRating = 0.0;
  Future<void> fetchRating() async {
    var res = await supabase
    .from('foodReviews')
    .select('*')
    .eq('ruid', fetchedData['ruid']!);
    reviewData = res[0];
    darelRating = reviewData['darelRate'].toDouble();
    inesRating = reviewData['inesRate'].toDouble();
    if(inesRating == 0.0) {
      var ratingCalculation = darelRating + inesRating;
      var clampedRating = ratingCalculation.clamp(0.0, 5.0);
      calcRating.value = clampedRating.toString();
      
    } else if (darelRating == 0.0) {
      var ratingCalculation = darelRating + inesRating;
      var clampedRating = ratingCalculation.clamp(0.0, 5.0);
      calcRating.value = clampedRating.toStringAsFixed(1);

    } else {
      // Calculate the combined rating and divide by 2 to normalize to a scale of 5
      var ratingCalculation = (darelRating + inesRating) / 2;

      // Clamp the normalized rating between 0.0 and 5.0
      var clampedRating = ratingCalculation.clamp(0.0, 5.0);

      // Set the calculated rating value
      calcRating.value = clampedRating.toStringAsFixed(1);
    }
  }
  ValueNotifier<String?> calcRating = ValueNotifier<String?>('0');
  Future<void> updateAPIRating(mode, rate) async {
    void update() async {
      if(mode == 'darel') {
        await supabase.from('foodReviews')
        .update({
          'darelRate': newdarelRating,
        })
        .match({ 'ruid': fetchedData['ruid']});
      } else {
        await supabase.from('foodReviews')
        .update({
          'inesRate': newinesRating,
        })
        .match({ 'ruid': fetchedData['ruid']});
      }
      print("$mode rate update to $rate");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 2),
          content: Text('Updated rating to $rate'),
          elevation: 20.0,
        ),
      );
      Navigator.pop(context);
      setState(() {
        calcRating.value = '0';
      });
    }
    void ignore() async {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 2),
          content: Text('Rating not updated'),
          elevation: 20.0,
        ),
      );
      Navigator.pop(context);
      setState(() {
        calcRating.value = '0';
      });
    }
    print('current $newdarelRating');
    print('new $darelRating');
    
    if(mode == 'ines') {
      if(inesRating == newinesRating) {
        ignore();
      } else {
        update();
      }
    } else {
      if(darelRating == newdarelRating) {
        ignore();
      } else {
        update();
      }
    }
  }
  Future<Future<Object?>> _showEditRateUI() async {
    newdarelRating = darelRating;
    newinesRating = inesRating;

    return Navigator.of(context).push(PageRouteBuilder(
      opaque: false, // Set to false so you can see the page behind the bottom sheet
      pageBuilder: (BuildContext context, _, __) {
        return editRateUI();
      },
      transitionsBuilder: (___, Animation<double> animation, ____, Widget child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
   ),
  );
}
  StatefulBuilder editRateUI() {
    return StatefulBuilder(builder: (context, StateSetter setState) {
        return GestureDetector(
          onTap: closeBottomSheet,
          child: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (userData!['provider_id'] == '110611428741214053827' || userData!['provider_id'] == '112416715810346894995') Column(
                      children: [
                        inesRating == 0.0 ? Text("Ines hasn't given rating to this yet.") : Text('Ines rates this: '+newinesRating.toString()),
                        Text('You rate: '+newdarelRating.toString()),
                        PannableRatingBar(
                          rate: newdarelRating,
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
                              newdarelRating = value;
                            });
                            // updateRating('darel', value);
                          },
                          onCompleted:(value) {
                              updateAPIRating('darel', value);
                          },
                        ),
                      ],
                    ) else if (userData!['provider_id'] == '103226649477885875796' || userData!['provider_id'] == '109587676420726193785' || userData!['provider_id'] == '117026477282809025732') 
                    Column(
                      children: [
                        darelRating == 0.0 ? Text("Darrell hasn't given rating to this yet.") : Text('Darrell rates this: '+newdarelRating.toString()),
                        Text('You rate: '+newinesRating.toString()),
                        PannableRatingBar(
                          rate: newinesRating,
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
                              newinesRating = value;
                              // updateRating('ines', value);
                            });
                          },
                          onCompleted:(value) {
                              updateAPIRating('ines', value);
                          },
                        ),
                      ],
                    ),
                    if(inesRating > 0 && darelRating > 0)Text("End calculation: "+calcRating.value!.toString()),
                    Text("Tap anywhere to close")
                  ],
                ),
              ),
          ),
        );
      }
    );
  }
  void closeBottomSheet() async{
    if(userData!['provider_id'] == '103226649477885875796'|| userData!['provider_id'] == '109587676420726193785' || userData!['provider_id'] == '117026477282809025732') {
      if (Navigator.canPop(context)) {
        await updateAPIRating('ines', newinesRating);
      }
    } else if(userData!['provider_id'] == '110611428741214053827' || userData!['provider_id'] == '112416715810346894995'){
      if (Navigator.canPop(context)) {
        await updateAPIRating('darel', newdarelRating);
      }
    }
  }

  Timer? _debounce;
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void updateRating(mode, value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
    updateAPIRating(mode, value);
    });
  }

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
                  if(isFoodReview()) PopupMenuItem<int>(onTap:() => _showEditRateUI(), value: 2, child: Text('Rating')),
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
            final user = post['users'];
            final threads = post['threads'];
            postuuid = post['uuid'];
            postpuid = post['puid'];
            postluid = post['luid'];
            postcatid = post['cuid'];
            allowThread = post['allowReply'];
            DateTime myDateTime = DateTime.parse(post['created_at']);
            String convertedDate() {
              var fetchedDate = myDateTime.toLocal();
              var hour = fetchedDate.hour.toString();
              var minute = fetchedDate.minute.toString();
              var date = fetchedDate.day.toString();
              var month = fetchedDate.month.toString();
              var year = fetchedDate.year.toString();

              return hour+':'+minute+' '+date+'/'+month+'/'+year;
            }
            
            return GestureDetector(
              onLongPress: () {
                
              },
              child: Column(
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
                                // contentPadding: EdgeInsets.fromLTRB(15, 15, 15, 5),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(48.0),
                                  child: isFoodReview() ? Image.network(user!['avatar_url'], width: 48, height: 48
                                  ) : Image.network(user!['avatar_url'], width: 40, height: 40
                                  )
                                ),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        // overlayColor: Colors.transparent,
                                        // foregroundColor: Colors.white,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        splashFactory: NoSplash.splashFactory,
                                        minimumSize: Size(10, 10),
                                        alignment: isLocationAttached() ? Alignment.bottomLeft : Alignment.centerLeft
                                      ),
                                      child: Text(user['name'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), 
                                      onPressed: () {
                                        if(isAdmin()) {
                                          context.go('/account');
                                        } else {
                                          context.push('/user/$postuuid');
                                        }
                                      }
                                    ),
                                    if(isLocationAttached()) TextButton.icon(
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        // overlayColor: Colors.transparent,
                                        // foregroundColor: Colors.white,
                                        // foregroundColor: Theme.of(context).primaryColor,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        splashFactory: NoSplash.splashFactory,
                                        minimumSize: Size(10, 10)
                                        // alignment: Alignment.topLeft
                                      ),
                                      onPressed: () => goLocation(post['locations']['lat'], post['locations']['long']), 
                                      label: post['locations']['name'] != null ? Text(post['locations']['name'], overflow: TextOverflow.ellipsis) : Text('Location name unavailable', overflow: TextOverflow.ellipsis), 
                                      // icon: Icon(Icons.location_pin),
                                    ),
                                    if(isFoodReview()) TextButton.icon(
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        // overlayColor: Colors.transparent,
                                        // foregroundColor: Colors.white,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        splashFactory: NoSplash.splashFactory,
                                        alignment: Alignment.topLeft,
                                        minimumSize: Size(10, 10)
                                      ),
                                      onPressed: () => _showEditRateUI(),
                                      // onPressed: () => context.push('/category/368d3855-965d-4f13-b741-7975bbac80bf'), 
                                      label: ValueListenableBuilder(valueListenable: calcRating, builder: (context, value, child) {
                                        if(calcRating.value! == '0') {
                                          Text('No rating yet');
                                        } return Text(calcRating.value!);
                                      }),
                                      icon: Icon(Icons.star),
                                    )
                                  ],
                                ),
                                // trailing: Text(timeago.format(myDateTime, locale: 'en'))
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // if(isFoodReview()) showRatingUI(),
                                   
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
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                                      child: Text(post['details']),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(0,16,0,0),
                                      child: Text(
                                        convertedDate()+' – '+(timeago.format(myDateTime, locale: 'en')),
                                        style: TextStyle(
                                          color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white.withOpacity(0.5)
                                            : Colors.black.withOpacity(0.5),
                                        ),
                                      ),
                                    ),                        // Divider()
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          if (threads.length > 0) Divider(),
                          // if (threads.length > 0) Center(child: Text("Threads")),
                          PostThreadViewerComponent(puid, true),
                        ],
                      ),
                    ),
                  ),
                  CreateThread(puid: postpuid, allowThread: allowThread),
                ],
              ),
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
                  style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.red)),
                  child: Text('Delete', style: TextStyle(color: Colors.white),),
                  onPressed: () {
                    _deletePost();
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
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
  }
