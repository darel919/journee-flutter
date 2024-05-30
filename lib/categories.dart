// ignore_for_file: prefer_const_constructors, prefer_interpolation_to_compose_strings, no_logic_in_create_state, avoid_print, unnecessary_null_comparison, prefer_const_literals_to_create_immutables, dead_code

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journee/search.dart';
import 'package:journee/threads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final _futureCat = Supabase.instance.client
    .from('categories')
    .select('''*, users(*), posts(*)''');
    // .order('created_at',  ascending: false);
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureCat,
        builder: (context, snapshot) {
          if(!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snapshot.data!;
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: ((context, index) {
              final category = categories[index];
              final user = category['users'];
              final cuid = category['cuid'];
              int length = category['posts'].length;
              
              if (length > 0 ) {
                if(user == null) {
                  return Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                  child: ListTile(
                    onTap: () {
                      kIsWeb ? context.go('/category/$cuid') : context.push('/category/$cuid');
                    },
                    leading: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(48.0),
                        child: Icon(Icons.people, size: 48.0)
                      ),
                    ),
                    title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0,0,8,0),
                            child: Text(category['name']),
                          ),
                          Text('by System', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    trailing: Text('$length posts'),
                  ),
                );
                } 
                else {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                    child: ListTile(
                      onTap: () {
                        kIsWeb ? context.go('/category/$cuid') : context.push('/category/$cuid');
                      },
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(48.0),
                        child: Image.network(user['avatar_url']
                        )
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0,0,8,0),
                            child: Text(category['name']),
                          ),
                          Text('by '+user['name'], style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      trailing: Text('$length posts'),
                    ),
                  );
                }
              }
              return Container();
              
            }),
          );
        }
      ),
    );
  }
}

class CategoriesViewPage extends StatefulWidget {
  final String? cuid;
  final bool? home;
  const CategoriesViewPage({super.key, required this.cuid, required this.home});

  @override
  State<CategoriesViewPage> createState() => _CategoriesViewPageState(cuid: cuid, home: home);
}

class _CategoriesViewPageState extends State<CategoriesViewPage> {
  final supabase = Supabase.instance.client;
  final String? cuid;
  final bool? home;

  _CategoriesViewPageState({required this.cuid, required this.home});

  late final _futureCatView = supabase
  .from('posts')
  .select('''*, users(*), threads ( * ), categories ( * ), locations(*)''')
  .eq('cuid', cuid!)
  .order('created_at',  ascending: false);
  
  ValueNotifier<String> catName = ValueNotifier<String>('');
  String? catDesc;
  late List<Map<String, dynamic>> fetchedData = [];
  Future<String> fetchRating(ruid) async {
    double darelRating = 0.0;
    double inesRating = 0.0;
    Map<String, dynamic> reviewData = {};
    var res = await supabase
    .from('foodReviews')
    .select('*')
    .eq('ruid', ruid);
    reviewData = res[0];
    darelRating = reviewData['darelRate'].toDouble();
    inesRating = reviewData['inesRate'].toDouble();
    
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
  Future<void> refreshPage() async{
    context.pushReplacement('/category/$cuid');
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureCatView,
        builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.done) {
            final posts = snapshot.data!;
            // print(posts);
            if(snapshot.data!.isNotEmpty) {
            fetchedData = posts;
            catDesc = posts[0]['categories']['desc'];
            final length = posts.length;
            catName.value = snapshot.data![0]['categories']['name'];
                                   
            Widget categoryViewUI() {
            // FOOD REVIEW CATEGORY VIEW
            if(posts[0]['cuid'] == '368d3855-965d-4f13-b741-7975bbac80bf' && posts.isNotEmpty) {
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: ((context, index) {

                        final post = posts[index];
                        final user = post['users'];
                        final location = post['locations'];
                        final puid = post['puid'];
                        DateTime myDateTime = DateTime.parse(post['created_at']);
                        catName.value = snapshot.data![0]['categories']['name'];
                        // bool readMore = false;
                        ValueNotifier<bool?> readMore = ValueNotifier<bool?>(false);
                        return ListTile(
                          // dense: true,
                          // onTap: () {
                          //   context.push('/post/$puid');
                          // },
                          contentPadding: EdgeInsets.fromLTRB(0, 5, 0, 5),
                          title: Row(
                            children: [
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
                                            return Text('Loading star...');
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
                                if(post['mediaUrl_preview'] != null) GestureDetector(
                                  onTap: () {
                                    context.push('/post/$puid');
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(0 ,8, 0, 0),
                                    child: Image.network(post['mediaUrl_preview'], width: 400),
                                  ),
                                ),
                                if(post['mediaUrl_preview'] == null) GestureDetector(
                                  onTap: () {
                                    context.push('/post/$puid');
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(0 ,8, 0, 0),
                                    child: Image.network(post['mediaUrl']),
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
                                
                                // Divider(),
                                // Padding(
                                //   padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
                                //   child: Row(
                                //     crossAxisAlignment: CrossAxisAlignment.center,
                                //     children: [
                                //       if(post['allowReply']) Padding(
                                //         padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                                //         child: Row(
                                //           crossAxisAlignment: CrossAxisAlignment.center,
                                //           children: [
                                //             Icon(Icons.chat_bubble_outline, size: 20),
                                //             if(threadLength > 0) Padding(
                                //               padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                                //               child: Text('$threadLength'),
                                //             ),
                                //           ],
                                //         ),
                                //       ),
                                //       if(!post['allowReply']) Padding(
                                //         padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                                //         child: Row(
                                //           crossAxisAlignment: CrossAxisAlignment.center,
                                //           children: [
                                //             // Icon(Icons.comments_disabled_outlined, size: 20),
                                //             if(threadLength > 0) Padding(
                                //               padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                                //               child: Text('$threadLength'),
                                //             ),
                                //           ],
                                //         ),
                                //       ),
                                //     ],
                                //   ),
                                // )
                              ],
                            ),
                          ),
                        );
                        }
                      ),
                    ),
                  ),
                ],
              );
              }

              // NON FOOD REVIEW CATEGORY VIEW
              return Column(
                children: [
                  ListTile(
                    // title: Text(catName.value),
                    subtitle: catDesc != null ? Text(catDesc!) : Text("No description available"),
                    trailing: Text('$length posts'),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: ((context, index) {

                        final post = posts[index];
                        final user = post['users'];
                        final puid = post['puid'];
                        int threadLength = post['threads'].length;
                        final special = post['type'];
                        DateTime myDateTime = DateTime.parse(post['created_at']);
                        catName.value = snapshot.data![0]['categories']['name'];

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
                                  child: Image.network(post['mediaUrl_preview'], width: 400)),
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
                    ),
                  ),
                ],
              );
              
            }
            
            if(home == true) {
              return Scaffold(
                body: RefreshIndicator(
                  onRefresh: () => refreshPage(),
                  child: categoryViewUI())
              );
            } return Scaffold(
              appBar: AppBar(
                title: Text(catName.value),
                actions: <Widget> [categorySearchMode(cuid!, catName.value)],
              ),
              body: RefreshIndicator(
                onRefresh: () => refreshPage(),
                child: categoryViewUI())
            );
            }
            return Center(child: Text("There are no food reviews!"));
          }
          return const Center(child: CircularProgressIndicator());
        }
      );
  }
}