// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, avoid_print, unused_local_variable, unnecessary_const, no_leading_underscores_for_local_identifiers, unused_element, unnecessary_new, unused_field, prefer_interpolation_to_compose_strings

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journee/categories.dart';
import 'package:journee/threads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePostView extends StatefulWidget {
  const HomePostView({super.key});

  @override
  State<HomePostView> createState() => _HomePostViewState();
}

class _HomePostViewState extends State<HomePostView> with SingleTickerProviderStateMixin {
  
  static const appcastURL = 'https://raw.githubusercontent.com/darel919/journee-flutter/main/android/app/appcast/appcast.xml';
  static const _urlAndroid = 'https://github.com/darel919/journee-flutter/releases/download/app/app-release.apk';
  static const _url = 'https://github.com/darel919/journee-flutter/releases/';
  String? version;
  String? newestVersion;
  bool willUpgrade = false;
  final upgrader = Upgrader(
    durationUntilAlertAgain: Duration(seconds: 1),
    debugDisplayAlways: false,
    debugLogging: true,
    storeController: UpgraderStoreController(
      onAndroid: () => UpgraderAppcastStore(appcastURL: appcastURL),
    ),
  );
  // late Upgrader upgrader = Upgrader(
  //   durationUntilAlertAgain: Duration(seconds: 1),
  //   debugDisplayAlways: false,
  //   debugLogging: false,
  // //     willDisplayUpgrade: ({appStoreVersion, required display, installedVersion, minAppVersion}) {
  // //   if(appStoreVersion == version) {
  // //     willUpgrade = false;
  // //   } else {
  // //     willUpgrade = display;
  // //   }
  // //     newestVersion = appStoreVersion;
  // // },
  //   minAppVersion: newestVersion,
  //     // appcastConfig:
  //     //     AppcastConfiguration(url: appcastURL, supportedOS: ['android'])
  // );
  bool launchUpdateURL() {
    if(Platform.isAndroid) {
      launchUrl(Uri.parse(_urlAndroid));
    } if(Platform.isWindows) {
      launchUrl(Uri.parse(_url));
    }
    return true;
  }
  final supabase = Supabase.instance.client;
  late final User? user = supabase.auth.currentUser;
  late final userData = user?.userMetadata!;
  late final _future = supabase
    .from('posts')
    .select('''*, users(*), threads ( * ), categories ( * )''')
    .neq('cuid', '368d3855-965d-4f13-b741-7975bbac80bf')
    .order('created_at',  ascending: false);
  
  Future<void> _refresh() async {
    context.pushReplacement('/');
  }
  Widget AllPostView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if(!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
          
        final posts = snapshot.data!;
        return NewPostView(posts, snapshot, false, true);
      }
    );  
  }

  late TabController _secondaryTabController;
  
  @override
  void initState() {
     super.initState();
     _secondaryTabController = TabController(length: 2, vsync:this);
  }
  @override
  void dispose() {
    _secondaryTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          primary: true,
          title: Text("Journee"),
          actions: <Widget> [
            GestureDetector(
              onTap: () => context.push('/account'),
              child: Padding(
                padding: EdgeInsets.fromLTRB(0,0,20,0), 
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32.0),
                  child: Image.network(userData!['avatar_url'], width: 32, height: 32))),
            )
          ],
          bottom: TabBar( 
            tabs: [ 
              Tab( 
                text: "Diaries", 
              ), 
              Tab( 
                text: "Foods", 
              ), 
              Tab( 
                text: "All Categories", 
              ), 
            ], 
          ), 
          automaticallyImplyLeading: false,
        ),        
        body: TabBarView(
          children: [
            UpgradeAlert(
              showIgnore: false, 
              showLater: false,
              onUpdate: () => launchUpdateURL(), 
              child: RefreshIndicator(
                  onRefresh: () => _refresh(),
                  child: AllPostView(),
                ),
              ),
            FoodReviewHome(_secondaryTabController),
            CategoriesPage()
          ]
        ),
      ),
    );
  }
}
Widget FoodReviewHome(TabController _secondaryTabController) {
  final supabase = Supabase.instance.client;
  late final _futureFoodRankView = supabase
  .from('posts')
  .select('''*, users(*), threads ( * ), categories ( * ), locations(*)''')
  .eq('cuid', '368d3855-965d-4f13-b741-7975bbac80bf')
  .order('created_at',  ascending: false);

  return FutureBuilder<List<Map<String, dynamic>>>(
    future: _futureFoodRankView,
    builder: (context, snapshot) {
      if(!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
        
      final posts = snapshot.data!;
      final PageController _pageController = PageController(initialPage: 0);
      return DefaultTabController(
        
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            flexibleSpace: TabBar(
              controller: _secondaryTabController,
              tabs: [
                Tab(text: 'Ratings'),
                Tab(text: 'Reviews'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _secondaryTabController,
            children: [
              GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity! > 0) {
                    DefaultTabController.of(context).animateTo(0);
                  } else {
                    _secondaryTabController.animateTo(1);
                  }
                },
                child: FoodModeGridView(posts, snapshot, true)), // First tab content
              GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity! < 0) {
                    DefaultTabController.of(context).animateTo(2);
                  } else {
                    _secondaryTabController.animateTo(0);
                  }
                },
                child: NewPostView(posts, snapshot, true, true))
            ],
          ),
        ),
      );
    }
  );  
}

Widget FoodModeGridView(List<Map<String, dynamic>> posts, AsyncSnapshot<List<Map<String, dynamic>>> snapshot, bool scrollPhysics) {
  final supabase = Supabase.instance.client;  
  Future<String> fetchRating(ruid) async {
    double darelRating = 0.0;
    double inesRating = 0.0;
    Map<String, dynamic> reviewData = {};
    
    try {
      var res = await supabase
      .from('foodReviews')
      .select('*')
      .eq('ruid', ruid);
      reviewData = res[0];
      darelRating = reviewData['darelRate'].toDouble();
      inesRating = reviewData['inesRate'].toDouble();
    } catch (e) {
      print(e);
    }

    
    if(inesRating == 0.0) {
      var ratingCalculation = darelRating + inesRating;
      var clampedRating = ratingCalculation.clamp(0.0, 5.0);
      return clampedRating.toString();
      
    } else if (darelRating == 0.0) {
      var ratingCalculation = darelRating + inesRating;
      var clampedRating = ratingCalculation.clamp(0.0, 5.0);
      return clampedRating.toStringAsFixed(1);

    } else {
      // Calculate the combined rating and divide by 2 to normalize to a scale of 5
      var ratingCalculation = (darelRating + inesRating) / 2;

      // Clamp the normalized rating between 0.0 and 5.0
      var clampedRating = ratingCalculation.clamp(0.0, 5.0);

      // Set the calculated rating value
      return clampedRating.toStringAsFixed(1);
    }
  }
  
  return GridView.builder(
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
    itemCount: posts.length,
    itemBuilder: (BuildContext context, index) {
      final post = posts[index];
      final puid = post['puid'];

      return GridTile(
        child: post['mediaUrl_preview'] != null ? GestureDetector(
          onTap: () => context.push('/post/$puid'),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                PictureViewerWidget(post['mediaUrl_preview'], 400, 400, false),
                SizedBox(
                  width: 40,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.75)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0,0,4,0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.star, size: 13),
                          FutureBuilder<String>(
                          future: fetchRating(post['ruid']), // your async function call
                          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                            if (snapshot.connectionState == ConnectionState.done) {
                              if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else if (snapshot.hasData) {
                                return Text(snapshot.data!); // display the data
                              }
                            }
                            // By default, show a loading spinner
                            return Text('...');
                          },
                        ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ) : GestureDetector(
          onTap: () => context.push('/post/$puid'),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Stack(
              children: [
                PictureViewerWidget(post['mediaUrl'], 100, 100, false),
                SizedBox(
                  width: 40,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.75)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0,0,4,0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.star, size: 13),
                          FutureBuilder<String>(
                          future: fetchRating(post['ruid']), // your async function call
                          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                            if (snapshot.connectionState == ConnectionState.done) {
                              if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else if (snapshot.hasData) {
                                return Text(snapshot.data!); // display the data
                              }
                            }
                            // By default, show a loading spinner
                            return Text('...');
                          },
                        ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  );
}

Widget NewPostView(List<Map<String, dynamic>> posts, AsyncSnapshot<List<Map<String, dynamic>>> snapshot, bool foodMode, bool scrollPhysics) {
  final supabase = Supabase.instance.client;  
  ValueNotifier<String> catName = ValueNotifier<String>('');
  Future<String> fetchRating(ruid) async {
    double darelRating = 0.0;
    double inesRating = 0.0;
    Map<String, dynamic> reviewData = {};
    try {
      var res = await supabase
      .from('foodReviews')
      .select('*')
      .eq('ruid', ruid);
      reviewData = res[0];
      darelRating = reviewData['darelRate'].toDouble();
      inesRating = reviewData['inesRate'].toDouble();
    } catch (e) {
      print(e);
    }

    
    if(inesRating == 0.0) {
      var ratingCalculation = darelRating + inesRating;
      var clampedRating = ratingCalculation.clamp(0.0, 5.0);
      return clampedRating.toString();
      
    } else if (darelRating == 0.0) {
      var ratingCalculation = darelRating + inesRating;
      var clampedRating = ratingCalculation.clamp(0.0, 5.0);
      return clampedRating.toStringAsFixed(1);

    } else {
      // Calculate the combined rating and divide by 2 to normalize to a scale of 5
      var ratingCalculation = (darelRating + inesRating) / 2;

      // Clamp the normalized rating between 0.0 and 5.0
      var clampedRating = ratingCalculation.clamp(0.0, 5.0);

      // Set the calculated rating value
      return clampedRating.toStringAsFixed(1);
    }
  }
  
  return ListView.builder(
    shrinkWrap: true,
    itemCount: posts.length,
    physics: scrollPhysics ? AlwaysScrollableScrollPhysics() : NeverScrollableScrollPhysics(),
    itemBuilder: ((context, index) {
      
      final post = posts[index];
      final user = post['users'];
      final location = post['locations'];
      final puid = post['puid'];
      final thread = post['threads'];
      DateTime myDateTime = DateTime.parse(post['created_at']);
      ValueNotifier<bool?> readMore = ValueNotifier<bool?>(false);
      bool loading = false;

      if(foodMode) {
        return ListTile(
          contentPadding: EdgeInsets.fromLTRB(0, 5, 0, 5),
          title: Row(
            children: [
              // OWNER PHOTO
              Padding(
                padding: const EdgeInsets.fromLTRB(8,0,8,0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50.0),
                  child: Image.network(
                    user['avatar_url'], 
                    height: 40.0,
                    width: 40.0,
                    fit:BoxFit.cover
                  )
                ),
              ),
      
              // POST METADATA
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['name']),
                  location == null ? Text('Loc Unavail') : ConstrainedBox(constraints: BoxConstraints(maxWidth: 275), child: Text(location['name'], overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12),)),
                  GestureDetector(
                    onTap: () => context.push('/post/$puid'),
                    child: Row(
                      children: [
                        Icon(Icons.star),
                        FutureBuilder<String>(
                          future: fetchRating(post['ruid']), // your async function call
                          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                            if (snapshot.connectionState == ConnectionState.done) {
                              if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else if (snapshot.hasData) {
                                return Text(snapshot.data!); // display the data
                              }
                            }
                            // By default, show a loading spinner
                            return Text('...');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.fromLTRB(0,8,0,8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IMAGE
                GestureDetector(
                  onTap: () {
                    context.push('/post/$puid');
                  },
                  child: post['mediaUrl_preview'] != null ? Padding(
                    padding: const EdgeInsets.fromLTRB(0 ,8, 0, 0),
                    child: PictureViewerWidget(post['mediaUrl_preview'], 400, 400, false),
                  ) : Padding(
                    padding: const EdgeInsets.fromLTRB(0 ,8, 0, 0),
                    child: PictureViewerWidget(post['mediaUrl'], 400, 400, false),
                  ),
                ),
              
                // FOOD CAPTION
                GestureDetector(
                  onTap: () => readMore.value = true,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(15,24,15,10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ValueListenableBuilder(valueListenable: readMore, builder: (context, value, child) {
                          if(readMore.value == true) {
                            return GestureDetector(onTap: () => ViewPostThreadBottomSheet(puid, context),child: Text(post['details']));
                          } else {
                            return Text(post['details'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14));
                          }
                        }),                                        
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0,16,0,0),
                          child: Text(
                            timeago.format(myDateTime, locale: 'en'),
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.5)
                                : Colors.black.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        return ListTile(
          contentPadding: EdgeInsets.fromLTRB(0, 5, 0, 5),
          title: GestureDetector(
            onTap: () => context.push('/post/$puid'),
            child: Row(
            children: [
              // OWNER PHOTO
              Padding(
                padding: const EdgeInsets.fromLTRB(8,0,8,0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32.0),
                  child: Image.network(
                    user['avatar_url'], 
                    height: 32.0,
                    width: 32.0,
                    fit:BoxFit.cover
                  )
                ),
              ),
      
              // POST METADATA
              location == null ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['name']),
                  Text(post['categories']['name'], style: TextStyle(fontSize: 11))
                ],
              ) : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['name']),
                  ConstrainedBox(constraints: BoxConstraints(maxWidth: 275), child: Text(location['name'], overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12),)),
                ],
              ),
            ],
          ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.fromLTRB(0,8,0,8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IMAGE
                if(post['mediaUrl'] != null) GestureDetector(
                  onTap: () {
                    context.push('/post/$puid');
                  },
                  child: post['mediaUrl_preview'] != null ? Padding(
                    padding: const EdgeInsets.fromLTRB(0 ,8, 0, 0),
                    child: PictureViewerWidget(post['mediaUrl_preview'],400,400, false),
                  ) : Padding(
                    padding: const EdgeInsets.fromLTRB(0 ,8, 0, 0),
                    child: PictureViewerWidget(post['mediaUrl'],400,400, false),
                  ),
                ),
              
                // CAPTION
                GestureDetector(
                  onTap: () => readMore.value = true,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(15,24,15,10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ValueListenableBuilder(valueListenable: readMore, builder: (context, value, child) {
                          if(readMore.value == true) {
                            return GestureDetector(onTap: () => ViewPostThreadBottomSheet(puid, context),child: Text(post['details']));
                          } else {
                            return Text(post['details'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14));
                          }
                        }),                                        
                        if(thread.length>0) Padding(
                          padding: const EdgeInsets.fromLTRB(0,8,0,8),
                          child: PostThreadViewerComponent(puid, true),
                        ),
                        if(thread.length == 0) Padding(padding: EdgeInsets.fromLTRB(0, 16, 0, 16)),
                        if(thread.length >3 )Padding(
                          padding: const EdgeInsets.fromLTRB(0,16,0,0),
                          child: Text(
                            "View all threads",
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.5)
                                : Colors.black.withOpacity(0.5),
                            ),
                          ),
                        ),
                        Text(
                          timeago.format(myDateTime, locale: 'en'),
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.5)
                              : Colors.black.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  ),
);
}

Widget OldPostView(List<Map<String, dynamic>> posts, AsyncSnapshot<List<Map<String, dynamic>>> snapshot, bool scrollPhysics) {
  return ListView.builder(
    shrinkWrap: true,
    physics: scrollPhysics ? AlwaysScrollableScrollPhysics() : NeverScrollableScrollPhysics(),
    itemCount: posts.length,
    itemBuilder: ((context, index) {
  
      final post = posts[index];
      final user = post['users'];
      final puid = post['puid'];
      int threadLength = post['threads'].length;
      final special = post['type'];
      DateTime myDateTime = DateTime.parse(post['created_at']);
  
      return ListTile(
        onTap: () {
          context.push('/post/$puid');
        },
        contentPadding: EdgeInsets.fromLTRB(10, 5, 10, 5),
        isThreeLine: true,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(48.0),
          child: Image.network(user['avatar_url']
          )
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0,0,4,0),
                  child: Text(user['name']),
                ),
                if(special == 'Special') Padding(
                  padding: const EdgeInsets.fromLTRB(5,0,0,0),
                  child: Icon(Icons.star_border_outlined),
                )
              ],
            ),
          ],
        ),
        trailing: Text(timeago.format(myDateTime, locale: 'en_short')),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post['details'], maxLines: 3, style: TextStyle(fontSize: 12.5, height: 2)),
            if(post['mediaUrl_preview'] != null) Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: PictureViewerWidget(post['mediaUrl_preview'],400,400, false),),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
              child: Row(
                children: [
                  if(post['mediaUrl_preview'] == null && post['mediaUrl'] != null) Padding(
                    padding: const EdgeInsets.fromLTRB(0, 5, 5, 0),
                    child: Icon(Icons.image_outlined, size: 22),
                  ),
                  if(post['allowReply']) Padding(
                    padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 20),
                        if(threadLength > 0) Padding(
                          padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                          child: Text('$threadLength'),
                        ),
                      ],
                    ),
                  ),
                  if(!post['allowReply']) Padding(
                    padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon(Icons.comments_disabled_outlined, size: 20),
                        if(threadLength > 0) Padding(
                          padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                          child: Text('$threadLength'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
        );
      }
    ),
  );
}

Widget PictureViewerWidget(String getSource, double width, double height, bool fullView) {
  if(getSource.isNotEmpty) {
    return DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.transparent,
      border: Border.all(color: Colors.transparent),
      // borderRadius: BorderRadius.circular(20),
    ),
    child: Image.network(
      getSource, 
      width: fullView ? null : width,
      height: fullView ? null : height,
      fit: BoxFit.cover,
      frameBuilder: pictureFrameScreen,
      loadingBuilder: (context, child, loadingProgress) => pictureLoadingScreen(context, child, loadingProgress, width, height, fullView),
      errorBuilder: pictureErrorScreen,
    ),
  );
  } else {
    return DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.transparent,
      border: Border.all(color: Colors.transparent),
      // borderRadius: BorderRadius.circular(20),
    ),
    child: Text("An error occured while we load the image"));
  }
}

Widget pictureFrameScreen(context, child, frame, wasSynchronouslyLoaded) {
  if (wasSynchronouslyLoaded) {
    return child;
  }
  return AnimatedOpacity(
    child: child,
    opacity: frame == null ? 0 : 1,
    duration: const Duration(seconds: 1),
    curve: Curves.easeOut,
  );
}

Widget pictureErrorScreen(context, exception, stackTrace) {
  return Text('Failed to load image: $exception');
}

Widget pictureLoadingScreen(BuildContext context, Widget child, ImageChunkEvent? loadingProgress, double width, double height, bool fullView) {
  if (loadingProgress == null) return child; // If the image is fully loaded, return the child widget
    return SizedBox(
      height: fullView ? null :height,
      width: fullView ? null :width,
      child: Center( // Otherwise, return a loading widget
        child: CircularProgressIndicator( // You can use any widget you like, such as a Shimmer widget
          value: loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
            : null,
        ),
      ),
    );
}
