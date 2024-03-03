// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, avoid_print, unused_local_variable, unnecessary_const, no_leading_underscores_for_local_identifiers, unused_element, unnecessary_new, unused_field, prefer_interpolation_to_compose_strings

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journee/account.dart';
import 'package:journee/categories.dart';
import 'package:journee/search.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  int _selectedIndex = 0;
  static const List<NavigationDestination> navbarWidget = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_filled),
      label: 'Home',
    ),
    // NavigationDestination(
    //   icon: Icon(Icons.create_outlined),
    //   selectedIcon: Icon(Icons.create_rounded),
    //   label: 'Create',
    // ),
    // NavigationDestination(
    //   icon: Icon(Icons.search_outlined),
    //   selectedIcon: Icon(Icons.search_sharp),
    //   label: 'Search',
    // ),
    NavigationDestination(
      icon: Icon(Icons.account_circle_outlined),
      selectedIcon: Icon(Icons.account_circle),
      label: 'Profile',
    ),
  ];
  static const List<NavigationRailDestination> navbarWidgetWindows = [
    NavigationRailDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_filled),
      label: Text('Home'),
    ),
    // NavigationRailDestination(
    //   icon: Icon(Icons.create_outlined),
    //   selectedIcon: Icon(Icons.create_rounded),
    //   label: Text('Create'),
    // ),
    // NavigationRailDestination(
    //   icon: Icon(Icons.search_outlined),
    //   selectedIcon: Icon(Icons.search_sharp),
    //   label: Text('Search'),
    // ),
    NavigationRailDestination(
      icon: Icon(Icons.account_circle_outlined),
      selectedIcon: Icon(Icons.account_circle),
      label: Text('Profile'),
    ),
  ];

  Widget _bottomNavbar() { 
    return NavigationBar(
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (int index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      destinations: navbarWidget,
    );
  }

  Widget _sideNavbar() { 
    return NavigationRail(
      destinations: navbarWidgetWindows, 
      selectedIndex: _selectedIndex,
      groupAlignment: 0,
      labelType: NavigationRailLabelType.selected,
      onDestinationSelected: (int index) {
        setState(() {
          _selectedIndex = index;
        });
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    const List<Widget> _pages = <Widget>[
      HomePostView(),
      // CreateDiaryPage(),
      // SearchPage(),
      AccountPage()
    ];

    if(kIsWeb) {
      return Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages
        ),
        bottomNavigationBar: _bottomNavbar());
    } 
    else {
      if(Platform.isAndroid) {
        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: _pages
          ),
          bottomNavigationBar: _bottomNavbar());
      } 
      else {
        return Scaffold(
          body: Row(
            children: [
              _sideNavbar(),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _pages
                ),
              ),
            ],
          ),
        );
      }
    }
  }
}

class HomePostView extends StatefulWidget {
  const HomePostView({super.key});

  @override
  State<HomePostView> createState() => _HomePostViewState();
}

class _HomePostViewState extends State<HomePostView> {
  static const appcastURL = 'https://raw.githubusercontent.com/darel919/journee-flutter/main/android/app/appcast/appcast.xml';
  static const _urlAndroid = 'https://github.com/darel919/journee-flutter/releases/download/app/app-release.apk';
  static const _url = 'https://github.com/darel919/journee-flutter/releases/';
  String? version;
  String? newestVersion;
  bool willUpgrade = false;
  late Upgrader upgrader = Upgrader(
    durationUntilAlertAgain: Duration(seconds: 1),
    debugDisplayAlways: false,
    debugLogging: false,
      willDisplayUpgrade: ({appStoreVersion, required display, installedVersion, minAppVersion}) {
    if(appStoreVersion == version) {
      willUpgrade = false;
    } else {
      willUpgrade = display;
    }
      newestVersion = appStoreVersion;
  },
    minAppVersion: newestVersion,
      appcastConfig:
          AppcastConfiguration(url: appcastURL, supportedOS: ['android'])
  );
  bool launchUpdateURL() {
    if(Platform.isAndroid) {
      launchUrl(Uri.parse(_urlAndroid));
    } if(Platform.isWindows) {
      launchUrl(Uri.parse(_url));
    }
    return true;
  }

  final _future = Supabase.instance.client
    .from('posts')
    .select('''*, users(*), threads ( * ), categories ( * )''')
    .order('created_at',  ascending: false);
  
  Future<void> _refresh() async {
    context.pushReplacement('/');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
          appBar: AppBar(
            primary: true,
            title: Text("Journee"),
            bottom: TabBar( 
            tabs: [ 
              Tab( 
                // icon: Icon(Icons.home_filled), 
                text: "All", 
              ), 
              Tab( 
                // icon: Icon(Icons.category_outlined), 
                text: "Categories", 
              ), 
            ], 
          ), 
            automaticallyImplyLeading: false,
            actions: <Widget> [searchMode()],
          ),        
          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.create_outlined),
            onPressed: () {
                context.push('/create/diary');
              }
          ),
          body: TabBarView(
            children: [
              UpgradeAlert(
              upgrader: upgrader, 
              canDismissDialog: false,
              showIgnore: false, 
              showLater: false,
              onUpdate: () => launchUpdateURL(), 
              child: RefreshIndicator(
                  onRefresh: () => _refresh(),
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if(!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                        final posts = snapshot.data!;
                        
                        return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: posts.length,
                        itemBuilder: ((context, index) {
                          final post = posts[index];
                          final user = post['users'];
                          final thread = post['threads'];
                          final category = post['categories'];
                          final special = post['type'];
                          final puid = post['puid'];
                          int threadLength = post['threads'].length;
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
                            title: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(0,0,8,0),
                                  child: Text(user['name'], style: TextStyle(fontSize: 16)),
                                ),
                                Container(
                                  padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
                                  decoration: BoxDecoration(border: Border.all(color: MediaQuery.of(context).platformBrightness == Brightness.dark ? Colors.white : Colors.black),
                                  borderRadius: BorderRadius.circular(4)),
                                  child: Text(category['name'], style: TextStyle(fontSize: 9)),
                                ),
                                if(special == 'Special') Padding(
                                  padding: const EdgeInsets.fromLTRB(5,0,0,0),
                                  child: Icon(Icons.star_border_outlined),
                                )
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
                        }),
                      );
                    },
                  ),
                ),
              ), 
              CategoriesPage()
            ]
          ),
          ),
    );
  }
}
